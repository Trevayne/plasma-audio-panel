/*
    SPDX-FileCopyrightText: 2019 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2019 David Edmundson <davidedmundson@kde.org>
    SPDX-FileCopyrightText: 2019 Arjen Hiemstra <ahiemstra@heimr.nl>
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.9
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Layouts 1.1

import org.kde.kirigami 2.8 as Kirigami

import org.kde.ksysguard.sensors 1.0 as Sensors
import org.kde.ksysguard.faces 1.0 as Faces

import org.kde.quickcharts 1.0 as Charts
import org.kde.quickcharts.controls 1.0 as ChartControls

Faces.SensorFace {
    id: root

    // Keep each donut exactly as wide as it is tall, so they sit close together.
    // Slot width = panel height + slotExtra: the ring is now as tall as the panel allows, so the
    // slot gets a little wider to keep the gap between neighbouring donuts about what it was.
    readonly property int slotExtra: 2
    Layout.minimumWidth: root.formFactor == Faces.SensorFace.Horizontal ? height + slotExtra : -1
    Layout.preferredWidth: root.formFactor == Faces.SensorFace.Horizontal ? height + slotExtra : -1
    Layout.maximumWidth: root.formFactor == Faces.SensorFace.Horizontal ? height + slotExtra : -1
    contentItem: ColumnLayout {
        PieChart {
            Layout.maximumHeight: Math.max(root.width, Layout.minimumHeight)
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            updateRateLimit: root.controller.updateRateLimit

            // Fill the panel height: the ring may touch the bottom edge, with 1 px clear above it.
            // A letter can only sit exactly in the middle if the space around it has the same
            // odd/even-ness as its ink, so give up one more pixel on the top/right when needed.
            id: pie
            readonly property int edgeGap: 1      // top
            readonly property int bottomGap: 0
            // ceil, not round: a glyph that measures 5.4 px wide still lights up 6 pixel columns
            readonly property int inkW: Math.ceil(inkMetrics.tightBoundingRect.width)
            readonly property int inkH: Math.round(inkMetrics.tightBoundingRect.height)
            readonly property int extraRight: (width - inkW) % 2 !== 0 ? 1 : 0
            readonly property int extraTop: (height - edgeGap - bottomGap - inkH) % 2 !== 0 ? 1 : 0
            readonly property real ringCentreX: (width - extraRight) / 2
            readonly property real ringCentreY: edgeGap + extraTop + (height - edgeGap - bottomGap - extraTop) / 2
            topPadding: edgeGap + extraTop
            leftPadding: 0
            bottomPadding: bottomGap
            rightPadding: extraRight

            // Donut with Initial: thin ring, the widget title drawn large in the centre.
            // Thin ring that scales with the panel: 4 px on a 23 px panel, never more than 10 px.
            readonly property int ringBoost: 2   // extra px on top of 15% of the panel height
            chart.thickness: Math.max(2, Math.min(10, Math.round(Math.min(width, height) * 0.15) + ringBoost))

            QQC2.Label {
                id: initial
                // Centre the letter's actual ink, not its text box: a text box leaves
                // room for descenders, which makes a capital letter sit too high.
                x: Math.round(pie.ringCentreX - (inkMetrics.tightBoundingRect.x + inkMetrics.tightBoundingRect.width / 2))
                y: Math.round(pie.ringCentreY - (baselineOffset + inkMetrics.tightBoundingRect.y + inkMetrics.tightBoundingRect.height / 2))
                text: root.controller.title
                // Noto Sans only goes up to Bold, which looks thin at this size, so use
                // the heaviest face installed.
                font.family: "Ubuntu Sans"
                font.weight: Font.ExtraBold
                readonly property real letterFactor: 0.35
                font.pixelSize: Math.max(7, Math.round(Math.min(parent.width, parent.height) * letterFactor))
                color: Kirigami.Theme.textColor
                TextMetrics {
                    id: inkMetrics
                    font: initial.font
                    text: initial.text
                }
            }
        }
        QQC2.Label {
            id: label
            visible: root.formFactor == Faces.SensorFace.Planar && root.controller.showTitle && text.length > 0
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.controller.title
        }
    }
}
