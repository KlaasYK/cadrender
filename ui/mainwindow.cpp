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
