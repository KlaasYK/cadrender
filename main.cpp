#include <ui/mainwindow.h>

#include <QApplication>
#include <QSurfaceFormat>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    // Set up logging format
    qSetMessagePattern("%{if-debug}D%{endif}%{if-info}I%{endif}%{if-warning}W%{endif}%{if-critical}C%{endif}%{if-fatal}F%{endif}] %{message} (%{function}:%{line})");

    // Setup OpenGL 4.5 (needs atleast 4.1)
    QSurfaceFormat glFormat;
    glFormat.setVersion(4, 5);
    glFormat.setProfile(QSurfaceFormat::CoreProfile);
    glFormat.setOption(QSurfaceFormat::DebugContext);
    QSurfaceFormat::setDefaultFormat(glFormat);

    MainWindow w;
    w.show();

    return a.exec();
}
