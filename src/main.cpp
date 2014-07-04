#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "applicationdata.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    ApplicationData data;
    engine.rootContext()->setContextProperty("applicationData", &data);
    engine.load(QUrl(QStringLiteral("qrc:///qml/main.qml")));

    return app.exec();
}
