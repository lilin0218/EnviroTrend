#ifndef DHT11_H
#define DHT11_H

#include <QThread>
#include <QVariantMap>
#include <QDateTime>
#include <QDebug>
#include <QtMath>

#ifdef Q_OS_LINUX
#include <fcntl.h>
#include <unistd.h>
#endif

class DHT11 : public QThread {
    Q_OBJECT
public:
    explicit DHT11(QObject *parent = nullptr);
    ~DHT11() override;

    void setActive(bool active);
    bool getActive();
    void setInterval(int interval);
    int getInterval();

signals:
    void valueSig(const QVariantMap &data);
    void errorOccurred(const QString &msg);

protected:
    void run() override;

private:
    bool init();
    void readData();

    int m_fd;
    bool m_active;
    int m_interval;
    double m_tick; // 用于模拟数据的正弦波步进
};

#endif // DHT11_H
