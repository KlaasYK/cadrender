#include <util/beziersceneimporter.h>

#include <gl/bezierscene.h>
#include <geom/beziertriangle.h>

#include <QFile>
#include <QtDebug>

#include <limits>

BezierSceneImporter::BezierSceneImporter()
{
    minValues = QVector3D(
                std::numeric_limits<float>::max(),
                std::numeric_limits<float>::max(),
                std::numeric_limits<float>::max());
    maxValues = QVector3D(
                std::numeric_limits<float>::min(),
                std::numeric_limits<float>::min(),
                std::numeric_limits<float>::min());
}


BezierSceneImporter::~BezierSceneImporter() {

}



QSharedPointer<BezierScene> BezierSceneImporter::importBezierScene(QString fileName)
{
    QSharedPointer<BezierScene> scene(new BezierScene());
    QFile fin(fileName);
    QVector<unsigned> indices;
    QVector<QVector4D> vertices;

    if (fin.open(QIODevice::ReadOnly)) {
        qInfo() << "Importing file:" << fileName;
        QTextStream in(&fin);
        parseScene(in, vertices, indices, *scene.data());
        scene->setIndexBuffer(indices);
        scene->setVertexBuffer(vertices);
        scene->setModelMatrix(calculateModelMatrix());
    } else {
        qWarning() << "Could not open file:" << fileName;
    }
    return scene;
}

const QVector4D BezierSceneImporter::interpolateTriCenterPoint(const QVector<QVector4D> &points) const
{
    Q_ASSERT(points.size() == 9);
    const QVector4D UV003 = points.at(0);
    const QVector4D UV102 = points.at(1);
    const QVector4D UV201 = points.at(2);
    const QVector4D UV300 = points.at(3);
    const QVector4D UV210 = points.at(4);
    const QVector4D UV120 = points.at(5);
    const QVector4D UV030 = points.at(6);
    const QVector4D UV021 = points.at(7);
    const QVector4D UV012 = points.at(8);

    // Midpoints are interpolated using: G. Farin
    // Curves and Surfaces for CAGD, p. 342
    const QVector4D UV111 =
            1.0/4.0 * (UV201 + UV102 + UV021 + UV012 + UV210 + UV120)
            -  1.0/6.0 * (UV300 + UV030 + UV003);

    return UV111;
}


void BezierSceneImporter::parsePatch(
        const QStringList &tokens,
        QVector<QVector4D> &vertices,
        QVector<unsigned> &indices,
        BezierScene &scene)
{
    Q_ASSERT(tokens.size() == 10 || tokens.size() == 11);
    QVector<QVector4D> patchVertices;
    patchVertices.reserve(10);
    // TODO: check for QUAD patches

    for (unsigned i = 1; i < 10; ++i) {
        unsigned index = tokens.at(i).toUInt();
        Q_ASSERT(index < static_cast<unsigned>(vertices.size()));
        indices.push_back(index);
        patchVertices.push_back(vertices.at(index));
    }
    if (tokens.size() == 11) {
        unsigned midpoint = tokens.at(10).toUInt();
        indices.push_back(midpoint);
        patchVertices.push_back(vertices.at(midpoint));
    } else {
        // interpolate midpoint
        indices.push_back(vertices.size());
        const QVector4D center = interpolateTriCenterPoint(patchVertices);
        vertices.push_back(center);
        patchVertices.push_back(center);
    }
    scene.addBezierTriangle(BezierTriangle(patchVertices));
}

void BezierSceneImporter::parseScene(QTextStream &in,
                                     QVector<QVector4D> &vertices,
                                     QVector<unsigned> &indices,
                                     BezierScene &scene)
{
    QString line;
    QStringList tokens;
    while (in.readLineInto(&line)) {
        if (line.startsWith("#")) continue; // skip comments
        tokens = line.split(" ", QString::SkipEmptyParts);
        if (tokens.size() < 1) continue; // skip empty lines

        if (tokens[0] == "v") {
            parseVertex(tokens, vertices);
        } else if (tokens[0] == "p") {
            parsePatch(tokens, vertices, indices, scene);
        } else {
            qWarning() << "Unknown line:" << line << endl;
        }
    } // while (in.readLine)

}

void BezierSceneImporter::parseVertex(
        const QStringList &tokens,
        QVector<QVector4D> &vertices)
{
    Q_ASSERT(tokens.size() == 5);
    double x = tokens.at(1).toDouble();
    double y = tokens.at(2).toDouble();
    double z = tokens.at(3).toDouble();
    double w = tokens.at(4).toDouble();
    const QVector4D point(x, y, z, w);
    checkMinMax(QVector3D(
                    point.x() / point.w(),
                    point.y() / point.w(),
                    point.z() / point.w()));
    vertices.push_back(point);
}

void BezierSceneImporter::checkMinMax(const QVector3D &point)
{
    if (point.x() > maxValues.x()) {
        maxValues.setX(point.x());
    }
    if (point.x() < minValues.x()) {
        minValues.setX(point.x());
    }
    if (point.y() > maxValues.y()) {
        maxValues.setY(point.y());
    }
    if (point.y() < minValues.y()) {
        minValues.setY(point.y());
    }
    if (point.z() > maxValues.z()) {
        maxValues.setZ(point.z());
    }
    if (point.z() < minValues.z()) {
        minValues.setZ(point.z());
    }
}

const QMatrix4x4 BezierSceneImporter::calculateModelMatrix() const
{
    QMatrix4x4 modelMatrix;
    QVector3D range = maxValues - minValues;

    float scale = 1.0/std::max(range.x(),std::max(range.y(),range.z()));

    modelMatrix.scale(scale);

    modelMatrix.translate((-1.0 * minValues) - (0.5 * range));

    return modelMatrix;
}



