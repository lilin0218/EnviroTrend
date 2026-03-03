#include "coremanager.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QCoreApplication>

CoreManager::CoreManager(QObject *parent) : QObject(parent) {
    m_backstage = Backstage::instance();
    m_dht11 = new DHT11(this);

    // 传感器逻辑连线
    connect(m_dht11, &DHT11::valueSig, m_backstage, &Backstage::handleDHT11);
    connect(m_backstage, &Backstage::valueSig, this, &CoreManager::onBackstageDataChanged);
    connect(m_backstage, &Backstage::bufferSig, this, &CoreManager::bufferSig);

    m_dht11->start();

    // 预测进程初始化
    m_predictProcess = new QProcess(this);

    connect(m_predictProcess, &QProcess::readyReadStandardOutput, this, &CoreManager::handleProcessOutput);

    // 关键：当后台数据文件 data.csv 更新后触发预测
    connect(m_backstage, &Backstage::bufferSig, this, &CoreManager::runPrediction);

    // 错误处理
    connect(m_predictProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error){
        qDebug() << "[AI Error]:" << m_predictProcess->readAllStandardError();
        m_isAiBusy = false;
        emit aiStatusChanged();
    });

    connect(m_predictProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus exitStatus){
        qDebug() << "[DEBUG] AI Process Exit! Code:" << exitCode << " Status:" << exitStatus;
        m_isAiBusy = false;
        emit aiStatusChanged();
    });
}

void CoreManager::runPrediction() {
    if (m_isAiBusy || m_predictProcess->state() != QProcess::NotRunning){
        qDebug()<<"由于不符合py进程启动条件，退出";
        return;
    }

    QString scriptPath = QCoreApplication::applicationDirPath() + "/predict.py";

    if (!QFile::exists(scriptPath)) {
        qCritical() << "predict.py not found!";
        return;
    }

    m_isAiBusy = true;
    emit aiStatusChanged();

    // 适配最新脚本参数：python3 predict.py [点数] [间隔]
    QStringList args;
    args << "predict.py" << "60" << "60";

    m_predictProcess->start("python3", args);
}

void CoreManager::handleProcessOutput() {
    // 1. 读取原始输出并修剪两端空白
    QByteArray rawOutput = m_predictProcess->readAllStandardOutput().trimmed();

    // 强制打印原始输出，方便在终端查看到底输出了什么
    qDebug() << "[AI] --- 原始输出开始 ---";
    qDebug() << rawOutput;
    qDebug() << "[AI] --- 原始输出结束 ---";

    if (rawOutput.isEmpty()) {
        qWarning() << "[AI] 警告: 进程输出为空";
        return;
    }

    // 2. 增强解析：尝试自动寻找 JSON 数组的起始位置 '['
    // 这样可以过滤掉 Python 库输出的干扰信息（如 torch 的警告）
    int jsonStartIndex = rawOutput.indexOf("[{");
    QByteArray cleanJson = (jsonStartIndex != -1) ? rawOutput.mid(jsonStartIndex) : rawOutput;

    QJsonDocument doc = QJsonDocument::fromJson(cleanJson);

    // 输出原始 doc 的状态（转为字符串展示）
    if (!doc.isNull()) {
        // qDebug() << "[AI] 解析成功后的 JSON 内容:" << doc.toJson(QJsonDocument::Compact);
    }

    if (!doc.isNull() && doc.isArray()) {
        QJsonArray arr = doc.array();

        m_predictedTempList.clear();
        m_predictedHumList.clear();

        for (int i = 0; i < arr.size(); ++i) {
            QJsonObject obj = arr[i].toObject();
            m_predictedTempList << obj["temp"].toDouble();
            m_predictedHumList << obj["hum"].toDouble();

            // 以预测结果的第一个点的时间戳作为图表基准起始时间
            if (i == 0) {
                QString tsStr = obj["timestamp"].toString();
                qDebug() << "[AI] 提取到第一个点时间戳字符串:" << tsStr;

                QDateTime dt = QDateTime::fromString(tsStr, "yyyy-MM-dd HH:mm:ss");
                if (dt.isValid()) {
                    m_baseTime = dt.toMSecsSinceEpoch();
                    qDebug() << "[AI] 成功转换 baseTime 为毫秒:" << m_baseTime;
                } else {
                    qWarning() << "[AI] 错误: 时间格式无法解析，请检查 Python 输出格式是否为 yyyy-MM-dd HH:mm:ss";
                    // 兜底策略：如果解析失败，使用当前系统时间
                    m_baseTime = QDateTime::currentMSecsSinceEpoch();
                }
            }
        }

        // 数据更新完成后再发送信号
        emit predictionUpdated();
        qDebug() << "[AI] 预测数据解析并发送完毕，点数:" << m_predictedTempList.size();

    } else {
        qWarning() << "[AI] 解析失败: 输出不是有效的 JSON 数组。尝试解析的文本长度:" << cleanJson.length();
    }
}
// --- 基础接口实现 ---

QString CoreManager::tempStr() const { return QString::number(m_backstage->getTemp(), 'f', 1); }
QString CoreManager::humStr() const { return QString::number(m_backstage->getHum(), 'f', 1); }
QList<double> CoreManager::tempBuffer() const { return m_backstage->getTempBuffer(); }
QList<double> CoreManager::humBuffer() const { return m_backstage->getHumBuffer(); }
bool CoreManager::isAiBusy() const { return m_isAiBusy; }

void CoreManager::onBackstageDataChanged() { emit valueSig(); }

void CoreManager::setSensorActive(int id, bool active) {
    if(id == 0) m_dht11->setActive(active);
    emit sensorSig(id);
}

void CoreManager::setSensorInterval(int id, int sec) {
    if(id == 0) m_dht11->setInterval(sec);
    emit sensorSig(id);
}

bool CoreManager::getSensorActive(int id) {
    return (id == 0) ? m_dht11->getActive() : false;
}

int CoreManager::getSensorInterval(int id) {
    return (id == 0) ? m_dht11->getInterval() : -1;
}
