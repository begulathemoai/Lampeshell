#include "imagesampler.hpp"

#include <qmath.h>

namespace lampshell::services {

ImageSampler::ImageSampler(QObject* parent)
    : QObject(parent) {}

int ImageSampler::imageWidth() const {
    return m_image.width();
}

int ImageSampler::imageHeight() const {
    return m_image.height();
}

bool ImageSampler::load(const QUrl& url) {
    const QString path = url.isLocalFile() ? url.toLocalFile() : url.toString();

    QImage loaded;
    if (!loaded.load(path))
        return false;

    if (m_image.size() != loaded.size())
        Q_EMIT imageChanged();

    m_image = loaded;
    return true;
}

QString ImageSampler::sample(int x, int y) const {
    if (m_image.isNull())
        return {};

    const int px = qBound(0, x, m_image.width() - 1);
    const int py = qBound(0, y, m_image.height() - 1);

    return m_image.pixelColor(px, py).name(QColor::HexRgb);
}

QString ImageSampler::sampleAtFraction(double fx, double fy) const {
    if (m_image.isNull())
        return {};

    const double x = qBound(0.0, fx, 1.0) * (m_image.width() - 1);
    const double y = qBound(0.0, fy, 1.0) * (m_image.height() - 1);

    return sample(qRound(x), qRound(y));
}

} // namespace lampshell::services