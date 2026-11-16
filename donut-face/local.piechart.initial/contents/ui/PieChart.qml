/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.9
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.8 as Kirigami

import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces

import org.kde.quickcharts 1.0 as Charts
import org.kde.quickcharts.controls 1.0 as ChartControls


ChartControls.PieChartControl {
    id: chart

    property alias headingSensor: sensor.sensorId
    property alias sensors: sensorsModel.sensors
    property alias sensorsModel: sensorsModel

    property int updateRateLimit

    Layout.minimumHeight: root.formFactor == Faces.SensorFace.Vertical ? width : Kirigami.Units.gridUnit

    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    readonly property real rangeFrom: root.controller.faceConfiguration.rangeFrom *
                                      root.controller.faceConfiguration.rangeFromMultiplier

    readonly property real rangeTo: root.controller.faceConfiguration.rangeTo *
                                    root.controller.faceConfiguration.rangeToMultiplier

    chart.smoothEnds: root.controller.faceConfiguration.smoothEnds
    chart.fromAngle: root.controller.faceConfiguration.fromAngle
    chart.toAngle: root.controller.faceConfiguration.toAngle

    // Donut with Initial (local change): a network rate has no natural maximum,
    // and an automatic range would show a full ring all the time. So for
    // network sensors a full ring is the busiest moment of the last few
    // minutes: the peak (download + upload) is held and relaxes by 1% every
    // 2 s (half-life ~2 min), and never drops below 256 KB/s so that idle
    // background traffic stays a sliver.
    readonly property bool networkSensor: root.controller.highPrioritySensorIds.length > 0
        && root.controller.highPrioritySensorIds[0].indexOf("network/") === 0
    readonly property real networkFloor: 262144
    property real networkPeak: networkFloor

    Sensors.Sensor {
        id: net0
        sensorId: chart.networkSensor ? root.controller.highPrioritySensorIds[0] : ""
        updateRateLimit: chart.updateRateLimit
    }
    Sensors.Sensor {
        id: net1
        sensorId: chart.networkSensor && root.controller.highPrioritySensorIds.length > 1
            ? root.controller.highPrioritySensorIds[1] : ""
        updateRateLimit: chart.updateRateLimit
    }
    Timer {
        interval: 2000
        repeat: true
        running: chart.networkSensor
        onTriggered: {
            var now = (Number(net0.value) || 0) + (Number(net1.value) || 0)
            chart.networkPeak = Math.max(chart.networkFloor, now, chart.networkPeak * 0.99)
        }
    }

    range {
        from: chart.networkSensor ? 0 : chart.rangeFrom
        to: chart.networkSensor ? chart.networkPeak * 1.1 : chart.rangeTo
        automatic: chart.networkSensor ? false : root.controller.faceConfiguration.rangeAuto
    }

    chart.backgroundColor: "#2A2A2A" // visible track on the black panel (the chart ignores alpha)

    valueSources: Charts.ModelSource {
        model: Sensors.SensorDataModel {
            id: sensorsModel
            sensors: root.controller.highPrioritySensorIds
            updateRateLimit: chart.updateRateLimit
            sensorLabels: root.controller.sensorLabels
        }
        roleName: "Value"
        indexColumns: true
    }
    chart.nameSource: Charts.ModelSource {
        roleName: "Name";
        model: valueSources[0].model;
        indexColumns: true
    }
    chart.shortNameSource: Charts.ModelSource {
        roleName: "ShortName";
        model: valueSources[0].model;
        indexColumns: true
    }
    chart.colorSource: root.colorSource

    Sensors.Sensor {
        id: sensor
        sensorId: root.controller.totalSensors.length > 0 ? root.controller.totalSensors[0] : ""
        updateRateLimit: chart.updateRateLimit
    }

    UsedTotalDisplay {
        anchors.fill: parent

        usedSensor: root.controller.totalSensors.length > 0 ? root.controller.totalSensors[0] : ""
        totalSensor: root.controller.totalSensors.length > 1 ? root.controller.totalSensors[1] : ""

        contentMargin: chart.chart.thickness
        updateRateLimit: chart.updateRateLimit
    }
}

