import QtQuick 2.11
import QtQuick.Window 2.11
import QtQuick.Layouts 1.3
import "qrc:/qml/common"
import "qrc:/qml/components"
import "./qml/pages/HelloPage"

Window {
    visible: true
    width: 800
    height: 480
    title: qsTr("EnviroTrend - Tesla Style")
    color: Theme.mainBg

    ColumnLayout {
        id: mainArea
        anchors.fill: parent
        spacing: 0
        visible: false

        TopStatusBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 45.0
        }

        MainContentStack {
            id: contentStack
            currentIndex: bottomNav.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        BottomNavigationBar {
            id: bottomNav
            Layout.fillWidth: true
            Layout.preferredHeight: 85.0
        }
    }

    // --- 开屏动画层 ---
    HelloPage {
        id: helloArea
        anchors.fill: parent
        z: 100 // 确保在最顶层

        // 增加退出动画
        Behavior on opacity {
            NumberAnimation { duration: 1000 }
        }
    }

    // --- 跳转控制定时器 ---
    Timer {
        id: loadTimer
        interval: 5000
        running: true
        repeat: false
        onTriggered: {
            helloArea.opacity = 0
            mainArea.visible = true
            // 彻底销毁开屏页以节省显存 (可选)
            destroyTimer.start()
        }
    }

    Timer {
        id: destroyTimer
        interval: 800
        onTriggered: {
            helloArea.destroy()
        }
    }
}
