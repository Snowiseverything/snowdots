pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

PanelWindow {
    id: root

    visible: false

    property color currentColor: "#da470b"
    property int pcBrightness: 50
    property int kbBrightness: 50
    property int goveeBrightness: 50
    property bool syncMode: true

    function toggle(): void {
        root.visible = !root.visible;
        if (root.visible) refreshState();
    }

    function refreshState(): void {
        XhrFetch.get("http://localhost:5070/status", function(status) {
            if (status) {
                var data = JSON.parse(status);
                if (data.openrgb) {
                    var color = data.openrgb.color;
                    if (color && color !== "000000") {
                        root.currentColor = Qt.color("#" + color);
                    }
                    root.pcBrightness = data.openrgb.brightness;
                }
                if (data.keyboard) root.kbBrightness = data.keyboard.brightness;
                if (data.govee) root.goveeBrightness = data.govee.brightness;
            }
        });
    }

    // Color preset — every device, each keeps its own brightness.
    function setColor(hex: string): void {
        root.currentColor = Qt.color("#" + hex);
        XhrFetch.post("http://localhost:5070/all", JSON.stringify({
            color: hex,
            brightness: root.pcBrightness,
            kb_bri: root.kbBrightness,
            govee_bri: root.goveeBrightness,
            fade: true
        }));
    }

    function setPcBrightness(v: int): void {
        root.pcBrightness = v;
        XhrFetch.post("http://localhost:5070/openrgb", JSON.stringify({
            color: v > 0 ? Qt.colorToHex(root.currentColor).replace("#", "") : "000000",
            brightness: v
        }));
    }

    function setKbBrightness(v: int): void {
        root.kbBrightness = v;
        XhrFetch.post("http://localhost:5070/keyboard", JSON.stringify({
            color: v > 0 ? Qt.colorToHex(root.currentColor).replace("#", "") : "000000",
            brightness: v
        }));
    }

    function setGoveeBrightness(v: int): void {
        root.goveeBrightness = v;
        XhrFetch.post("http://localhost:5070/govee", JSON.stringify({
            color: v > 0 ? Qt.colorToHex(root.currentColor).replace("#", "") : "000000",
            brightness: v
        }));
    }

    function allOff(): void {
        root.pcBrightness = 0;
        root.kbBrightness = 0;
        root.goveeBrightness = 0;
        XhrFetch.post("http://localhost:5070/all", JSON.stringify({
            color: "000000",
            brightness: 0
        }));
    }

    function syncWallpaper(): void {
        XhrFetch.post("http://localhost:5070/sync", "{}");
    }

    implicitWidth: 360
    implicitHeight: content.implicitHeight + Tokens.padding.large * 2

    color: "transparent"

    Connections {
        target: root
        function onVisibilityChanged(): void {
            if (root.visible) refreshState();
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // ── header ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Column {
                spacing: Tokens.spacing.extraSmall
                StyledText {
                    text: "RGB Control"
                    font: Tokens.font.body.builders.large.size(20).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }
                StyledText {
                    text: "PC · Keyboard · Govee"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
            Item { Layout.fillWidth: true }
            StyledRect {
                width: 28; height: 28
                radius: Tokens.rounding.full
                color: root.currentColor
                border.width: 2
                border.color: Colours.palette.m3outlineVariant
            }
        }

        // ── color presets ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]

                StyledRect {
                    required property string modelData

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: Tokens.rounding.full
                    color: Qt.color(modelData)
                    border.width: root.currentColor === modelData ? 3 : 1
                    border.color: root.currentColor === modelData ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setColor(modelData.replace("#", ""))
                    }
                }
            }
        }

        // ── per-device brightness ──────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: "Brightness per device"
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3onSurfaceVariant
            }

            BriRow { icon: "desktop_windows"; label: "PC"; value: root.pcBrightness; accent: Colours.palette.m3primary; onMoved: { root.pcBrightness = value; pcDebounce.restart(); } }
            BriRow { icon: "keyboard"; label: "Keyboard"; value: root.kbBrightness; accent: Colours.palette.m3secondary; onMoved: { root.kbBrightness = value; kbDebounce.restart(); } }
            BriRow { icon: "light_mode"; label: "Govee"; value: root.goveeBrightness; accent: Colours.palette.m3tertiary; onMoved: { root.goveeBrightness = value; goveeDebounce.restart(); } }
        }

        // ── actions ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            TextButton {
                Layout.fillWidth: true
                text: "🖼 Sync"
                type: TextButton.Filled
                onClicked: root.syncWallpaper()
            }

            TextButton {
                Layout.fillWidth: true
                text: "⏻ All Off"
                type: TextButton.Filled
                activeColour: Colours.palette.m3error
                inactiveColour: Colours.palette.m3errorContainer
                activeOnColour: Colours.palette.m3onError
                inactiveOnColour: Colours.palette.m3onErrorContainer
                onClicked: root.allOff()
            }
        }

        // ── sync toggle ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Sync with Wallpaper"
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurfaceVariant
            }
            Item { Layout.fillWidth: true }

            StyledSwitch {
                checked: root.syncMode
                onToggled: {
                    root.syncMode = checked;
                    if (checked) root.syncWallpaper();
                }
            }
        }
    }

    // ── debounce timers (outside content ColumnLayout) ─────────────────────
    Timer { id: pcDebounce; interval: 250; onTriggered: root.setPcBrightness(root.pcBrightness) }
    Timer { id: kbDebounce; interval: 250; onTriggered: root.setKbBrightness(root.kbBrightness) }
    Timer { id: goveeDebounce; interval: 250; onTriggered: root.setGoveeBrightness(root.goveeBrightness) }

    // ── local component ────────────────────────────────────────────────────
    component BriRow: RowLayout {
        id: briRow

        required property string icon
        required property string label
        required property int value
        required property color accent
        signal moved(real v)

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: briRow.icon
            fontStyle: Tokens.font.icon.medium
            color: briRow.accent
        }

        StyledText {
            text: briRow.label
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurface
            Layout.preferredWidth: 86
        }

        StyledSlider {
            Layout.fillWidth: true
            from: 0; to: 100; stepSize: 5
            value: briRow.value
            fgColour: briRow.accent
            onInteraction: v => briRow.moved(v)
        }

        StyledText {
            text: briRow.value + "%"
            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            color: briRow.accent
            Layout.preferredWidth: 34
            horizontalAlignment: Text.AlignRight
        }
    }
}
