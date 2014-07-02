TEMPLATE = app

QT += qml quick

QMAKE_CXXFLAGS += -std=c++11
QMAKE_LFLAGS += -std=c++11

SOURCES += main.cpp \
    applicationdata.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
include(deployment.pri)

OTHER_FILES += \
    README.md

HEADERS += \
    applicationdata.h
