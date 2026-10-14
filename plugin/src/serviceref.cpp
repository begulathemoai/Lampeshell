#include "serviceref.hpp"

namespace lampshell::services {

ServiceRef::ServiceRef(QObject* parent)
    : QObject(parent) {}

Service* ServiceRef::service() const {
    return m_service;
}

void ServiceRef::setService(Service* service) {
    if (m_service == service) {
        return;
    }

    if (m_service) {
        m_service->unref(this);
    }

    m_service = service;
    emit serviceChanged();

    if (m_service) {
        m_service->ref(this);
    }
}

}
