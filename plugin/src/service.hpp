#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>

namespace lampshell::services {

class Service : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit Service(QObject* parent = nullptr);

    Q_INVOKABLE void ref(QObject* sender);
    Q_INVOKABLE void unref(QObject* sender);

    [[nodiscard]] int refCount() const;

private:
    QSet<QObject*> m_refs;

    virtual void start() = 0;
    virtual void stop() = 0;
};

}
