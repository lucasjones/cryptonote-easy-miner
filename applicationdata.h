#ifndef APPLICATIONDATA_H
#define APPLICATIONDATA_H

#include <QObject>
#include <QProcess>

class ApplicationData : public QObject
{
    Q_OBJECT
public:

    ApplicationData() { }

    Q_INVOKABLE int numThreads() const;
    Q_INVOKABLE void startCpuMiner(int numThreads, QString protocol, QString url, int port, QString address);
    Q_INVOKABLE void stopCpuMiner();
    Q_INVOKABLE bool cpuSupportsAES();

signals:
    void minerOutput(QString output);
    void minerStarted();
    void minerStopped();
    void hashrateUpdated(float hashrate);
    void difficultyUpdated(float difficulty);
    void shareSubmitted(float difficulty);
    void workReceived();

private:
    QProcess *minerProcess = nullptr;

private slots:

    void minerReadyRead();
    void minerFinished(int code, QProcess::ExitStatus status);
    void minerError(QProcess::ProcessError);

};

#endif // APPLICATIONDATA_H
