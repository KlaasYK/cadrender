#ifndef BEZIERSCENE_H
#define BEZIERSCENE_H

#include <geom/bezierpatch.h>
#include <geom/beziertriangle.h>
#include <util/beziersceneimporter.h>


#include <QOpenGLFunctions_4_5_Core>
#include <QOpenGLShaderProgram>
#include <QPair>
#include <QSharedPointer>
#include <QVector>
#include <QVector4D>

class BezierScene : protected QOpenGLFunctions_4_5_Core
{
    friend class BezierSceneImporter;

    // =========================================================================
    // -- Enums ----------------------------------------------------------------
    // =========================================================================

private:

    enum AttribArray {
        LOCATION = 0,
        NORMALS = 1,
        TEXTURE = 2
    };

    // =========================================================================
    // -- Constructors and destructor ------------------------------------------
    // =========================================================================

public:

    BezierScene();

    ~BezierScene();

    // =========================================================================
    // -- Other methods --------------------------------------------------------
    // =========================================================================

public:

    // TODO: add render settings (such as wireframe, faces etc.)
    void render(const QOpenGLShaderProgram &program);

protected:

    void addBezierTriangle(const BezierTriangle &patch);

    void setIndexBuffer(const QVector<unsigned> &indices);

    void setVertexBuffer(const QVector<QVector4D> &vertices);


private:

    void createBuffers();

    void initialize();

    // =========================================================================
    // -- Data members ---------------------------------------------------------
    // =========================================================================

private:

    // --- High level data store -----------------------------------------------

    QVector<QSharedPointer<BezierPatch>> _patches;

    // --- OpenGL members ------------------------------------------------------

    GLuint _sceneVAO;

    GLuint _sceneBO;

    GLuint _patchIBO;

    bool _isInit;


};

#endif // BEZIERSCENE_H
