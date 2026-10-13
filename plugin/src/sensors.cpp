#include "sensors.hpp"

#include <qdir.h>
#include <qfile.h>

namespace lampshell::services::sensors {

namespace {

using Qt::StringLiterals::operator""_s;

QString readText(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromLatin1(f.readLine()).trimmed();
}

// hwmon exposes temp*_input in milli-degrees celsius; libsensors (which
// caelestia uses) already scales to celsius, so divide to match.
std::optional<double> readTempCelsius(const QString& path) {
    const QString text = readText(path);
    bool ok = false;
    const double milli = text.toDouble(&ok);
    if (!ok)
        return std::nullopt;
    return milli / 1000.0;
}

struct Hwmon {
    QString path;
    QString name;
};

QList<Hwmon> hwmonChips() {
    QList<Hwmon> chips;
    const QDir base(u"/sys/class/hwmon"_s);
    const QStringList entries = base.entryList({ u"hwmon*"_s }, QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString& entry : entries) {
        const QString path = base.filePath(entry);
        chips.append({ path, readText(path + u"/name"_s) });
    }
    return chips;
}

struct TempInput {
    QString path;
    QString label;
};

// Returns the tempN_input files of a chip alongside their labels.
QList<TempInput> tempInputs(const QString& chipPath) {
    QList<TempInput> out;
    const QDir dir(chipPath);
    const QStringList inputs = dir.entryList({ u"temp*_input"_s }, QDir::Files);
    for (const QString& input : inputs) {
        const QString prefix = input.left(input.size() - 6); // strip "_input"
        const QString label = readText(chipPath + u"/"_s + prefix + u"_label"_s);
        out.append({ chipPath + u"/"_s + input, label });
    }
    return out;
}

bool isGpuChip(const QString& name) {
    static const QStringList names = { u"amdgpu"_s, u"nouveau"_s, u"i915"_s, u"xe"_s, u"radeon"_s, u"nvidia"_s };
    return names.contains(name);
}

struct Accum {
    double sum = 0.0;
    int count = 0;

    void add(double value) {
        sum += value;
        ++count;
    }

    [[nodiscard]] std::optional<double> average() const {
        if (count == 0)
            return std::nullopt;
        return sum / count;
    }
};

// Mirrors caelestia's classifyGpuTempLabel: indexed tempN labels and the vendor
// die labels are the reading we want; junction/mem only stand in when no
// primary sensor exists.
bool isPrimaryGpuLabel(const QString& label) {
    const bool tempIndexed = label.startsWith(u"temp"_s) && label.size() > 4 && label.at(4).isDigit();
    return tempIndexed || label == u"GPU core"_s || label == u"edge"_s;
}

bool isFallbackGpuLabel(const QString& label) {
    return label == u"junction"_s || label == u"mem"_s;
}

} // namespace

// Matches caelestia's cpuPackageTemp: "Package id N" / "Tdie" are the primary
// reading, "Tctl" only stands in when neither is present.
std::optional<double> cpuPackageTemp() {
    std::optional<double> primary;
    std::optional<double> fallback;

    for (const auto& chip : hwmonChips()) {
        for (const auto& input : tempInputs(chip.path)) {
            if (input.label.startsWith(u"Package id "_s) || input.label == u"Tdie"_s) {
                if (const auto value = readTempCelsius(input.path))
                    primary = value;
            } else if (input.label == u"Tctl"_s) {
                if (const auto value = readTempCelsius(input.path))
                    fallback = value;
            }
        }
    }

    return primary.has_value() ? primary : fallback;
}

// Matches caelestia's gpuPciAverageTemp: average the primary GPU sensors, or
// fall back to the junction/mem average when there is no primary.
std::optional<double> gpuTemp() {
    Accum primary;
    Accum fallback;

    for (const auto& chip : hwmonChips()) {
        if (!isGpuChip(chip.name))
            continue;

        for (const auto& input : tempInputs(chip.path)) {
            const bool primaryLabel = isPrimaryGpuLabel(input.label);
            const bool fallbackLabel = isFallbackGpuLabel(input.label);
            if (!primaryLabel && !fallbackLabel)
                continue;

            const auto value = readTempCelsius(input.path);
            if (!value)
                continue;

            if (primaryLabel)
                primary.add(*value);
            else
                fallback.add(*value);
        }
    }

    if (const auto average = primary.average())
        return average;
    return fallback.average();
}

} // namespace lampshell::services::sensors
