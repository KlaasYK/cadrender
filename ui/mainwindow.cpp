#include <ui/mainwindow.h>
#include "ui_mainwindow.h"

#include <QApplication>

// ----------------------------------------------------------------------------
// -- Constructors and destructor ---------------------------------------------
// ----------------------------------------------------------------------------

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    connect(ui->xSlider, SIGNAL(valueChanged(int)),
            ui->mainView, SLOT(onXRotation(int)));
    connect(ui->ySlider, SIGNAL(valueChanged(int)),
            ui->mainView, SLOT(onYRotation(int)));
    connect(ui->mainView, SIGNAL(onPrimitivesDrawn(int)),
            this, SLOT(onPrimitivesDrawn(int)));

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
    this->statusBar()->showMessage(QString("%1 primitives").arg(numPrimitives));
}
