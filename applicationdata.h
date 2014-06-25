#ifndef APPLICATIONDATA_H
#define APPLICATIONDATA_H

#include <QObject>
#include <QThread>

class ApplicationData : public QObject
{
    Q_OBJECT
public:

    Q_INVOKABLE int numThreads() const {
        return QThread::idealThreadCount();
    }

};

#endif // APPLICATIONDATA_H
