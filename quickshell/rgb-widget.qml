import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Window {
    id: root

    visible: true
    title: "RGB Control"
    flags: Qt.WindowStaysOnTopHint | Qt.Dialog
    width: 300
    height: col.implicitHeight + 40
    color: "#1a1a2e"
    x: Screen.width - width - 20
    y: 60

    property color currentColor: "#da470b"
    property int currentBrightness: 50

    function refreshState() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "http://localhost:5070/status");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                root.currentColor = Qt.color("#" + data.openrgb.color);
                root.currentBrightness = data.openrgb.brightness;
            }
        };
        xhr.send();
    }

    function setColor(hex) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:5070/all");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify({color: hex, brightness: root.currentBrightness}));
    }

    function syncWallpaper() {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", "http://localhost:5070/sync");
        xhr.send("{}");
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "RGB Control"
            font.pixelSize: 16
            font.bold: true
            color: "white"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]
                Rectangle {
                    implicitWidth: 36; implicitHeight: 36; radius: 18
                    color: modelData
                    border.width: 2; border.color: "#888"
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.setColor(modelData.replace("#",""))
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Brightness"; color: "#aaa"; font.pixelSize: 12 }
            Item { Layout.fillWidth: true }
            Text { text: root.currentBrightness + "%"; color: "#aaa"; font.pixelSize: 12 }
        }

        Slider {
            Layout.fillWidth: true
            from: 0; to: 100; value: root.currentBrightness; stepSize: 5
            onMoved: root.currentBrightness = value
        }

        RowLayout {
            Layout.fillWidth: true
            Button { text: "Apply"; onClicked: root.setColor("#" + currentColor.toString().slice(1)) }
            Button { text: "Sync"; onClicked: root.syncWallpaper() }
            Item { Layout.fillWidth: true }
            Button { text: "Close"; onClicked: Qt.quit() }
        }
    }

    Component.onCompleted: refreshState()
}
