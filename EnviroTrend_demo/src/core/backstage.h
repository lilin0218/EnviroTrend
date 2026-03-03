#ifndef BACKSTAGE_H
#define BACKSTAGE_H

#include <QObject>
#include <QDebug>
#include <QVariantMap>
#include <QDateTime>
#include <QTimer>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QList>

class Backstage : public QObject {
    Q_OBJECT

public:
    static Backstage* instance();

    double getTemp() const;
    void setTemp(double temp);
    double getHum() const;
    void setHum(double hum);

    // 为 Core 提供数据访问
    QList<double> getTempBuffer() const;
    QList<double> getHumBuffer() const;

    // 返回当前每个历史数据点时间间隔
    int getMsPerPoint() const {return m_msPerPoint;}

signals:
    void valueSig();   // 实时数据更新
    void bufferSig();  // 缓冲区/采样点更新

public slots:
    void handleDHT11(const QVariantMap &data);
    void processSnapshot(); // 定时采样处理

private:
    explicit Backstage(QObject *parent = nullptr);
    ~Backstage();
    Backstage& operator=(const Backstage&) = delete;

    void initStorage();
    void updateDataFile(double t, double h); // 维护综合 data.csv

    QList<double> m_tempBuffer;
    QList<double> m_humBuffer;

    double m_currentTemp;
    double m_currentHum;

    QTimer *m_sampleTimer;
    const int MAX_POINTS_24H = 1440;      // 24小时采样上限
    const int m_msPerPoint = 60000;    // 60秒采样一次
};

#endif // BACKSTAGE_H
