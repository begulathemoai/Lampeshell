#include "sensors.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qregularexpression.h>

namespace lampshell::services::sensors {

namespace {

using Qt::StringLiterals::operator""_s;

QString readText(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromLatin1(f.readLine()).trimmed();
}

std::optional<double> readDouble(const QString& path) {
    const QString text = readText(path);
    bool ok = false;
    const double value = text.toDouble(&ok);
    if (!ok)
        return std::nullopt;
    return value;
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

// Returns the tempN_input files of a chip alongside their labels.
QList<QPair<QString, QString>> tempInputs(const QString& chipPath) {
    QList<QPair<QString, QString>> out;
    const QDir dir(chipPath);
    const QStringList inputs = dir.entryList({ u"temp*_input"_s }, QDir::Files);
    for (const QString& input : inputs) {
        const QString prefix = input.left(input.size() - 6); // strip "_input"
        const QString label = readText(chipPath + u"/"_s + prefix + u"_label"_s);
        out.append({ chipPath + u"/"_s + input, label });
    }
    return out;
}

bool isCpuChip(const QString& name) {
    static const QStringList names = { u"k10temp"_s, u"coretemp"_s, u"zenpower"_s, u"cpu_thermal"_s, u"soc_thermal"_s };
    return names.contains(name);
}

bool isGpuChip(const QString& name) {
    static const QStringList names = { u"amdgpu"_s, u"nouveau"_s, u"i915"_s, u"xe"_s, u"radeon"_s, u"nvidia"_s };
    return names.contains(name);
}

} // namespace

std::optional<double> cpuPackageTemp() {
    static const QRegularExpression primary(u"Package id|Tctl|Tdie"_s);

    std::optional<double> fallback;
    for (const auto& chip : hwmonChips()) {
        if (!isCpuChip(chip.name))
            continue;

        for (const auto& [path, label] : tempInputs(chip.path)) {
            const auto value = readDouble(path);
            if (!value)
                continue;
            if (primary.match(label).hasMatch())
                return value;
            if (!fallback)
                fallback = value;
        }
    }
    return fallback;
}

std::optional<double> gpuTemp() {
    static const QRegularExpression preferred(u"edge|junction"_s);

    std::optional<double> fallback;
    for (const auto& chip : hwmonChips()) {
        if (!isGpuChip(chip.name))
            continue;

        for (const auto& [path, label] : tempInputs(chip.path)) {
            const auto value = readDouble(path);
            if (!value)
                continue;
            if (preferred.match(label).hasMatch())
                return value;
            if (!fallback)
                fallback = value;
        }
    }
    return fallback;
}

} // namespace lampshell::services::sensors
