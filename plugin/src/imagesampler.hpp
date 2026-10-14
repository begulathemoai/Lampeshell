#pragma once

#include <qcolor.h>
#include <qimage.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qurl.h>

namespace lampshell::services {

class ImageSampler : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int imageWidth READ imageWidth NOTIFY imageChanged)
    Q_PROPERTY(int imageHeight READ imageHeight NOTIFY imageChanged)

public:
    explicit ImageSampler(QObject* parent = nullptr);

    [[nodiscard]] int imageWidth() const;
    [[nodiscard]] int imageHeight() const;

    Q_INVOKABLE bool load(const QUrl& url);
    Q_INVOKABLE QString sample(int x, int y) const;
    Q_INVOKABLE QString sampleAtFraction(double fx, double fy) const;

    Q_SIGNAL void imageChanged();

private:
    QImage m_image;
};

}