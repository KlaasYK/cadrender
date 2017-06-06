#include <ui/mainwindow.h>
#include "ui_mainwindow.h"

#include <QApplication>
#include <QStatusBar>
#include <QComboBox>
#include <QSpinBox>
#include <QDoubleSpinBox>

// ----------------------------------------------------------------------------
// -- Constructors and destructor ---------------------------------------------
// ----------------------------------------------------------------------------

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    connect(ui->xSlider, SIGNAL(valueChanged(int)),
            ui->mainView, SLOT(onXRotation(int)), Qt::QueuedConnection);
    connect(ui->ySlider, SIGNAL(valueChanged(int)),
            ui->mainView, SLOT(onYRotation(int)), Qt::QueuedConnection);

    connect(ui->mainView, SIGNAL(onPrimitivesDrawn(int)),
            this, SLOT(onPrimitivesDrawn(int)), Qt::QueuedConnection);
    connect(ui->actionToggleWireframe, SIGNAL(triggered(bool)),
            ui->mainView, SLOT(setDrawWireframe(bool)), Qt::QueuedConnection);
    connect(ui->shadingBox, SIGNAL(currentIndexChanged(int)),
           ui->mainView, SLOT(setCurrentDrawingMode(int)), Qt::QueuedConnection);

    connect(ui->edgeHeuristicBox, SIGNAL(currentIndexChanged(int)),
            ui->mainView, SLOT(setEdgeHeuristic(int)), Qt::QueuedConnection);

    connect(ui->faceHeuristicBox, SIGNAL(currentIndexChanged(int)),
            ui->mainView, SLOT(setFaceHeuristic(int)), Qt::QueuedConnection);

    connect(ui->sceneBox, SIGNAL(currentIndexChanged(int)),
            ui->mainView, SLOT(setScene(int)), Qt::QueuedConnection);

    connect(ui->tolerance, SIGNAL(valueChanged(double)),
            ui->mainView, SLOT(setProjectionTolerance(double)), Qt::QueuedConnection);

}

MainWindow::~MainWindow()
{
    delete ui;
}

// ----------------------------------------------------------------------------
// -- Signals and slots -------------------------------------------------------
// ----------------------------------------------------------------------------

void MainWindow::closeApplication() {
    QApplication::quit();
}

void MainWindow::aboutQt() {
    QApplication::aboutQt();
}

void MainWindow::onPrimitivesDrawn(int numPrimitives) {
    this->statusBar()->clearMessage();
    this->statusBar()->showMessage(QString("%1 primitives").arg(numPrimitives));
}

void MainWindow::on_minTessLevel_valueChanged(int level)
{
    Q_UNUSED(level);
    ui->mainView->setTessellationLevels(
                ui->minTessLevel->value(),
                ui->maxTessLevel->value());
}

void MainWindow::on_maxTessLevel_valueChanged(int level)
{
    Q_UNUSED(level);
    ui->mainView->setTessellationLevels(
                ui->minTessLevel->value(),
                ui->maxTessLevel->value());
}
