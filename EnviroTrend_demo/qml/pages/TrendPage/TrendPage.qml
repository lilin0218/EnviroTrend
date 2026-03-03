import QtQuick 2.11
import QtQuick.Layouts 1.0
import "../../common"
// 注意：由于 TrendChart 和 SideAnchorBar 在同级目录下，直接引用即可

Rectangle {
    id: root
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 1. 左侧：导航锚点栏
        SideAnchorBar {
            id: sideBar
            Layout.fillHeight: true
            Layout.preferredWidth: 90

            // 联动逻辑：点击左侧，右侧滚动
            onItemSelected: {
                scrollToSection(index)
            }
        }

        // 2. 右侧：可滚动的图表展示区
        Flickable {
            id: chartFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: chartColumn.height
            clip: true

            // 平滑滚动动画
            Behavior on contentY {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutQuint
                }
            }

            Column {
                id: chartColumn
                width: parent.width
                spacing: 20
                topPadding: 20
                bottomPadding: 100

                // 1. 温度图表
                TrendChart {
                    id: tempChart
                    title: "温度趋势 (°C)"
                    // Y 轴绝对边界
                    limitMinY: -10.0
                    limitMaxY: 50.0
                    // X 轴滑动条上限
                    maxPastLimit: 24.0
                    maxFutureLimit: 12.0
                    // 初始显示范围
                    viewPastHours: 1.0
                    viewFutureHours: 1.0
                    dataBuffer: core.tempBuffer
                    predictList: core.predictedTempList
                }

                // 2. 湿度图表
                TrendChart {
                    id: humChart
                    title: "湿度趋势 (%)"
                    limitMinY: 0.0
                    limitMaxY: 100.0
                    maxPastLimit: 24.0
                    maxFutureLimit: 12.0
                    viewPastHours: 1.0
                    viewFutureHours: 1.0
                    dataBuffer: core.humBuffer
                    predictList: core.predictedHumList
                }

                // 3. 光照图表 (Lux 通常范围较大)
                TrendChart {
                    id: lightChart
                    title: "光照强度 (Lux)"
                    lineColor: "#FFD700"
                    limitMinY: 0.0
                    limitMaxY: 1000.0
                    maxPastLimit: 24.0
                    maxFutureLimit: 1.0   // 无预测时建议缩小右侧限制
                    viewPastHours: 1.0
                    viewFutureHours: 0.1  // 初始不显示预测空间
                    dataBuffer: core.humBuffer
                }

                // 4. 噪音图表 (dB 范围 30-120)
                TrendChart {
                    id: noiseChart
                    title: "噪音水平 (dB)"
                    lineColor: "#4CAF50"
                    limitMinY: 30.0
                    limitMaxY: 120.0
                    maxPastLimit: 24.0
                    maxFutureLimit: 1.0
                    viewPastHours: 1.0
                    viewFutureHours: 0.1
                    dataBuffer: core.humBuffer
                }

                // 5. 颗粒物图表 (ug/m³)
                TrendChart {
                    id: pmChart
                    title: "颗粒物浓度 (ug/m³)"
                    lineColor: "#9C27B0"
                    limitMinY: 0.0
                    limitMaxY: 300.0
                    maxPastLimit: 24.0
                    maxFutureLimit: 1.0
                    viewPastHours: 1.0
                    viewFutureHours: 0.1
                    dataBuffer: core.humBuffer
                }

                // 6. AQI图表
                TrendChart {
                    id: aqiChart
                    title: "空气质量指数 (AQI)"
                    lineColor: "#E91E63"
                    limitMinY: 0.0
                    limitMaxY: 500.0
                    maxPastLimit: 24.0
                    maxFutureLimit: 1.0
                    viewPastHours: 1.0
                    viewFutureHours: 0.1
                    dataBuffer: core.humBuffer
                }
            }

            // 联动逻辑：手动滑动右侧时，自动更新左侧的高亮状态
            onMovementEnded: {
                updateSideBarIndex()
            }
        }
    }

    // --- 逻辑函数 ---

    // 滚动到指定索引的图表
    function scrollToSection(index) {
        if (index < chartColumn.children.length) {
            let targetItem = chartColumn.children[index];
            chartFlickable.contentY = targetItem.y;
        }
    }

    // 自动检测当前视口在哪个图表，同步左侧高亮
    function updateSideBarIndex() {
        let currentY = chartFlickable.contentY + 50; // 偏移量，提高识别灵敏度
        for (var i = 0; i < chartColumn.children.length; i++) {
            let item = chartColumn.children[i];
            if (currentY >= item.y && currentY < (item.y + item.height + chartColumn.spacing)) {
                sideBar.currentIndex = i;
                break;
            }
        }
    }
}
