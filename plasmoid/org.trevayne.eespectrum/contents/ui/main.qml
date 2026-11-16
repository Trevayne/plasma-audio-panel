import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Tunables
    // Settings (right-click > Configure...)
    readonly property int barCount: Plasmoid.configuration.barCount
    readonly property int barWidth: Plasmoid.configuration.barWidth
    readonly property int barGap: Plasmoid.configuration.barGap
    // colour ramp across frequency: bass colour -> treble colour
    readonly property color barColor: Plasmoid.configuration.colorLow
    readonly property color barColorHigh: Plasmoid.configuration.colorHigh

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, 1);
    }
    readonly property string feedUrl: "http://127.0.0.1:" + Plasmoid.configuration.feedPort + "/bands?n=" + barCount

    property var bands: []
    property bool idle: true
    property bool online: false
    property bool busy: false

    // Plasma 6: let the shell pick (compact in a panel); also provide a full view so it never has nothing to show
    fullRepresentation: Item { }
    toolTipMainText: "EasyEffects Spectrum"
    toolTipSubText: online ? i18n("Click to open the audio app")
                           : i18n("Spectrum feed is not running. Click to start it (systemctl --user start ee-spectrum).")

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    Timer {
        // fast while audio plays, slow when silent/offline
        interval: (online && !idle) ? 33 : 250
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    property double startedAt: 0
    function poll() {
        // watchdog: a request that never completes must not wedge polling forever
        if (busy && Date.now() - startedAt < 1500) return;
        busy = true;
        startedAt = Date.now();
        var xhr = new XMLHttpRequest();
        xhr.timeout = 1000;
        xhr.ontimeout = function () { busy = false; root.online = false; root.bands = []; };
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            busy = false;
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText);
                    root.bands = d.bands;
                    root.idle = d.idle;
                    root.online = true;
                    return;
                } catch (e) {}
            }
            root.online = false;
            root.bands = [];
        };
        xhr.open("GET", feedUrl);
        xhr.send();
    }

    compactRepresentation: MouseArea {
        id: compact
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        Layout.minimumWidth: vertical ? -1 : root.barCount * (root.barWidth + root.barGap) + 4
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: vertical ? Kirigami.Units.iconSizes.medium : -1
        hoverEnabled: true
        onClicked: exec.connectSource(root.online
                                      ? Plasmoid.configuration.clickCommand
                                      : "systemctl --user start ee-spectrum.service")

        Row {
            id: bars
            anchors.centerIn: parent
            height: Math.round(parent.height * 0.7)
            spacing: root.barGap
            Repeater {
                model: root.barCount
                Item {
                    width: compact.vertical
                        ? Math.max(1, (compact.width - 4) / root.barCount - root.barGap)
                        : root.barWidth
                    height: bars.height
                    Rectangle {
                        id: bar
                        readonly property real level: root.bands.length > index ? root.bands[index] : 0
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(1, level * parent.height)
                        readonly property color base: root.mix(root.barColor, root.barColorHigh,
                                                               index / Math.max(1, root.barCount - 1))
                        radius: 1
                        opacity: root.online ? (0.55 + 0.45 * level) : 0.25
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(bar.base, 1.25) }
                            GradientStop { position: 1.0; color: bar.base }
                        }
                    }
                }
            }
        }
    }
}
