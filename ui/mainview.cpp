#include <ui/mainview.h>

#include <util/beziersceneimporter.h>

#include <QtDebug>
#include <QImage>

#include <iostream>

// =============================================================================
// -- Constructors and destructor ----------------------------------------------
// =============================================================================

MainView::MainView(QWidget *parent) :
    QOpenGLWidget(parent),
    _xRot(0),
    _yRot(0),
    _scale(1.0),
    _currentMouseState(MouseState::None),
    _drawFaces(true),
    _drawWireframe(false),
    _currentDrawingMode(0),
    _edgeHeuristic(0),
    _faceHeuristic(0),
    _minTessLevel(1),
    _maxTessLevel(8),
    _projectionTolerance(1.0f){}

MainView::~MainView() {
    glDeleteQueries(1, &_primitiveQuery);
}

// =============================================================================
// -- QWidget ------------------------------------------------------------------
// =============================================================================

void MainView::mousePressEvent(QMouseEvent *event) {

    switch(event->button()) {
    case Qt::LeftButton:
        _currentMouseState = MouseState::Rotate;
        break;
    case Qt::RightButton:
        _currentMouseState = MouseState::Translate;
        break;
    default:
        _currentMouseState = MouseState::None;
    }
    _lastX = event->x();
    _lastY = event->y();

    this->setFocus();
    update();
}

void MainView::mouseMoveEvent(QMouseEvent *event) {
    int dx = event->x() - _lastX;
    int dy = event->y() - _lastY;
    _lastX = event->x();
    _lastY = event->y();

    switch(_currentMouseState) {
    case MouseState::Rotate:
    {
        QMatrix4x4 rotationMatrix;
        rotationMatrix.rotate(dx,0,1,0);
        rotationMatrix.rotate(dy, 1, 0, 0);
        _rotationMatrix = rotationMatrix * _rotationMatrix;
    }
        break;
    default:
        // Do nothing
        break;
    }
    update();
}

void MainView::wheelEvent(QWheelEvent *event) {
    if (event->delta() > 0) {
        _scale += 0.05;
    } else {
        _scale -= 0.05;
    }
    _scale = std::max(0.0f, std::min(10.0f, _scale));
    update();
}

void MainView::keyReleaseEvent(QKeyEvent *event) {

    switch(event->key()) {
    case Qt::Key_S:
    {
        QImage img = this->grabFramebuffer();
        img.save("test.png");
    }
        break;
    default:
        // Do nothing
        break;
    }
    update();
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

    GLfloat range[2];
    GLfloat granulatiry;

    glGetFloatv(GL_LINE_WIDTH_RANGE, range);
    glGetFloatv(GL_LINE_WIDTH_GRANULARITY, &granulatiry);

    qDebug() << granulatiry;
    qDebug() << range[0] << range[1];

    //glEnable(GL_LINE_SMOOTH);
    glLineWidth(1.0);

    BezierSceneImporter importer = BezierSceneImporter();
    _scene = importer.importBezierScene(":/scenes/bezier/beziersphere.bezier");
}

void MainView::paintGL() {
    QMatrix4x4 projection, model, view, scale;
    scale.scale(_scale);
    model = scale * _scene->getModelMatrix();

    view.translate(0, 0, -1.0);
    view = view * _rotationMatrix;


    int tessLevels[2] = {_minTessLevel, _maxTessLevel};

    const float deviationTolerance = 1.0;

    const QVector4D materialProps = QVector4D(0.2, 0.8, 0.4, 20.0);
    const QVector4D lineMaterial = QVector4D(1.0, 0.0, 0.0, 1.0);
    const QVector3D frontColor = QVector3D(1, 0, 0);
    const QVector3D white = QVector3D(0,0,1);
    const QVector3D backColor = QVector3D(0, 1, 0);

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    const double aspect = static_cast<double>(width())/static_cast<double>(height());
    projection.perspective(60, aspect, 0.1, 100);

    _tessProgram->bind();

    _tessProgram->setUniformValue("ProjectionMatrix", projection);
    _tessProgram->setUniformValue("ModelViewMatrix", view * model);
    _tessProgram->setUniformValueArray("TessLevels", tessLevels, 2);
    _tessProgram->setUniformValue("EdgeHeuristic", _edgeHeuristic);
    _tessProgram->setUniformValue("FaceHeuristic", _faceHeuristic);
    _tessProgram->setUniformValue("ProjectionTolerance", _projectionTolerance);
    _tessProgram->setUniformValue("DeviationTolerance", deviationTolerance);

    _tessProgram->setUniformValue("Width", width());
    _tessProgram->setUniformValue("Height", height());

    glBeginQuery(GL_PRIMITIVES_GENERATED, _primitiveQuery);
    if (_drawFaces) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        _tessProgram->setUniformValue("MaterialProps",materialProps);
        _tessProgram->setUniformValue("ColorFront", frontColor);
        _tessProgram->setUniformValue("ColorBack", backColor);
        _tessProgram->setUniformValue("DrawingMode", _currentDrawingMode);
        _scene->render(*_tessProgram);
    }
    glEndQuery(GL_PRIMITIVES_GENERATED);

    int numPrimitives;

    glGetQueryObjectiv(_primitiveQuery, GL_QUERY_RESULT, &numPrimitives);

    if (_drawWireframe) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        model.scale(1.001f);
        _tessProgram->setUniformValue("ModelViewMatrix", view * model);
        _tessProgram->setUniformValue("MaterialProps",lineMaterial);
        _tessProgram->setUniformValue("ColorFront", white);
        _tessProgram->setUniformValue("ColorBack", white);
        _tessProgram->setUniformValue("DrawingMode", 0); // Smooth
        _scene->render(*_tessProgram);
    }


    emit onPrimitivesDrawn(numPrimitives);

    _tessProgram->release();
}

void MainView::resizeGL(int newWidth, int newHeight) {
    Q_UNUSED(newWidth);
    Q_UNUSED(newHeight);
    // TODO: resizeGL();
}



// =============================================================================
// -- Signals and slots --------------------------------------------------------
// =============================================================================

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

void MainView::setDrawFaces(bool drawFaces) {
    _drawFaces = drawFaces;
}

void MainView::toggleDrawFaces() {
    _drawFaces = !_drawFaces;
}

void MainView::setDrawWireframe(bool drawWireframe) {
    _drawWireframe = drawWireframe;
    update();
}

void MainView::toggleWireFrame() {
    _drawWireframe = !_drawWireframe;
    update();
}

void MainView::setCurrentDrawingMode(int drawingMode) {
    _currentDrawingMode = drawingMode;
    update();
}

void MainView::setEdgeHeuristic(int heuristic) {
    _edgeHeuristic = heuristic;
    qDebug() << "setEdgeHeuristic(" << heuristic << ")";
    update();
}

void MainView::setFaceHeuristic(int heuristic) {
    _faceHeuristic = heuristic;
    qDebug() << "setFaceHeuristic(" << heuristic << ")";
    update();
}

void MainView::setTessellationLevels(int minLevel, int maxLevel) {
    _minTessLevel = minLevel;
    _maxTessLevel = maxLevel;
    update();
}

void MainView::setScene(int sceneID) {
    // Make sure the OpenGL context is current
    this->makeCurrent();
    BezierSceneImporter importer = BezierSceneImporter();
    switch (sceneID) {
    case 0:
        _scene = importer.importBezierScene(":/scenes/bezier/beziersphere.bezier");
        break;
    case 1:
        _scene = importer.importBezierScene(":/scenes/bezier/cone.bezier");
        break;
    case 2:
        _scene = importer.importBezierScene(":/scenes/bezier/rationalbeziersphere.bezier");
        break;
    case 3:
        _scene = importer.importBezierScene(":/scenes/bezier/simpletriangle.bezier");
        break;
    case 4:
        _scene = importer.importBezierScene(":/scenes/bezier/slottedcylinder.bezier");
        break;
    case 5:
        _scene = importer.importBezierScene(":/scenes/bezier/splitin4.bezier");
        break;
    case 6:
        _scene = importer.importBezierScene(":/scenes/bezier/teapot.bezier");
        break;
    case 7:
        _scene = importer.importBezierScene(":/scenes/bezier/testblock.bezier");
        break;
    case 8:
        _scene = importer.importBezierScene(":/scenes/bezier/floating.bezier");
        break;
    case 9:
        _scene = importer.importBezierScene(":/scenes/bezier/extremecurvature.bezier");
        break;
    default:
        _scene = importer.importBezierScene(":/scenes/bezier/teapot.bezier");
        break;
    }
    this->doneCurrent();
    update();
}

void MainView::setProjectionTolerance(double tolerance) {
    _projectionTolerance = static_cast<float>(tolerance);
    update();
}

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
