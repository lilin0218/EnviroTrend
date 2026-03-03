import QtQuick 2.11
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.0 // 必须导入，用于处理形状遮罩

Button {
    id: control

    // 自定义属性
    property string shape: "Rect" // "Rect", "Circle", "Rhombus"
    property color themeColor: "#21be2b"
    property real borderWidth: 3.0
    property color activeBorderColor: "#ffffff"
    property color idleBorderColor: Qt.darker(themeColor, 1.5)

    implicitWidth: 120
    implicitHeight: 50

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.pressed ? "#eeeeee" : "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        z: 10
    }

    background: Item {
        id: backgroundItem

        // 核心形状定义
        Rectangle {
            id: mainShape
            anchors.fill: parent
            anchors.margins: control.shape === "Rhombus" ? 8 : 0 // 为菱形旋转留出余量
            color: control.pressed ? Qt.darker(control.themeColor, 1.4) :
                   (control.hovered ? Qt.lighter(control.themeColor, 1.2) : control.themeColor)

            radius: control.shape === "Circle" ? width / 2 : 0
            rotation: control.shape === "Rhombus" ? 45 : 0

            border.width: control.borderWidth
            border.color: (control.hovered || control.pressed) ? control.activeBorderColor : control.idleBorderColor

            // 交互时的边框和颜色过渡动画
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Behavior on color { ColorAnimation { duration: 150 } }

            // 开启图层渲染，以便后续进行波纹裁剪
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: mainShape // 自身作为遮罩，波纹绝不会溢出
            }

            // --- 波纹逻辑 ---
            Rectangle {
                id: ripple
                property real maxSide: Math.max(parent.width, parent.height) * 2.5
                width: 0; height: 0
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.4)

                // 修正坐标：由于 parent 旋转了，鼠标坐标需要映射
                // 这里使用简单的中心扩散，效果最稳
                anchors.centerIn: parent

                ParallelAnimation {
                    id: rippleAnim
                    NumberAnimation { target: ripple; property: "width"; from: 0; to: ripple.maxSide; duration: 500; easing.type: Easing.OutQuart }
                    NumberAnimation { target: ripple; property: "height"; from: 0; to: ripple.maxSide; duration: 500; easing.type: Easing.OutQuart }
                    SequentialAnimation {
                        NumberAnimation { target: ripple; property: "opacity"; from: 1; to: 0.5; duration: 200 }
                        NumberAnimation { target: ripple; property: "opacity"; from: 0.5; to: 0; duration: 300 }
                    }
                }
            }
        }

        // 捕捉点击触发波纹
        MouseArea {
            anchors.fill: parent
            onPressed: {
                rippleAnim.restart()
                mouse.accepted = false // 继续传递点击事件给 Button
            }
        }
    }
}
