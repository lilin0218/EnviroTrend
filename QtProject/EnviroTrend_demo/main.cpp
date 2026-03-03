#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <src/core/coremanager.h>
#include <QIcon>
#include <QQmlContext>
#include <QApplication>

int main(int argc, char *argv[])
{
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

    QIcon icon("qrc:/res/logo/logo_transparentbg.png");
    app.setWindowIcon(icon);

    QQmlApplicationEngine engine;

    // 注册core给qml
    CoreManager *manager = new CoreManager(&app);
    engine.rootContext()->setContextProperty("core", manager);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
