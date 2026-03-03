#ifndef COREMANAGER_H
#define COREMANAGER_H

#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <QDateTime>
#include "backstage.h"
#include "src/sensor/dht11.h"

class CoreManager : public QObject {
    Q_OBJECT
    // 当前显示
    Q_PROPERTY(QString tempStr READ tempStr NOTIFY valueSig)
    Q_PROPERTY(QString humStr READ humStr NOTIFY valueSig)

    // 历史缓冲区（实测数据）
    Q_PROPERTY(QList<double> tempBuffer READ tempBuffer NOTIFY bufferSig)
    Q_PROPERTY(QList<double> humBuffer READ humBuffer NOTIFY bufferSig)

    // 预测数据（AI输出）
    Q_PROPERTY(QVariantList predictedTempList READ predictedTempList NOTIFY predictionUpdated)
    Q_PROPERTY(QVariantList predictedHumList READ predictedHumList NOTIFY predictionUpdated)
    Q_PROPERTY(bool isAiBusy READ isAiBusy NOTIFY aiStatusChanged)

    // 时间轴基准
    Q_PROPERTY(qint64 baseTime READ baseTime NOTIFY predictionUpdated)

public:
    explicit CoreManager(QObject *parent = nullptr);

    Q_INVOKABLE void setSensorActive(int id, bool active);
    Q_INVOKABLE void setSensorInterval(int id, int sec);
    Q_INVOKABLE bool getSensorActive(int id);
    Q_INVOKABLE int getSensorInterval(int id);

    // 返回毫秒数，供 QML updateSeries 中的 msPerPoint 使用
    Q_INVOKABLE int getMsPerPoint() const { return m_backstage->getMsPerPoint(); }

    // --- 修改 3: 确保 runPrediction 也是 INVOKABLE ---
    Q_INVOKABLE void runPrediction();

    QString tempStr() const;
    QString humStr() const;
    QList<double> tempBuffer() const;
    QList<double> humBuffer() const;

    QVariantList predictedTempList() const { return m_predictedTempList; }
    QVariantList predictedHumList() const { return m_predictedHumList; }
    qint64 baseTime() const { return m_baseTime; }
    bool isAiBusy() const;

signals:
    void valueSig();
    void bufferSig();
    void sensorSig(int id);
    void predictionUpdated();
    void aiStatusChanged();

private slots:
    void onBackstageDataChanged();
    void handleProcessOutput();

private:
    Backstage *m_backstage;
    DHT11 *m_dht11;

    QProcess* m_predictProcess;
    QVariantList m_predictedTempList;
    QVariantList m_predictedHumList;
    qint64 m_baseTime = 0;
    bool m_isAiBusy = false;
};

#endif // COREMANAGER_H
