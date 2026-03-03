#include "backstage.h"

Backstage::Backstage(QObject *parent)
    : QObject(parent), m_currentTemp(0.0), m_currentHum(0.0) {

    initStorage();

    // 初始化采样定时器
    m_sampleTimer = new QTimer(this);
    connect(m_sampleTimer, &QTimer::timeout, this, &Backstage::processSnapshot);
    m_sampleTimer->start(m_msPerPoint);
}

Backstage::~Backstage() {
    if (m_sampleTimer->isActive()) {
        m_sampleTimer->stop();
    }
}

Backstage *Backstage::instance() {
    static Backstage _instance;
    return &_instance;
}

void Backstage::initStorage() {
    QDir dir;
    if (!dir.exists("csvData")) {
        dir.mkdir("csvData");
    }
}

// 核心修改：将温湿度同时存入 data.csv，适配 Python 端的读取要求
void Backstage::updateDataFile(double t, double h) {
    QString path = "csvData/data.csv";
    QStringList lines;

    // 1. 读取现有数据
    QFile readFile(path);
    if (readFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&readFile);
        while (!in.atEnd()) {
            lines.append(in.readLine());
        }
        readFile.close();
    }

    // 2. 维护最大行数（保留表头）
    const int MAX_TOTAL_LINES = MAX_POINTS_24H + 1;
    while (lines.size() >= MAX_TOTAL_LINES) {
        if (lines.size() > 1) {
            lines.removeAt(1); // 移除最早的一条数据
        } else {
            break;
        }
    }

    // 3. 构造新行：timestamp,temp,hum (注意：必须使用 double 以保证精度)
    QString now = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    QString newLine = QString("%1,%2,%3").arg(now)
                          .arg(t, 0, 'f', 2)
                          .arg(h, 0, 'f', 2);

    if (lines.isEmpty()) {
        lines.append("timestamp,temp,hum");
    }
    lines.append(newLine);

    // 4. 写入文件
    QFile writeFile(path);
    if (writeFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&writeFile);
        for (const QString &line : lines) {
            out << line << "\n";
        }
        writeFile.close();
    }
}

void Backstage::processSnapshot() {
    // 更新内存缓冲区
    auto updateBuf = [this](QList<double> &list, double val) {
        list.append(val);
        if (list.size() > MAX_POINTS_24H) {
            list.removeFirst();
        }
    };

    updateBuf(m_tempBuffer, m_currentTemp);
    updateBuf(m_humBuffer, m_currentHum);

    // 持久化到 data.csv
    updateDataFile(m_currentTemp, m_currentHum);

    emit bufferSig();
}

// --- Getter / Setter ---

double Backstage::getTemp() const { return m_currentTemp; }
double Backstage::getHum() const { return m_currentHum; }

void Backstage::setTemp(double temp) { m_currentTemp = temp; }
void Backstage::setHum(double hum) { m_currentHum = hum; }

QList<double> Backstage::getTempBuffer() const { return m_tempBuffer; }
QList<double> Backstage::getHumBuffer() const { return m_humBuffer; }

void Backstage::handleDHT11(const QVariantMap &data) {
    if (data.contains("temperature")) {
        setTemp(data["temperature"].toDouble());
    }
    if (data.contains("humidity")) {
        setHum(data["humidity"].toDouble());
    }
    emit valueSig();
}
