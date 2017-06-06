#ifndef MAINVIEW_H
#define MAINVIEW_H

#include <geom/beziertriangle.h>
#include <gl/bezierscene.h>


#include <QMatrix3x3>
#include <QMatrix4x4>
#include <QMouseEvent>
#include <QOpenGLDebugLogger>
#include <QOpenGLFunctions_4_5_Core>
#include <QOpenGLShaderProgram>
#include <QOpenGLWidget>
#include <QPointer>

class MainView : public QOpenGLWidget, protected QOpenGLFunctions_4_5_Core
{

    Q_OBJECT

    // =========================================================================
    // -- Enumerators ----------------------------------------------------------
    // =========================================================================

    enum MouseState {
        None = 0,
        Rotate,
        Scale,
        Translate,
        NUM_MOUSE_STATES
    };

    // =========================================================================
    // -- Constructors and destructor ------------------------------------------
    // =========================================================================

public:

    explicit MainView(QWidget *parent = 0);

    ~MainView();

    // =========================================================================
    // -- QWidget --------------------------------------------------------------
    // =========================================================================

protected:

    virtual void mousePressEvent(QMouseEvent *event) override;

    virtual void mouseMoveEvent(QMouseEvent *event) override;

    virtual void wheelEvent(QWheelEvent *event) override;

    // =========================================================================
    // -- QOpenGLWidget --------------------------------------------------------
    // =========================================================================

protected:

    virtual void initializeGL() override;

    virtual void paintGL() override;

    virtual void resizeGL(int newWidth, int newHeight) override;



    // =========================================================================
    // -- Signals and slots ----------------------------------------------------
    // =========================================================================

signals:

    void onPrimitivesDrawn(int numPrimitives);

public slots:

    void onXRotation(int rotation);

    void onYRotation(int rotation);

    void setDrawFaces(bool drawFaces);

    void toggleDrawFaces();

    void setDrawWireframe(bool drawWireframe);

    void toggleWireFrame();

    void setCurrentDrawingMode(int drawingMode);

    void setEdgeHeuristic(int heuristic);

    void setFaceHeuristic(int heuristic);

    void setTessellationLevels(int minLevel, int maxLevel);

    void setScene(int sceneID);

private slots:

    void onMessageLogged(QOpenGLDebugMessage message);

    // =========================================================================
    // -- Ohter methods --------------------------------------------------------
    // =========================================================================

private:

    void createTessellationProgram();

    void createSimpleProgram();

    // =========================================================================
    // -- Data members ---------------------------------------------------------
    // =========================================================================

private:

    QPointer<QOpenGLDebugLogger> _debugLogger;

    QPointer<QOpenGLShaderProgram> _simpleProgram;

    QPointer<QOpenGLShaderProgram> _tessProgram;

    QSharedPointer<BezierScene> _scene;

    int _xRot, _yRot;

    QMatrix4x4 _rotationMatrix;

    int _lastX, _lastY;

    float _scale;

    GLuint _primitiveQuery;

    MouseState _currentMouseState;

    bool _drawFaces, _drawWireframe;

    int _currentDrawingMode;
    int _edgeHeuristic;
    int _faceHeuristic;
    int _minTessLevel, _maxTessLevel;

};

#endif // MAINVIEW_H
