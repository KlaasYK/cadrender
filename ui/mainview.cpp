#include <ui/mainview.h>

#include <util/beziersceneimporter.h>

#include <QtDebug>

#include <iostream>

// =============================================================================
// -- Constructors and destructor ----------------------------------------------
// =============================================================================

MainView::MainView(QWidget *parent) :
    QOpenGLWidget(parent),
    _xRot(0),
    _yRot(0){}

MainView::~MainView() {
    glDeleteQueries(1, &_primitiveQuery);
}

// =============================================================================
// -- QOpenGLWidget ------------------------------------------------------------
// =============================================================================

void MainView::initializeGL() {
    qDebug() << "Initializing OpenGL...";
    initializeOpenGLFunctions();

#ifdef QT_DEBUG
    _debugLogger = new QOpenGLDebugLogger(this);
    connect(_debugLogger, SIGNAL(messageLogged(QOpenGLDebugMessage)),
            this, SLOT(onMessageLogged(QOpenGLDebugMessage)),
            Qt::DirectConnection);   
    if (_debugLogger->initialize()) {
        qDebug() << "Logging initialized.";
        // Disable shader initialisation messages
        _debugLogger->disableMessages(
                    QOpenGLDebugMessage::ShaderCompilerSource,
                    QOpenGLDebugMessage::OtherType,
                    QOpenGLDebugMessage::NotificationSeverity);

        _debugLogger->disableMessages(
                    QOpenGLDebugMessage::AnySource,
                    QOpenGLDebugMessage::PerformanceType,
                    QOpenGLDebugMessage::AnySeverity);
        // Defaults to Asynchronous logging
        _debugLogger->startLogging(QOpenGLDebugLogger::SynchronousLogging);
    } else {
        qWarning() << "Logging initialisation failed!";
    }
#endif

    QString glVersion;
    glVersion = reinterpret_cast<const char*>(glGetString(GL_VERSION));
    qInfo() << "OpenGL:" << qPrintable(glVersion);

    // TODO: this needs to be set for each different patch!
    glPatchParameteri(GL_PATCH_VERTICES, 10);

    createSimpleProgram();
    createTessellationProgram();

    glGenQueries(1, &_primitiveQuery);

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);

    const BezierSceneImporter importer = BezierSceneImporter();
    _scene = importer.importBezierScene(":/scenes/bezier/simpletriangle.bezier");
}

void MainView::paintGL() {
    QMatrix4x4 projection, model, view;

    view.translate(0, 0, -10);
    view.rotate(_xRot, 0, 1, 0);
    view.rotate(_yRot, 1, 0, 0);


    const int tessLevels[2] = {1,8};

    const int edgeHeuristic = 5; // min proj, curv
    const int faceHeuristic = 5; // min proj, curv

    const float projectionTolerance = 1.0;
    const float deviationTolerance = 1.0;

    const QVector4D materialProps = QVector4D(0.2, 0.8, 0.4, 20.0);
    const QVector3D frontColor = QVector3D(1, 0, 0);
    const QVector3D backColor = QVector3D(0, 1, 0);

    const int drawingMode = 0; // Smooth

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    const double aspect = static_cast<double>(width())/static_cast<double>(height());
    projection.perspective(60, aspect, 0.1, 100);

    _tessProgram->bind();

    _tessProgram->setUniformValue("ProjectionMatrix", projection);
    _tessProgram->setUniformValue("ModelViewMatrix", view * model);
    _tessProgram->setUniformValueArray("TessLevels", tessLevels, 2);
    _tessProgram->setUniformValue("EdgeHeuristic", edgeHeuristic);
    _tessProgram->setUniformValue("FaceHeuristic", faceHeuristic);
    _tessProgram->setUniformValue("ProjectionTolerance", projectionTolerance);
    _tessProgram->setUniformValue("DeviationTolerance", deviationTolerance);

    _tessProgram->setUniformValue("Width", width());
    _tessProgram->setUniformValue("Height", height());

    _tessProgram->setUniformValue("MaterialProps",materialProps);
    _tessProgram->setUniformValue("ColorFront", frontColor);
    _tessProgram->setUniformValue("ColorBack", backColor);
    _tessProgram->setUniformValue("DrawingMode", drawingMode);

     glBeginQuery(GL_PRIMITIVES_GENERATED, _primitiveQuery);
    _scene->render(*_tessProgram);
    glEndQuery(GL_PRIMITIVES_GENERATED);

    int numPrimitives;

    glGetQueryObjectiv(_primitiveQuery, GL_QUERY_RESULT, &numPrimitives);

    emit onPrimitivesDrawn(numPrimitives);


    _tessProgram->release();
}

void MainView::resizeGL(int newWidth, int newHeight) {
    Q_UNUSED(newWidth);
    Q_UNUSED(newHeight);
    // TODO: resizeGL();
}

void MainView::onXRotation(int rotation)
{
    _xRot = rotation;
    update();
}

void MainView::onYRotation(int rotation)
{
    _yRot = rotation;
    update();
}

// =============================================================================
// -- Signals and slots --------------------------------------------------------
// =============================================================================

void MainView::onMessageLogged(QOpenGLDebugMessage message) {
    switch(message.severity()) {
    case QOpenGLDebugMessage::NotificationSeverity:
    case QOpenGLDebugMessage::LowSeverity:
        case QOpenGLDebugMessage::MediumSeverity:
        qDebug() << message.message();
        break;
    case QOpenGLDebugMessage::HighSeverity:
        qWarning() << message.message();
        break;
    default:
        qDebug() << message.message();
        break;
    }
}

// =============================================================================
// -- Ohter methods ------------------------------------------------------------
// =============================================================================

void MainView::createTessellationProgram() {
    _tessProgram = new QOpenGLShaderProgram(this);

    _tessProgram->addShaderFromSourceFile(
                QOpenGLShader::Vertex,
                ":/shaders/tessellation/vertex.glsl");
    _tessProgram->addShaderFromSourceFile(
                QOpenGLShader::TessellationControl,
                ":/shaders/tessellation/tess_control.glsl");
    _tessProgram->addShaderFromSourceFile(
                QOpenGLShader::TessellationEvaluation,
                ":/shaders/tessellation/tess_eval.glsl");
    _tessProgram->addShaderFromSourceFile(
                QOpenGLShader::Geometry,
                ":/shaders/tessellation/geometry.glsl");
    _tessProgram->addShaderFromSourceFile(
                QOpenGLShader::Fragment,
                ":/shaders/tessellation/fragment.glsl");

    if (!_tessProgram->link()) {
        qFatal("Tessellation program did not compile");
    }

}

void MainView::createSimpleProgram() {
    _simpleProgram = new QOpenGLShaderProgram(this);

    _simpleProgram->addShaderFromSourceFile(
                QOpenGLShader::Vertex,
                ":/shaders/simple/vertex.glsl");
    _simpleProgram->addShaderFromSourceFile(
                QOpenGLShader::Fragment,
                ":/shaders/simple/fragment.glsl");

    if (!_simpleProgram->link()) {
        qFatal("Simple program did not compile!");
    }
}
