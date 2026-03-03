import QtQuick 2.11
import QtQuick.Controls 2.4
import "qrc:/qml/common"

Rectangle {
    id: card
    radius: 12.0

    // --- 动态样式绑定 (核心逻辑) ---
    // 假设 core 提供 isActive(id) 和 getInterval(id) 接口
    // 这里我们先模拟绑定到 core 的属性上
    property bool active: core.getSensorActive(sensorId) // 以后可以根据 sensorId 动态绑定
    property int interval: core.getSensorInterval(sensorId)

    color: active ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.03)
    border.color: active ? Theme.accentBlue : "#444444"
    border.width: active ? 1.5 : 1.0

    property string label: ""
    property string value: ""
    property string unit: ""
    property string iconSource_checked: "qrc:/res/placeholder.png"
    property string iconSource_unchecked: "qrc:/res/placeholder.png"
    property int sensorId: -1
    property string sensorName: ""

    // 交互：双季/右键弹出菜单
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onDoubleClicked: sensorMenu.open()
        onClicked: if (mouse.button === Qt.RightButton) sensorMenu.open()
    }

    // --- 内容区域 ---
    Row {
        anchors.fill: parent
        anchors.margins: parent.width * 0.08
        spacing: parent.width * 0.05
        opacity: card.active ? 1.0 : 0.4 // 未启用时整体变暗

        // SensorCard.qml 内部的图片逻辑
        Item {
            width: parent.height; height: width
            anchors.verticalCenter: parent.verticalCenter

            // 未选中/禁用 状态的图标
            Image {
                anchors.fill: parent
                source: iconSource_unchecked
                opacity: card.active ? 0.0 : 1.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // 选中/启用 状态的图标
            Image {
                anchors.fill: parent
                source: iconSource_checked
                opacity: card.active ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: card.label;
                color: card.active ? Theme.textSecondary : "#666666"
                font.pixelSize: card.height * 0.15
            }
            Text {
                text: card.active ? (card.value + " " + card.unit) : "已禁用"
                color: card.active ? Theme.textMain : "#888888"
                font.bold: true; font.pixelSize: card.height * 0.22
            }
        }
    }

    // --- 模态配置菜单 ---
    Popup {
        id: sensorMenu
        parent: Overlay.overlay
        modal: true; dim: true; focus: true
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: parent.width * 0.7; height: parent.height * 0.55
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#2A2A2A"; radius: 15; border.color: Theme.accentBlue
            MouseArea { anchors.fill: parent }
        }

        contentItem: Column {
            anchors.fill: parent; anchors.margins: 20; spacing: 20

            Text {
                width: parent.width
                text: "正在快捷设置 "+ sensorName +" 传感器"
                color: Theme.accentBlue; font.bold: true; horizontalAlignment: Text.AlignHCenter
                font.pixelSize: parent.height * 0.08
            }

            // 启用开关：直接修改 core
            Row {
                width: parent.width; height: 40; spacing: 20
                Text { text: "启用状态："; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                Switch {
                    checked: active // 绑定 Core
                    onToggled: {
                        // 调用 Core 的方法修改数据
                        core.setSensorActive(card.sensorId, checked)
                    }
                }
            }

            // 刷新频率：直接修改 core
            Row {
                width: parent.width; height: 40; spacing: 20
                Text { text: "刷新间隔："; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                SpinBox {
                    from: 100; to: 5000
                    value: interval // 绑定 Core
                    onValueModified: {
                        core.setSensorInterval(card.sensorId, value)
                    }
                }
                Text { text: "ms"; color: "#888"; anchors.verticalCenter: parent.verticalCenter }
            }

            Text {
                width: parent.width
                text: "单击弹窗外部区域以退出"
                color: "#555"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // 监听 core 的信号
    Connections {
        target: core
        onSensorSig: {
            if(id !== card.sensorId) return
            // 当 core 发出 dataUpdated 信号时，手动刷新这个属性
            card.active = core.getSensorActive(card.sensorId)
            card.interval = core.getSensorInterval(card.sensorId)
        }
    }
}
