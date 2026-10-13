#pragma once

#include <qprocess.h>
#include <qqmlintegration.h>
#include <qstringlist.h>

#include <functional>

#include "tickingservice.hpp"

namespace lampshell::services {

class Gpu : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(Type type READ type NOTIFY typeChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool detecting READ detecting NOTIFY detectingChanged)
    Q_PROPERTY(qreal percentage READ percentage NOTIFY percentageChanged)
    Q_PROPERTY(qreal temperature READ temperature NOTIFY temperatureChanged)

public:
    enum class Type : quint8 {
        None,
        Generic,
        Nvidia,
    };
    Q_ENUM(Type)

    explicit Gpu(QObject* parent = nullptr);

    [[nodiscard]] Type type() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] bool detecting() const;
    [[nodiscard]] qreal percentage() const;
    [[nodiscard]] qreal temperature() const;

signals:
    void typeChanged();
    void nameChanged();
    void detectingChanged();
    void percentageChanged();
    void temperatureChanged();

protected:
    void tick() override;

private:
    void resolveGpu();
    void tryNameSource(int index, int generation);
    void finishNameSource(int index, int generation, QString name);

    void readGenericUsage();
    void readGpuTemperature();
    void startNvidiaUsage();
    void resetUsage();

    void runProcess(const QString& program, const QStringList& args, std::function<void(const QByteArray&)> callback);

    void setType(Type value);
    void setName(QString value);
    void setDetecting(bool value);

    Type m_type = Type::None;
    QString m_name;
    bool m_detecting = false;
    qreal m_percentage = 0.0;
    qreal m_temperature = 0.0;

    QStringList m_busyFiles;
    int m_generation = 0;
    bool m_nvidiaQuerying = false;
};

} // namespace lampshell::services
