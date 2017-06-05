#ifndef BEZIERSCENEIMPORTER_H
#define BEZIERSCENEIMPORTER_H

#include <QSharedPointer>
#include <QTextStream>
#include <QVector>
#include <QVector3D>
#include <QVector4D>

// Fwd Declare
class BezierScene;

class BezierSceneImporter
{

public:
    BezierSceneImporter();

    virtual ~BezierSceneImporter();

    QSharedPointer<BezierScene> importBezierScene(QString fileName);

private:

    const QVector4D interpolateTriCenterPoint(const QVector<QVector4D> &points) const;

    void parsePatch(const QStringList &tokens,
            QVector<QVector4D> &vertices,
            QVector<unsigned> &indices,
            BezierScene &scene);

    void parseScene(QTextStream &in,
            QVector<QVector4D> &vertices,
            QVector<unsigned> &indices,
            BezierScene &scene);

    void parseVertex(
            const QStringList &tokens,
            QVector<QVector4D> &vertices);

    void checkMinMax(const QVector3D &point);

    const QMatrix4x4 calculateModelMatrix() const;

    /// Datamemembers

private:

    QVector3D minValues, maxValues;

};

#endif // BEZIERSCENEIMPORTER_H
