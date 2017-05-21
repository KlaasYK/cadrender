#include <gl/bezierscene.h>

#include <QThread>

// -----------------------------------------------------------------------------
// -- Constructors and destructor ----------------------------------------------
// -----------------------------------------------------------------------------

BezierScene::BezierScene() :
    _isInit(false)
{

}

BezierScene::~BezierScene() {
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    glDeleteVertexArrays(1, &_sceneVAO);
    glDeleteBuffers(1, &_sceneBO);
    glDeleteBuffers(1, &_patchIBO);
}

// -----------------------------------------------------------------------------
// -- Other Methods ------------------------------------------------------------
// -----------------------------------------------------------------------------

// --- Public ------------------------------------------------------------------

void BezierScene::render(const QOpenGLShaderProgram &program)
{
    if (!_isInit) {
        initialize();
    }

    //program.bind();


    glBindVertexArray(_sceneVAO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _patchIBO);
    glDrawElements(GL_PATCHES, _patches.size() * 10 , GL_UNSIGNED_INT, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindVertexArray(0);



    //program.release();
}

// --- Protected ---------------------------------------------------------------

void BezierScene::addBezierTriangle(const BezierTriangle &patch)
{
    _patches.push_back(QSharedPointer<BezierPatch>(new BezierTriangle(patch)));
}

void BezierScene::setIndexBuffer(const QVector<unsigned> &indices){
    if (!_isInit) {
        initialize();
    }
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _patchIBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 sizeof(unsigned) * indices.size(),
                 indices.data(),
                 GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

void BezierScene::setVertexBuffer(const QVector<QVector4D> &vertices)
{
    if (!_isInit) {
        initialize();
    }
    glBindBuffer(GL_ARRAY_BUFFER, _sceneBO);
    glBufferData(GL_ARRAY_BUFFER,
                 sizeof(QVector4D) * vertices.size(),
                 vertices.data(),
                 GL_STATIC_DRAW);    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

// --- Private -----------------------------------------------------------------

void BezierScene::createBuffers() {
    glGenVertexArrays(1, &_sceneVAO);
    glBindVertexArray(_sceneVAO);

    glGenBuffers(1, &_sceneBO);
    glBindBuffer(GL_ARRAY_BUFFER,_sceneBO);
    glEnableVertexAttribArray(LOCATION);
    glVertexAttribPointer(LOCATION, 4, GL_FLOAT, GL_FALSE, 0, 0);

    glGenBuffers(1, &_patchIBO);
}

void BezierScene::initialize() {
    initializeOpenGLFunctions();
    createBuffers();
    _isInit = true;
}
