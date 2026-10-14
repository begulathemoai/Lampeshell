#pragma once

#include <qelapsedtimer.h>
#include <qqmlintegration.h>

#include "tickingservice.hpp"

namespace lampshell::services {

class NetworkUsage : public TickingService {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(qreal downloadSpeed READ downloadSpeed NOTIFY changed)
    Q_PROPERTY(qreal uploadSpeed READ uploadSpeed NOTIFY changed)
    Q_PROPERTY(qreal downloadTotal READ downloadTotal NOTIFY changed)
    Q_PROPERTY(qreal uploadTotal READ uploadTotal NOTIFY changed)

public:
    explicit NetworkUsage(QObject* parent = nullptr);

    [[nodiscard]] qreal downloadSpeed() const;
    [[nodiscard]] qreal uploadSpeed() const;
    [[nodiscard]] qreal downloadTotal() const;
    [[nodiscard]] qreal uploadTotal() const;

signals:
    void changed();

protected:
    void tick() override;

private:
    qreal m_downloadSpeed = 0.0;
    qreal m_uploadSpeed = 0.0;
    qreal m_downloadTotal = 0.0;
    qreal m_uploadTotal = 0.0;

    quint64 m_prevRx = 0;
    quint64 m_prevTx = 0;
    bool m_initialized = false;
    QElapsedTimer m_timer;
};

}
