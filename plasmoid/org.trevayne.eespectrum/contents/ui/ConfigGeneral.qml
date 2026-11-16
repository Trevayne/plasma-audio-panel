import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    property alias cfg_barCount: countSpin.value
    property alias cfg_barWidth: widthSpin.value
    property alias cfg_barGap: gapSpin.value
    property alias cfg_colorLow: lowButton.color
    property alias cfg_colorHigh: highButton.color
    property alias cfg_feedPort: portSpin.value
    property alias cfg_clickCommand: commandField.text

    Kirigami.FormLayout {
        QQC2.SpinBox { id: countSpin; Kirigami.FormData.label: i18n("Number of bars:"); from: 4; to: 96 }
        QQC2.SpinBox { id: widthSpin; Kirigami.FormData.label: i18n("Bar width (px):"); from: 1; to: 12 }
        QQC2.SpinBox { id: gapSpin; Kirigami.FormData.label: i18n("Gap (px):"); from: 0; to: 8 }

        Item { Kirigami.FormData.isSection: true }

        KQuickControls.ColorButton { id: lowButton; Kirigami.FormData.label: i18n("Bass colour:"); showAlphaChannel: false }
        KQuickControls.ColorButton { id: highButton; Kirigami.FormData.label: i18n("Treble colour:"); showAlphaChannel: false }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox { id: portSpin; Kirigami.FormData.label: i18n("Feed port:"); from: 1024; to: 65535; editable: true }
        QQC2.TextField {
            id: commandField
            Kirigami.FormData.label: i18n("On click, run:")
            Layout.minimumWidth: Kirigami.Units.gridUnit * 20
            placeholderText: i18n("e.g. flatpak run com.github.wwmm.easyeffects")
        }
        QQC2.Label {
            text: i18n("The feed port must match EE_SPECTRUM_PORT for the ee-spectrum helper service.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        }
    }
}
