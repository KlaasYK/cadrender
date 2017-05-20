#ifndef MAINVIEW_H
#define MAINVIEW_H

#include <geom/beziertriangle.h>
#include <gl/bezierscene.h>

#include <QOpenGLDebugLogger>
#include <QOpenGLFunctions_4_5_Core>
#include <QOpenGLShaderProgram>
#include <QOpenGLWidget>
#include <QPointer>

class MainView : public QOpenGLWidget, protected QOpenGLFunctions_4_5_Core
{

    Q_OBJECT

    // =========================================================================
    // -- Constructors and destructor ------------------------------------------
    // =========================================================================

public:

    explicit MainView(QWidget *parent = 0);

    ~MainView();

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

};

#endif // MAINVIEW_H
