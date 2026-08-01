import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    implicitWidth: 760
    implicitHeight: layout.implicitHeight

    // ── state ──────────────────────────────────────────────────────────────
    property string currentHex: "da470b"
    property string restoreHex: "da470b"
    property int pcBrightness: 50
    property int kbBrightness: 50
    property int goveeBrightness: 50
    property var recentColors: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]

    function firePost(endpoint, body) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:5070" + endpoint);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(body ? JSON.stringify(body) : "{}");
    }

    function fireGet(endpoint, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://localhost:5070" + endpoint);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try { cb(JSON.parse(xhr.responseText)); } catch(e) {}
            }
        };
        xhr.send();
    }

    function refreshState() {
        fireGet("/status", function(d) {
            if (d && d.openrgb) {
                var c = d.openrgb.color;
                // Never clobber currentHex with black (off state) — keep the
                // last real color so brightness-up after All Off restores it.
                if (c && c !== "000000") {
                    root.currentHex = c;
                    root.restoreHex = c;
                }
                root.pcBrightness = d.openrgb.brightness;
            }
            if (d && d.keyboard) root.kbBrightness = d.keyboard.brightness;
            if (d && d.govee) root.goveeBrightness = d.govee.brightness;
        });
        fireGet("/recent", function(c) { if (c && c.length > 0) root.recentColors = c; });
    }

    // Pick a color — applies to every device, each keeps its own brightness.
    function setColor(hex) {
        root.currentHex = hex;
        firePost("/all", {
            color: hex,
            brightness: root.pcBrightness,
            kb_bri: root.kbBrightness,
            govee_bri: root.goveeBrightness,
            fade: true
        });
    }

    function setPcBrightness(v) {
        root.pcBrightness = v;
        firePost("/openrgb", {color: v > 0 ? root.currentHex : "000000", brightness: v});
    }

    function setKbBrightness(v) {
        root.kbBrightness = v;
        firePost("/keyboard", {color: v > 0 ? root.currentHex : "000000", brightness: v});
    }

    function setGoveeBrightness(v) {
        root.goveeBrightness = v;
        firePost("/govee", {color: v > 0 ? root.currentHex : "000000", brightness: v});
    }

    // All Off — device colors preserved, only brightness 0. Raising any
    // per-device slider (or picking a color) relights that device.
    function allOff() {
        root.pcBrightness = 0;
        root.kbBrightness = 0;
        root.goveeBrightness = 0;
        firePost("/all", {color: "000000", brightness: 0});
    }

    function syncWallpaper() {
        firePost("/sync", null);
    }

    // ── timers ─────────────────────────────────────────────────────────────
    Timer { id: refreshTimer; interval: 4000; onTriggered: root.refreshState() }
    Timer { id: pcBriDebounce; interval: 250; onTriggered: root.setPcBrightness(root.pcBrightness) }
    Timer { id: kbBriDebounce; interval: 250; onTriggered: root.setKbBrightness(root.kbBrightness) }
    Timer { id: goveeBriDebounce; interval: 250; onTriggered: root.setGoveeBrightness(root.goveeBrightness) }
    Component.onCompleted: root.refreshState()

    // ── ui ─────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        // header
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.small

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: qsTr("RGB Control")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }
                StyledText {
                    text: qsTr("PC · Keyboard · Govee")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item { Layout.fillWidth: true }

            StyledRect {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56

                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainer
                border.width: 2
                border.color: Colours.palette.m3outlineVariant

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: height / 2
                    color: "#" + root.currentHex
                }
            }
        }

        // recent colors
        SectionContainer {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                SectionHeader {
                    title: qsTr("Recent Colors")
                    description: qsTr("Tap a color to apply it to all devices")
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.recentColors

                        StyledRect {
                            required property string modelData
                            property bool isActive: root.currentHex === modelData.replace("#","").toLowerCase()

                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44

                            radius: Tokens.rounding.full
                            color: Qt.color(modelData)
                            border.width: isActive ? 3 : 1
                            border.color: isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setColor(modelData.replace("#",""))
                            }
                        }
                    }
                }
            }
        }

        // per-device brightness
        SectionContainer {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                SectionHeader {
                    title: qsTr("Brightness per device")
                    description: qsTr("Each device keeps its own level — 0 turns that device off")
                }

                DeviceBriRow {
                    icon: "desktop_windows"
                    label: qsTr("PC")
                    value: root.pcBrightness
                    accent: Colours.palette.m3primary
                    onMoved: (v) => { root.pcBrightness = Math.round(v * 100); pcBriDebounce.restart(); }
                }

                DeviceBriRow {
                    icon: "light_mode"
                    label: qsTr("Govee")
                    value: root.goveeBrightness
                    accent: Colours.palette.m3tertiary
                    onMoved: (v) => { root.goveeBrightness = Math.round(v * 100); goveeBriDebounce.restart(); }
                }

                DeviceBriRow {
                    icon: "keyboard"
                    label: qsTr("Keyboard")
                    value: root.kbBrightness
                    accent: Colours.palette.m3secondary
                    onMoved: (v) => { root.kbBrightness = Math.round(v * 100); kbBriDebounce.restart(); }
                }
            }
        }

        // actions
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            TextButton {
                Layout.fillWidth: true
                text: qsTr("Sync with Wallpaper")
                type: TextButton.Filled
                onClicked: { root.syncWallpaper(); refreshTimer.restart(); }
            }

            TextButton {
                Layout.fillWidth: true
                text: qsTr("All Off")
                type: TextButton.Filled
                activeColour: Colours.palette.m3error
                inactiveColour: Colours.palette.m3errorContainer
                activeOnColour: Colours.palette.m3onError
                inactiveOnColour: Colours.palette.m3onErrorContainer
                onClicked: root.allOff()
            }
        }

        // wallpaper preview
        SectionContainer {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.padding.medium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                SectionHeader {
                    title: qsTr("Current Wallpaper")
                    description: qsTr("Color synced from your active wallpaper")
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110

                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Tokens.rounding.small
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file:///home/snow/.cache/skwd-wall/current-wallpaper"
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }
            }
        }
    }

    // ── local components ──────────────────────────────────────────────────
    component DeviceBriRow: RowLayout {
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
            Layout.preferredWidth: 90
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
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }
}
