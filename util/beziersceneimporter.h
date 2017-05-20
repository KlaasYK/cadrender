#ifndef BEZIERSCENEIMPORTER_H
#define BEZIERSCENEIMPORTER_H

#include <QSharedPointer>
#include <QTextStream>
#include <QVector>
#include <QVector4D>

// Fwd Declare
class BezierScene;

class BezierSceneImporter
{

public:
    BezierSceneImporter();

    virtual ~BezierSceneImporter();

    QSharedPointer<BezierScene> importBezierScene(QString fileName) const;

private:

    const QVector4D interpolateTriCenterPoint(const QVector<QVector4D> &points) const;

    void parsePatch(const QStringList &tokens,
            QVector<QVector4D> &vertices,
            QVector<unsigned> &indices,
            BezierScene &scene) const;

    void parseScene(QTextStream &in,
            QVector<QVector4D> &vertices,
            QVector<unsigned> &indices,
            BezierScene &scene) const;

    void parseVertex(
            const QStringList &tokens,
            QVector<QVector4D> &vertices) const;




};

#endif // BEZIERSCENEIMPORTER_H
