#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

    // ----------------------------------------------------------------------------
    // -- Constructors and destructor ---------------------------------------------
    // ----------------------------------------------------------------------------

public:

    explicit MainWindow(QWidget *parent = 0);

    ~MainWindow();

    // ----------------------------------------------------------------------------
    // -- Signals and slots -------------------------------------------------------
    // ----------------------------------------------------------------------------

public slots:

    void closeApplication();

    void aboutQt();

    void onPrimitivesDrawn(int);

    // ----------------------------------------------------------------------------
    // -- Data members ------------------------------------------------------------
    // ----------------------------------------------------------------------------

private:

    Ui::MainWindow *ui;
};

#endif // MAINWINDOW_H
