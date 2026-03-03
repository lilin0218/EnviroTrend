import QtQuick 2.11
import QtQuick.Controls 2.4

Slider {
    id: control

    // 希望当前数值的标签出现在滑块的哪个方向
    property string labelPosition: "Top" // 可选值: "Top", "Bottom", "Left", "Right"

    // 基础尺寸设置
    implicitWidth: horizontal ? 200 : 40
    implicitHeight: horizontal ? 40 : 200

    // 背景槽设计
    background: Rectangle {
        id: bgRect
        implicitWidth: control.horizontal ? 200 : 4
        implicitHeight: control.horizontal ? 4 : 200
        width: control.horizontal ? control.availableWidth : implicitWidth
        height: control.horizontal ? implicitHeight : control.availableHeight
        x: control.leftPadding + (control.horizontal ? 0 : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : 0)
        color: "#bdbebf"

        // 1. 起点数值 (左/下)
        Text {
            text: control.from.toFixed(0)
            font.pixelSize: 10
            color: "#888"
            anchors.right: control.horizontal ? parent.left : undefined
            anchors.top: control.horizontal ? parent.bottom : parent.bottom
            anchors.rightMargin: control.horizontal ? 5 : 0
            anchors.horizontalCenter: control.horizontal ? undefined : parent.horizontalCenter
        }

        // 2. 终点数值 (右/上)
        Text {
            text: control.to.toFixed(0)
            font.pixelSize: 10
            color: "#888"
            anchors.left: control.horizontal ? parent.right : undefined
            anchors.bottom: control.horizontal ? parent.bottom : parent.top
            anchors.leftMargin: control.horizontal ? 5 : 0
            anchors.horizontalCenter: control.horizontal ? undefined : parent.horizontalCenter
        }

        // 3. 已填充进度条部分 (绿色部分 z+1)
        Rectangle {
            z: parent.z + 1
            width: control.horizontal ? control.position * parent.width : parent.width
            height: control.horizontal ? parent.height : control.position * parent.height

            // 修正：水平从左往右，垂直从下往上 (Slider默认垂直0在顶，这里做逻辑反转)
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            color: "#21be2b"
        }
    }

    // 滑块手柄设计
    handle: Rectangle {
        id: handleVisual
        x: control.horizontal ? control.leftPadding + control.visualPosition
                                * (control.availableWidth - width) : control.leftPadding
                                + (control.availableWidth - width) / 2
        y: control.horizontal ? control.topPadding + (control.availableHeight - height)
                                / 2 : control.topPadding + control.visualPosition
                                * (control.availableHeight - height)

        implicitWidth: 26
        implicitHeight: 26

        // 4. 视觉效果：悬空放大，按住变色
        color: control.pressed ? "grey" : (control.hovered ? "#ffffff" : "#f6f6f6")
        scale: control.pressed ? 0.9 : (control.hovered ? 1.15 : 1.0)
        border.color: control.hovered ? "#21be2b" : "#bdbebf"
        border.width: 3

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutBack
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Rectangle {
            color: "#333"
            visible: control.hovered || control.pressed
            z: 10 // 确保标签在最上层

            // 动态逻辑控制位置
            anchors.bottom: labelPosition === "Top" ? parent.top : undefined
            anchors.top: labelPosition === "Bottom" ? parent.bottom : undefined
            anchors.right: labelPosition === "Left" ? parent.left : undefined
            anchors.left: labelPosition === "Right" ? parent.right : undefined

            // 边距控制
            anchors.bottomMargin: labelPosition === "Top" ? 10 : 0
            anchors.topMargin: labelPosition === "Bottom" ? 10 : 0
            anchors.rightMargin: labelPosition === "Left" ? 10 : 0
            anchors.leftMargin: labelPosition === "Right" ? 10 : 0

            // 居中对齐逻辑
            // 如果是上下位置，则水平居中；如果是左右位置，则垂直居中
            anchors.horizontalCenter: (labelPosition === "Top" || labelPosition
                                       === "Bottom") ? parent.horizontalCenter : undefined
            anchors.verticalCenter: (labelPosition === "Left" || labelPosition
                                     === "Right") ? parent.verticalCenter : undefined

            Text {
                anchors.centerIn: parent
                text: control.value.toFixed(1) // 保持 double 精度习惯
                color: "white"
                font.pixelSize: 11
            }
        }
    }
}
