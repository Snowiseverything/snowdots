pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

PanelWindow {
    id: root

    visible: false

    property color currentColor: "#da470b"
    property int brightness: 50
    property bool syncMode: true

    function toggle(): void {
        root.visible = !root.visible;
        if (root.visible) {
            refreshState();
        }
    }

    function refreshState(): void {
        XhrFetch.get("http://localhost:5070/status", function(status) {
            if (status) {
                var data = JSON.parse(status);
                var color = data.openrgb.color;
                root.currentColor = Qt.color("#" + color);
                root.brightness = data.openrgb.brightness;
            }
        });
    }

    function setColor(hex: string, bri: int): void {
        XhrFetch.post("http://localhost:5070/all", JSON.stringify({
            color: hex,
            brightness: bri
        }));
    }

    function syncWallpaper(): void {
        XhrFetch.post("http://localhost:5070/sync", "{}");
    }

    implicitWidth: 320
    implicitHeight: content.implicitHeight + 40

    anchors {
        margins: 10
    }

    color: "transparent"

    Connections {
        target: root
        function onVisibilityChanged(): void {
            if (root.visible) refreshState();
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "RGB Control"
                font.family: "Noto Sans"
                font.pixelSize: 16
                font.bold: true
                color: Caelestia.Colors.onSurface
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: root.currentColor
                border.width: 2
                border.color: Caelestia.Colors.outline
            }
        }

        // Color Presets
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]

                Rectangle {
                    required property int index
                    required property string modelData

                    width: 36
                    height: 36
                    radius: 18
                    color: modelData
                    border.width: root.currentColor === modelData ? 3 : 1
                    border.color: root.currentColor === modelData ? Caelestia.Colors.primary : Caelestia.Colors.outline

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.currentColor = modelData;
                            root.setColor(modelData.replace("#", ""), root.brightness);
                        }
                    }
                }
            }
        }

        // Brightness Slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Text {
                    text: "Brightness"
                    font.family: "Noto Sans"
                    font.pixelSize: 12
                    color: Caelestia.Colors.onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.brightness + "%"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Caelestia.Colors.onSurfaceVariant
                }
            }

            Slider {
                id: brightnessSlider

                Layout.fillWidth: true
                from: 0
                to: 100
                value: root.brightness
                stepSize: 5

                onMoved: {
                    root.brightness = value;
                    root.setColor(Qt.colorToHex(root.currentColor).replace("#", ""), value);
                }

                background: Rectangle {
                    x: brightnessSlider.leftPadding
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 6
                    width: brightnessSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: Caelestia.Colors.surfaceContainer

                    Rectangle {
                        width: brightnessSlider.visualPosition * parent.width
                        height: parent.height
                        color: Caelestia.Colors.primary
                        radius: 3
                    }
                }

                handle: Rectangle {
                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: brightnessSlider.pressed ? Caelestia.Colors.primary : Caelestia.Colors.onPrimary
                    border.width: 2
                    border.color: Caelestia.Colors.primary
                }
            }
        }

        // Sync Toggle
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Sync with Wallpaper"
                font.family: "Noto Sans"
                font.pixelSize: 12
                color: Caelestia.Colors.onSurfaceVariant
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: root.syncMode ? Caelestia.Colors.primary : Caelestia.Colors.surfaceContainer

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.syncMode = !root.syncMode;
                        if (root.syncMode) root.syncWallpaper();
                    }
                }

                Rectangle {
                    x: root.syncMode ? parent.width - width - 2 : 2
                    y: 2
                    width: 20
                    height: 20
                    radius: 10
                    color: root.syncMode ? Caelestia.Colors.onPrimary : Caelestia.Colors.onSurfaceVariant

                    Behavior on x {
                        Anim {}
                    }
                }
            }
        }
    }
}
