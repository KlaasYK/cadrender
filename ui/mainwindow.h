#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

// =============================================================================
// -- Constructors and destructor ----------------------------------------------
// -----------------------------------------------------------------------------

public:

    explicit MainWindow(QWidget *parent = 0);

    ~MainWindow();

// ----------------------------------------------------------------------------
// -- Signals and slots -------------------------------------------------------
// ----------------------------------------------------------------------------

private slots:

    void closeApplication();

    void aboutQt();

    void onPrimitivesDrawn(int);

// --- Automaticly generated slots ---------------------------------------------

    void on_minTessLevel_valueChanged(int level);

    void on_maxTessLevel_valueChanged(int level);

// -----------------------------------------------------------------------------
// -- Data members -------------------------------------------------------------
// -----------------------------------------------------------------------------

private:

    Ui::MainWindow *ui;
};

#endif // MAINWINDOW_H
