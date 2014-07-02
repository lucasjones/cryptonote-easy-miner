#include "applicationdata.h"

#include <QThread>
#include <QDir>
#include <QDebug>

int ApplicationData::numThreads() const
{
    return QThread::idealThreadCount();
}

void cpuid(unsigned info, unsigned *eax, unsigned *ebx, unsigned *ecx, unsigned *edx)
{
    *eax = info;
    __asm volatile
            ("mov %%ebx, %%edi;"
             "cpuid;"
             "mov %%ebx, %%esi;"
             "mov %%edi, %%ebx;"
             :"+a" (*eax), "=S" (*ebx), "=c" (*ecx), "=d" (*edx)
             : :"edi");
}

bool ApplicationData::cpuSupportsAES()
{
    quint32 eax, ebx, ecx, edx;
    cpuid(1, &eax, &ebx, &ecx, &edx);
    return ((edx & 0x2000000) != 0);
}

void ApplicationData::startCpuMiner(int numThreads, QString protocol, QString url, int port, QString address)
{
    if(minerProcess && minerProcess->state() == QProcess::Running) {
        qDebug() << "Killing old miner thread...";
        minerProcess->kill();
        minerProcess->waitForFinished();
    }

    if(address.length() != 95) {
        emit minerOutput("Invalid address: " + address + "\n");
        return;
    }

    bool aes_ni = cpuSupportsAES();
    QString minerd = QDir::currentPath() + "/bin/minerd" +
            (aes_ni ? "-aesni" : "") + PLATFORM_BINARY_SUFFIX;

    QStringList arguments;
    arguments << "-o" << (protocol == "http" ? "http://" : "stratum+tcp://") + url + ":" + QString::number(port);
    arguments << "-a" << "cryptonight";
    arguments << "-u" << address;
    arguments << "-p" << "x";
    arguments << "-t" << QString::number(numThreads);

    qDebug() << "Launching" << minerd << "Threads:" << numThreads;
    qDebug() << "Arguments: " << arguments;
    minerProcess = new QProcess(this);
    minerProcess->setReadChannelMode(QProcess::MergedChannels);
    connect(minerProcess, SIGNAL(error(QProcess::ProcessError)),
            this, SLOT(minerError(QProcess::ProcessError)));
    connect(minerProcess, SIGNAL(readyRead()),
            this, SLOT(minerReadyRead()));
    connect(minerProcess, SIGNAL(finished(int,QProcess::ExitStatus)),
            this, SLOT(minerFinished(int,QProcess::ExitStatus)));
    connect(minerProcess, SIGNAL(started()),
            this, SIGNAL(minerStarted()));
    minerProcess->start(minerd, arguments, QIODevice::ReadOnly);
}

void ApplicationData::stopCpuMiner()
{
    if(minerProcess && minerProcess->state() == QProcess::Running) {
        qDebug() << "Killing miner thread...";
        minerProcess->kill();
        emit minerOutput("Mining stopped.\n");
    }
}

void ApplicationData::minerReadyRead()
{
    while(minerProcess->canReadLine()) {
        QString line = minerProcess->readLine();
        if(line.mid(22, 17) == "Pool set diff to ") {
            emit difficultyUpdated(line.mid(39).toFloat());
            emit workReceived();
        } else if(line.mid(22, 10) == "accepted: ") {
            int hashrateBegin = line.indexOf("), ") + 3;
            int hashrateLength = line.indexOf(" H/s") - hashrateBegin;

            if(hashrateBegin != -1 && hashrateLength > 0)
                emit hashrateUpdated(line.mid(hashrateBegin, hashrateLength).toFloat());

            int diffBegin  = line.indexOf(" at diff ") + 9;
            int diffLength = line.indexOf(" (yay!!!)") - diffBegin;
            if(diffBegin != -1 && diffLength > 0)
                emit shareSubmitted(line.mid(diffBegin, diffLength).toFloat());
        } else if (line.mid(22, 26) == "Stratum detected new block") {
            emit workReceived();
        }
        emit minerOutput(line);
    }
}

void ApplicationData::minerFinished(int code, QProcess::ExitStatus status)
{
    qDebug() << "Miner process finished. code:" << code << "status:" << status;
    disconnect(minerProcess, SIGNAL(error(QProcess::ProcessError)),
               this, SLOT(minerError(QProcess::ProcessError)));
    disconnect(minerProcess, SIGNAL(readyRead()),
               this, SLOT(minerReadyRead()));
    disconnect(minerProcess, SIGNAL(finished(int,QProcess::ExitStatus)),
               this, SLOT(minerFinished(int,QProcess::ExitStatus)));
    disconnect(minerProcess, SIGNAL(started()),
               this, SIGNAL(minerStarted()));
    minerProcess->deleteLater();
    minerProcess = nullptr;

    emit minerStopped();
}

void ApplicationData::minerError(QProcess::ProcessError)
{
    qDebug() << "Miner process error'd";
}

double ApplicationData::parseDouble(QString str)
{
    return str.toDouble();
}
