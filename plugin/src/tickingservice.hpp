#pragma once

#include <qtimer.h>

#include "service.hpp"

namespace lampshell::services {

class TickingService : public Service {
    Q_OBJECT

    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)

public:
    explicit TickingService(QObject* parent = nullptr);

    [[nodiscard]] int updateInterval() const;
    void setUpdateInterval(int ms);

signals:
    void updateIntervalChanged();

protected:
    virtual void tick() = 0;

private:
    void start() final;
    void stop() final;

    QTimer* m_timer;
    int m_interval = 1000;
    bool m_running = false;
};

}
