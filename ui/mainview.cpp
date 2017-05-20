#include <ui/mainview.h>

#include <util/beziersceneimporter.h>

#include <QtDebug>

#include <iostream>

// =============================================================================
// -- Constructors and destructor ----------------------------------------------
// =============================================================================

MainView::MainView(QWidget *parent) :
    QOpenGLWidget(parent) {}

MainView::~MainView() {}

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
        // Defaults to Asynchronous logging
        _debugLogger->startLogging(QOpenGLDebugLogger::SynchronousLogging);
    } else {
        qWarning() << "Logging initialisation failed!";
    }
#endif

    QString glVersion;
    glVersion = reinterpret_cast<const char*>(glGetString(GL_VERSION));
    qInfo() << "OpenGL:" << qPrintable(glVersion);

    createSimpleProgram();
    createTessellationProgram();

    const BezierSceneImporter importer = BezierSceneImporter();
    _scene = importer.importBezierScene(":/scenes/bezier/simpletriangle.bezier");
}

void MainView::paintGL() {
    // TODO: paintGL()
}

void MainView::resizeGL(int newWidth, int newHeight) {
    Q_UNUSED(newWidth);
    Q_UNUSED(newHeight);
    // TODO: resizeGL();
}

// =============================================================================
// -- Signals and slots --------------------------------------------------------
// =============================================================================

void MainView::onMessageLogged(QOpenGLDebugMessage message) {
    qDebug() << message;
    switch(message.severity()) {
    case QOpenGLDebugMessage::NotificationSeverity:
    case QOpenGLDebugMessage::LowSeverity:
        qDebug() << message.message();
        break;
    case QOpenGLDebugMessage::MediumSeverity:
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
