#include <util/beziersceneimporter.h>

#include <gl/bezierscene.h>
#include <geom/beziertriangle.h>

#include <QFile>
#include <QtDebug>

BezierSceneImporter::BezierSceneImporter()
{

}


BezierSceneImporter::~BezierSceneImporter() {

}



QSharedPointer<BezierScene> BezierSceneImporter::importBezierScene(QString fileName) const
{
    QSharedPointer<BezierScene> scene(new BezierScene());
    QFile fin(fileName);
    QVector<unsigned> indices;
    QVector<QVector4D> vertices;

    if (fin.open(QIODevice::ReadOnly)) {
        qInfo() << "Importing file:" << fileName;
        QTextStream in(&fin);
        parseScene(in,vertices,indices,*scene.data());
        scene->setIndexBuffer(indices);
        scene->setVertexBuffer(vertices);
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
            1/4 * (UV201 + UV102 + UV021 + UV012 + UV210 + UV120)
            -  1/6 * (UV300 + UV030 + UV003);

    return UV111;
}


void BezierSceneImporter::parsePatch(
        const QStringList &tokens,
        QVector<QVector4D> &vertices,
        QVector<unsigned> &indices,
        BezierScene &scene) const
{
    Q_ASSERT(tokens.size() == 10 || tokens.size() == 11);
    QVector<QVector4D> patchVertices;
    patchVertices.reserve(10);
    // TODO: check for QUAD patches

    for (unsigned i = 1; i < 10; ++i) {
        unsigned index = tokens.at(1).toUInt();
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
                                     BezierScene &scene) const
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
        QVector<QVector4D> &vertices) const
{
    Q_ASSERT(tokens.size() == 5);
    double x = tokens.at(1).toDouble();
    double y = tokens.at(2).toDouble();
    double z = tokens.at(3).toDouble();
    double w = tokens.at(4).toDouble();
    vertices.push_back(QVector4D(x, y, z, w));
}
