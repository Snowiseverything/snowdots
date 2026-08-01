import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components

Item {
    id: root

    implicitWidth: layout.implicitWidth > 600 ? layout.implicitWidth : 640
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    property string currentHex: "da470b"
    property string restoreHex: "da470b"
    property int currentBrightness: 50
    property var recentColors: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]

    function firePost(endpoint, body) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:5070" + endpoint);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(body ? JSON.stringify(body) : "{}");
    }

    function refreshState() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://localhost:5070/status");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText);
                    if (d && d.openrgb) {
                        var c = d.openrgb.color;
                        if (c && c !== "000000") {
                            root.currentHex = c;
                            root.restoreHex = c;
                        }
                        root.currentBrightness = d.openrgb.brightness;
                    }
                } catch(e) {}
            }
        };
        xhr.send();
        var r2 = new XMLHttpRequest();
        r2.open("GET", "http://localhost:5070/recent");
        r2.onreadystatechange = function() {
            if (r2.readyState === 4 && r2.status === 200) {
                try { var c = JSON.parse(r2.responseText); if (c && c.length > 0) root.recentColors = c; } catch(e) {}
            }
        };
        r2.send();
    }

    function setAll(hex) {
        root.currentHex = hex;
        firePost("/all", {color: hex, brightness: root.currentBrightness, fade: true});
    }

    function syncWallpaper() {
        firePost("/sync", null);
    }

    Timer { id: refreshTimer; interval: 4000; onTriggered: root.refreshState() }
    Timer { id: briDebounce; interval: 300; onTriggered: root.setAll(root.currentHex) }
    Component.onCompleted: root.refreshState()

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.small

            Column {
                spacing: Tokens.spacing.extraSmall
                Text { text: qsTr("RGB Control"); font.pixelSize: 28; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#e0e0e0" }
                Text { text: qsTr("Manage all RGB devices"); font.pixelSize: 14; font.family: "Noto Sans"; color: "#888" }
            }
            Item { Layout.fillWidth: true }
            Rectangle { implicitWidth: 60; implicitHeight: 60; radius: 30; color: "#" + root.currentHex; border.width: 2; border.color: "#444" }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: colorCol.implicitHeight + 24
            radius: 24; color: "#1e1e2e"

            ColumnLayout {
                id: colorCol
                anchors.centerIn: parent; spacing: 12

                Text { Layout.alignment: Qt.AlignHCenter; text: qsTr("Recent Colors"); font.pixelSize: 16; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#e0e0e0" }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 8

                    Repeater {
                        model: root.recentColors
                        Rectangle {
                            required property string modelData
                            property bool isActive: root.currentHex === modelData.replace("#","").toLowerCase()

                            implicitWidth: 48; implicitHeight: 48; radius: 24
                            color: Qt.color(modelData)
                            border.width: isActive ? 3 : 1
                            border.color: isActive ? "#7aa2f7" : "#444"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setAll(modelData.replace("#",""))
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 12

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: briCol.implicitHeight + 24; radius: 16; color: "#1e1e2e"

                ColumnLayout {
                    id: briCol
                    anchors.centerIn: parent; spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "☀"; font.pixelSize: 20; color: "#7aa2f7" }
                        Text { text: qsTr("Brightness"); font.pixelSize: 14; font.family: "Noto Sans"; color: "#e0e0e0" }
                        Item { Layout.fillWidth: true }
                        Text { text: root.currentBrightness + "%"; font.pixelSize: 14; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#7aa2f7" }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 100; value: root.currentBrightness; stepSize: 5
                        onMoved: { root.currentBrightness = value; briDebounce.restart(); }
                    }
                }
            }

            ColumnLayout { spacing: 8
                Rectangle { implicitWidth: 120; implicitHeight: 48; radius: 12; color: "#263040"
                    Row { anchors.centerIn: parent; spacing: 6
                        Text { text: "🖼"; font.pixelSize: 16; color: "#7aa2f7"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: qsTr("Sync"); font.pixelSize: 14; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#7aa2f7"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.syncWallpaper(); refreshTimer.restart(); } }
                }

                Rectangle { implicitWidth: 120; implicitHeight: 48; radius: 12; color: "#2e1a1a"
                    Row { anchors.centerIn: parent; spacing: 6
                        Text { text: "⏻"; font.pixelSize: 16; color: "#f7768e"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: qsTr("All Off"); font.pixelSize: 14; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#f7768e"; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.allOff() }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.bottomMargin: 16
            implicitHeight: wpCol.implicitHeight + 24; radius: 16; color: "#1e1e2e"

            ColumnLayout {
                id: wpCol
                anchors.centerIn: parent; spacing: 8
                Text { Layout.alignment: Qt.AlignHCenter; text: qsTr("Current Wallpaper"); font.pixelSize: 16; font.weight: Font.DemiBold; font.family: "Noto Sans"; color: "#e0e0e0" }
                Image { Layout.alignment: Qt.AlignHCenter; source: "file:///home/snow/.cache/skwd-wall/current-wallpaper"; fillMode: Image.PreserveAspectCrop; sourceSize.width: 260; sourceSize.height: 100; visible: status === Image.Ready
                    Rectangle { anchors.fill: parent; radius: 12; color: "transparent"; border.width: 1; border.color: "#444" }
                }
            }
        }
    }
}
