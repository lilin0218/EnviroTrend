import QtQuick 2.11
import QtQuick.Controls 2.4
import QtCharts 2.2
import "../../common"
import "../../components"

Item {
    id: root

    // --- 接口属性：基础数据 ---
    property string title: "传感器数据"
    property color lineColor: "#00CCFF"
    property color aiLineColor: "#FF9900"
    property var dataBuffer: []
    property var predictList: []
    property double currentTime: core.baseTime

    // --- 接口属性：Y 轴范围限制 ---
    property double limitMinY: 0.0
    property double limitMaxY: 100.0
    property double viewMinY: 0.0
    property double viewMaxY: 100.0

    // --- 接口属性：X 轴时间控制 ---
    property double maxPastLimit: 24.0
    property double maxFutureLimit: 12.0
    property double viewPastHours: 1.0
    property double viewFutureHours: 1.0

    width: parent.width
    height: 350

    // 属性变化监听
    onPredictListChanged: updateSeries()
    onDataBufferChanged: updateSeries()
    onCurrentTimeChanged: updateSeries()
    onViewPastHoursChanged: updateSeries()
    onViewFutureHoursChanged: updateSeries()
    onViewMinYChanged: updateSeries()
    onViewMaxYChanged: updateSeries()

    Row {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 5

        // 1. 左侧：控制区（Y轴滑动条 + 预测按钮）
        Column {
            width: 60
            height: parent.height
            spacing: 15
            anchors.verticalCenter: parent.verticalCenter

            CustomRangeSlider {
                id: yRangeSlider
                implicitHeight: parent.height * 0.6
                orientation: Qt.Vertical
                labelPosition: "Left"
                from: root.limitMinY
                to: root.limitMaxY
                live: false
                first.onValueChanged: root.viewMinY = first.value
                second.onValueChanged: root.viewMaxY = second.value
                anchors.horizontalCenter: parent.horizontalCenter
            }

            CustomButton {
                id: predictBtn
                text: core.isAiBusy ? "计算中..." : "AI预测"
                enabled: !core.isAiBusy
                width: 50
                height: 30
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    core.runPrediction(); // 假设 Core 端暴露此接口启动 py 模型
                }
            }
        }

        // 2. 中间：图表主区域
        ChartView {
            id: chart
            width: parent.width - 140 // 留出左右两侧宽度
            height: parent.height
            antialiasing: true
            backgroundColor: "transparent"
            legend.visible: true
            legend.alignment: Qt.AlignBottom
            legend.labelColor: "white"
            title: root.title
            titleColor: "white"
            dropShadowEnabled: true

            DateTimeAxis {
                id: axisX
                tickCount: 5
                labelsColor: "#AAAAAA"
                gridLineColor: "#333333"
                format: "HH:mm:ss"
            }

            ValueAxis {
                id: axisY
                min: root.viewMinY
                max: root.viewMaxY
                labelsColor: "#AAAAAA"
                gridLineColor: "#333333"
                labelFormat: "%.1f"
                tickCount: 5
            }

            LineSeries {
                id: series
                name: "实际观测"
                axisX: axisX; axisY: axisY
                color: root.lineColor
                width: 2
                useOpenGL: true
                onHovered: handleHover(point, state, root.lineColor)
            }

            LineSeries {
                id: predictSeries
                name: "LSTM 预测"
                axisX: axisX; axisY: axisY
                color: root.aiLineColor
                width: 2
                useOpenGL: true
                onHovered: handleHover(point, state, root.aiLineColor)
            }

            Rectangle {
                id: tooltip
                width: 100; height: 40; color: "#CC000000"; border.color: "white"; radius: 4; visible: false; z: 100
                Column {
                    anchors.centerIn: parent
                    Text { id: tooltipTime; color: "white"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { id: tooltipVal; color: "cyan"; font.bold: true; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }

        // 3. 右侧：X 轴时间范围滑动条
        Column {
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                Text { text: "历史"; color: "grey"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                CustomSlider {
                    id: pastSlider
                    implicitHeight: root.height / 3
                    orientation: Qt.Vertical
                    labelPosition: "Left"
                    from: 0.1; to: root.maxPastLimit
                    value: root.viewPastHours
                    live: false
                    onValueChanged: root.viewPastHours = value
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                Text { text: "预测"; color: "grey"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                CustomSlider {
                    id: futureSlider
                    implicitHeight: root.height / 3
                    orientation: Qt.Vertical
                    labelPosition: "Left"
                    from: 0.1; to: root.maxFutureLimit
                    value: root.viewFutureHours
                    live: false
                    onValueChanged: root.viewFutureHours = value
                }
            }
        }
    }

    function updateSeries() {
        console.log("[QML DEBUG] Received Prediction Points:", dataBuffer.length);
        if (!series || !axisX || !axisY) return;

        var nowMs = Number(currentTime);
        if (isNaN(nowMs) || nowMs < 100000) return;

        var pastOffset = root.viewPastHours * 3600 * 1000;
        var futureOffset = root.viewFutureHours * 3600 * 1000;
        axisX.min = new Date(nowMs - pastOffset);
        axisX.max = new Date(nowMs + futureOffset);

        // 增加安全性检查
        var interval = 60000;
        try { interval = core.getMsPerPoint(); } catch(e) {}
        if (interval <= 0) {console.log("获取core的interval非法",interval); return};

        // 1. 绘制历史观测
        series.clear();
        if (dataBuffer && dataBuffer.length > 0) {
            var pointsToDraw = Math.ceil(pastOffset / interval);
            var startIndex = Math.max(0, dataBuffer.length - pointsToDraw);
            for (var i = startIndex; i < dataBuffer.length; i++) {
                var pTime = nowMs - (dataBuffer.length - 1 - i) * interval;
                if (pTime >= axisX.min.getTime()) series.append(pTime, dataBuffer[i]);
            }
        }

        // 2. 预测线绘制
        predictSeries.clear();
        var pList = root.predictList;
        if (pList && pList.length > 0) {
            // --- 优化：为了线段连贯，将历史观测的最后一个点作为预测起点 ---
            if (series.count > 0) {
                var lastRealPoint = series.at(series.count - 1);
                predictSeries.append(lastRealPoint.x, lastRealPoint.y);
            }

            for (var j = 0; j < pList.length; j++) {
                var pAiTime = nowMs + (j * interval);
                var val = parseFloat(pList[j]);

                // --- 核心过滤逻辑 ---
                // 1. 必须是有效数字
                // 2. 必须在当前 X 轴视野内 (min ~ max)
                // 3. 必须在当前时间点之后 (pAiTime > nowMs)
                if (!isNaN(val) &&
                    pAiTime > nowMs &&
                    pAiTime <= axisX.max.getTime() &&
                    pAiTime >= axisX.min.getTime()) {

                    predictSeries.append(pAiTime, val);
                }
            }
        }
        // 最终调试日志
        console.log("[" + title + "] 刷新结果 -> 预测点数:", predictSeries.count,
                    "第一个点时间:", new Date(nowMs).toLocaleTimeString());
    }

    function handleHover(point, state, clr) {
        if (state) {
            var p = chart.mapToPosition(point, series);
            tooltip.x = p.x + 10; tooltip.y = p.y - 45;
            var date = new Date(point.x);
            var hh = date.getHours();
            var mm = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes();
            var ss = date.getSeconds() < 10 ? "0" + date.getSeconds() : date.getSeconds();
            tooltipTime.text = hh + ":" + mm + ":" + ss;
            tooltipVal.text = point.y.toFixed(2);
            tooltipVal.color = clr;
            tooltip.visible = true;
        } else {
            tooltip.visible = false;
        }
    }

    Component.onCompleted: {
        var range = root.limitMaxY - root.limitMinY;
        yRangeSlider.first.value = root.limitMinY + (range / 4.0);
        yRangeSlider.second.value = root.limitMaxY - (range / 4.0);
        updateSeries();
    }
}
