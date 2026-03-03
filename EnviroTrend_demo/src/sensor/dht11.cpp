#include "dht11.h"

DHT11::DHT11(QObject *parent)
    : QThread(parent),
      m_fd(-1),
      m_active(true),
      m_interval(1000), // 默认1秒
      m_tick(0.0)
{
#ifdef IS_BOARD
    qDebug() << "Compile Check: IS_BOARD is DEFINED";
#else
    qDebug() << "Compile Check: IS_BOARD is NOT DEFINED";
#endif
}

DHT11::~DHT11() {
    m_active = false;
    this->quit();
    this->wait();
#ifdef IS_BOARD
    if (m_fd != -1) ::close(m_fd);
#endif
}

bool DHT11::init() {
    // 只有在开发板模式下才尝试打开硬件设备
#ifdef IS_BOARD
    m_fd = ::open("/dev/dht11", O_RDONLY);
    if (m_fd < 0) {
        emit errorOccurred("[ERROR] DHT11: Cannot open /dev/dht11 (Board Mode)");
        return false;
    }
    qDebug() << "[INFO] DHT11: Hardware initialized on Board.";
    return true;
#else
    // Windows 或 Linux 虚拟机进入此分支
    qDebug() << "[INFO] DHT11: Running in Mock Mode (Simulator).";
    return true;
#endif
}

void DHT11::readData() {
#ifdef IS_BOARD
    // 1. 开发板硬件读取逻辑
    if (m_fd < 0) return;

    char rawBuf[32] = {0};
    ssize_t bytesRead = ::read(m_fd, rawBuf, sizeof(rawBuf));

    if (bytesRead >= 5) {
        double humInt  = static_cast<unsigned char>(rawBuf[0]);
        double humDec  = static_cast<unsigned char>(rawBuf[1]);
        double tempInt = static_cast<unsigned char>(rawBuf[2]);
        double tempDec = static_cast<unsigned char>(rawBuf[3]);

        double humidity = humInt + (humDec / 10.0);
        double temperature = tempInt + (tempDec / 10.0);

        QVariantMap data;
        data["humidity"] = humidity;
        data["temperature"] = temperature;
        data["timestamp"] = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
        emit valueSig(data);
    }
#else
    // 2. Windows/虚拟机 模拟逻辑 (Win & Linux VM 共享)
    m_tick += 0.1;
    double mockTemp = 22.0 + 3.0 * qSin(m_tick); // 模拟 19-25 度波动
    double mockHumi = 50.0 + 5.0 * qCos(m_tick); // 模拟 45-55 湿度波动

    QVariantMap data;
    data["humidity"] = mockHumi;
    data["temperature"] = mockTemp;
    data["timestamp"] = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
    emit valueSig(data);
#endif
}

void DHT11::run() {
    if (!init()) return;

    while (m_active) {
        readData();
        this->msleep(static_cast<unsigned long>(m_interval));
    }
}

// --- Getter/Setter 保持不变 ---
void DHT11::setActive(bool active) {
    if(active && !this->isRunning()) this->start();
    m_active = active;
}

bool DHT11::getActive() { return m_active; }

void DHT11::setInterval(int interval) {
    if (interval >= 100 && interval <= 5000) m_interval = interval;
}

int DHT11::getInterval() { return m_interval; }
