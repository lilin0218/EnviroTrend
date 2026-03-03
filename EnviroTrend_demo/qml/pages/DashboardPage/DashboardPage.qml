import QtQuick 2.11

Item {
    id: dashboardRoot
    anchors.fill: parent

    // 动态比例计算 (Double)
    readonly property double marginSize: width * 0.04
    readonly property double cellSpacing: width * 0.02

    // 计算 2列 3行 的卡片尺寸
    readonly property double cardWidth: (width - (marginSize * 2.0) - cellSpacing) / 2.0
    readonly property double cardHeight: (height - (marginSize * 2.0) - (cellSpacing * 2.0)) / 3.0

    Grid {
        anchors.fill: parent
        anchors.margins: dashboardRoot.marginSize
        columns: 2
        spacing: dashboardRoot.cellSpacing

        // 1. 温度 - 绑定 Core 中的 tempStr
        SensorCard {
            width: cardWidth; height: cardHeight
            label: "环境温度"; unit: "°C"
            value: core.tempStr // 这里的 backstage 是你在 main.cpp 注册的对象名
            sensorId: 0 // 温湿度设为同组，逻辑同步
            sensorName: "DHT11"
            iconSource_checked: "qrc:/res/sensor/temp_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/temp_unchecked.png"
        }

        // 2. 湿度 - 绑定 Core 中的 humStr
        SensorCard {
            width: cardWidth; height: cardHeight
            label: "相对湿度"; unit: "%"
            value: core.humStr
            sensorId: 0
            sensorName: "DHT11"
            iconSource_checked: "qrc:/res/sensor/hum_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/hum_unchecked.png"
        }

        SensorCard {
            width: cardWidth; height: cardHeight
            label: "光照强度"; unit: "Lux";
            value: "101.32"
            sensorId: 1
            sensorName: "光照传感器"
            iconSource_checked: "qrc:/res/sensor/light_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/light_unchecked.png"
        }

        SensorCard {
            width: cardWidth; height: cardHeight
            label: "空气颗粒度"; unit: "m";
            value: "550.00"
            sensorId: 2
            sensorName: "MQ-135"
            iconSource_checked: "qrc:/res/sensor/particle_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/particle_unchecked.png"
        }

        SensorCard {
            width: cardWidth; height: cardHeight
            label: "空气质量"; unit: "μg/m³";
            value: "405.00"
            sensorId: 3
            sensorName: "空气质量传感器"
            iconSource_checked: "qrc:/res/sensor/aqi_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/aqi_unchecked.png"
        }

        SensorCard {
            width: cardWidth; height: cardHeight
            label: "噪音"; unit: "db";
            value: "12.00"
            sensorId: 4
            sensorName: "噪音传感器"
            iconSource_checked: "qrc:/res/sensor/noise_checked.png"
            iconSource_unchecked: "qrc:/res/sensor/noise_unchecked.png"
        }
    }
}
