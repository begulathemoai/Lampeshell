#pragma once

#include <qpointer.h>
#include <qqmlintegration.h>

#include "service.hpp"

namespace lampshell::services {

// QML element that keeps a Service alive for as long as it exists. Bind its
// `service` to a native singleton to start/stop polling with the UI.
class ServiceRef : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(lampshell::services::Service* service READ service WRITE setService NOTIFY serviceChanged)

public:
    explicit ServiceRef(QObject* parent = nullptr);

    [[nodiscard]] Service* service() const;
    void setService(Service* service);

signals:
    void serviceChanged();

private:
    QPointer<Service> m_service;
};

} // namespace lampshell::services
