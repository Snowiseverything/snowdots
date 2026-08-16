import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight

    // ── state ──────────────────────────────────────────────────────────────
    property string currentHex: "da470b"
    property string restoreHex: "da470b"
    property int pcBrightness: 50
    property int kbBrightness: 50
    property int goveeBrightness: 50
    property int masterBrightness: 100
    property var recentColors: ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]

    // color picker state
    property real pickerHue: 0.58
    property string pickerHex: "#da470b"
    property bool pickerOpen: true
    readonly property color pickerColor: Qt.color(pickerHex)
    readonly property color pickerHueColor: Qt.hsva(pickerHue, 1, 1, 1)

    // Convert hex -> hue (0..1) for the picker
    function hexToHue(hex) {
        var c = Qt.color("#" + hex)
        if (!c.valid) return 0.58
        var r = c.r, g = c.g, b = c.b
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var d = max - min
        if (d === 0) return 0.58
        var h
        if (max === r) h = ((g - b) / d) % 6
        else if (max === g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        h = h * 60
        if (h < 0) h += 360
        return h / 360
    }

    // Convert hex -> saturation/value (0..1) for the SV dot
    function hexToSV(hex) {
        var c = Qt.color("#" + hex)
        if (!c.valid) return {s: 1, v: 1}
        var max = Math.max(c.r, c.g, c.b)
        var min = Math.min(c.r, c.g, c.b)
        var d = max - min
        var s = max === 0 ? 0 : d / max
        return {s: s, v: max}
    }

    // Open the picker pre-seeded with the current color
    function openPicker() {
        root.pickerHex = "#" + root.currentHex
        root.pickerHue = root.hexToHue(root.currentHex)
        var sv = root.hexToSV(root.currentHex)
        svDot.sx = sv.s
        svDot.sy = 1 - sv.v
        root.pickerOpen = true
    }

    // Convert a QML color to hex string
    function colorToHex(c) {
        if (!c.valid) return "000000"
        var r = Math.round(c.r * 255).toString(16).padStart(2, "0")
        var g = Math.round(c.g * 255).toString(16).padStart(2, "0")
        var b = Math.round(c.b * 255).toString(16).padStart(2, "0")
        return (r + g + b).toLowerCase()
    }

    // Apply a hex (with or without #) to all devices
    function applyColor(hex) {
        var h = hex.replace("#", "")
        root.setColor(h)
        root.pickerHex = "#" + h
    }

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
                    root.pickerHex = "#" + c;
                    root.pickerHue = root.hexToHue(c);
                    var sv = root.hexToSV(c);
                    svDot.sx = sv.s;
                    svDot.sy = 1 - sv.v;
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

    function setMasterBrightness(v) {
        root.masterBrightness = v;
        root.pcBrightness = v;
        root.kbBrightness = v;
        root.goveeBrightness = v;
        firePost("/all", {color: v > 0 ? root.currentHex : "000000", brightness: v, kb_bri: v, govee_bri: v});
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
    Timer { id: masterBriDebounce; interval: 250; onTriggered: root.setMasterBrightness(root.masterBrightness) }
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

            // hex value display
            StyledText {
                text: "#" + root.currentHex.toUpperCase()
                font: Tokens.font.body.builders.small.size(13).weight(Font.DemiBold).family("JetBrains Mono, monospace").build()
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // color picker
        SectionContainer {
            Layout.fillWidth: true
            contentSpacing: Tokens.spacing.medium

                SectionHeader {
                    title: qsTr("Color Picker")
                    description: qsTr("Pick any color — applies to all devices")
                }

                // saturation × value square
                Rectangle {
                    id: svSquare

                    Layout.preferredWidth: 280
                    Layout.preferredHeight: 280
                    Layout.alignment: Qt.AlignHCenter
                    radius: Tokens.rounding.medium

                    // hue gradient (left→right white→hue), value (top→bottom transparent→black)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "white" }
                        GradientStop { position: 1.0; color: root.pickerHueColor }
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "black" }
                        }
                    }

                    // picker dot
                    Rectangle {
                        id: svDot

                        property real sx: 1.0
                        property real sy: 0.0

                        x: parent.width * sx - width / 2
                        y: parent.height * sy - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: "white"
                        border.width: 2
                        border.color: "black"
                        visible: root.pickerOpen
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: (m) => pick(m)
                        onPositionChanged: (m) => { if (pressed) pick(m) }
                        function pick(m) {
                            svDot.sx = Math.max(0, Math.min(1, m.x / svSquare.width))
                            svDot.sy = Math.max(0, Math.min(1, m.y / svSquare.height))
                            root.pickerHex = "#" + root.colorToHex(Qt.hsva(root.pickerHue, svDot.sx, 1 - svDot.sy, 1))
                        }
                    }
                }

                // hue slider
                RowLayout {
                    Layout.preferredWidth: 280
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Hue")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                        Layout.preferredWidth: 40
                    }

                    Rectangle {
                        id: hueBar

                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        radius: Tokens.rounding.full

                        gradient: Gradient {
                            GradientStop { position: 0.000; color: "#ff0000" }
                            GradientStop { position: 0.167; color: "#ffff00" }
                            GradientStop { position: 0.333; color: "#00ff00" }
                            GradientStop { position: 0.500; color: "#00ffff" }
                            GradientStop { position: 0.667; color: "#0000ff" }
                            GradientStop { position: 0.833; color: "#ff00ff" }
                            GradientStop { position: 1.000; color: "#ff0000" }
                        }

                        Rectangle {
                            id: hueMarker

                            x: parent.width * root.pickerHue - width / 2
                            y: 0
                            width: 6
                            height: parent.height
                            radius: 3
                            color: "white"
                            border.width: 1
                            border.color: "#00000088"
                            visible: root.pickerOpen
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: (m) => setHue(m)
                            onPositionChanged: (m) => { if (pressed) setHue(m) }
                            function setHue(m) {
                                root.pickerHue = Math.max(0, Math.min(1, m.x / hueBar.width))
                            }
                        }
                    }
                }

                // hex input
                RowLayout {
                    Layout.preferredWidth: 280
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    StyledText {
                        text: qsTr("Hex")
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                        Layout.preferredWidth: 40
                    }

                    StyledTextField {
                        id: hexField

                        Layout.fillWidth: true
                        text: root.pickerHex
                        maximumLength: 7
                        placeholderText: "#RRGGBB"
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).family("JetBrains Mono, monospace").build()
                        onAccepted: {
                            var h = hexField.text.trim()
                            if (h.length === 6) h = "#" + h
                            if (h.length === 7 && h[0] === "#") {
                                var c = Qt.color(h)
                                if (c.valid) root.applyColor(h)
                            }
                        }
                    }

                    TextButton {
                        text: qsTr("Apply")
                        type: TextButton.Filled
                        onClicked: {
                            var h = hexField.text.trim()
                            if (h.length === 6) h = "#" + h
                            if (h.length === 7 && h[0] === "#") {
                                var c = Qt.color(h)
                                if (c.valid) root.applyColor(h)
                            }
                        }
                    }
                }
        }

        // recent colors
        SectionContainer {
            Layout.fillWidth: true
            contentSpacing: Tokens.spacing.medium

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

        // per-device brightness
        SectionContainer {
            Layout.fillWidth: true
            contentSpacing: Tokens.spacing.medium

                SectionHeader {
                    title: qsTr("Brightness per device")
                    description: qsTr("Each device keeps its own level — 0 turns that device off")
                }

                DeviceBriRow {
                    icon: "brightness_6"
                    label: qsTr("All")
                    value: root.masterBrightness
                    accent: Colours.palette.m3primary
                    onMoved: (v) => { root.masterBrightness = Math.round(v * 100); masterBriDebounce.restart(); }
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
            contentSpacing: Tokens.spacing.small

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

    // ── local components ──────────────────────────────────────────────────
    component SectionContainer: StyledRect {
        default property alias content: contentColumn.data
        property real contentSpacing: Tokens.spacing.large
        property bool alignTop: false

        Layout.fillWidth: true
        implicitHeight: contentColumn.implicitHeight + Tokens.padding.extraLargeIncreased

        radius: Tokens.rounding.large
        color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : Colours.palette.m3surfaceContainerHigh

        ColumnLayout {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: root.alignTop ? parent.top : undefined
            anchors.verticalCenter: root.alignTop ? undefined : parent.verticalCenter
            anchors.margins: Tokens.padding.large

            spacing: root.contentSpacing
        }
    }

    component SectionHeader: ColumnLayout {
        required property string title
        property string description: ""

        spacing: 0

        StyledText {
            Layout.topMargin: Tokens.spacing.largeIncreased
            text: root.title
            font: Tokens.font.title.builders.medium.weight(Font.Medium).build()
        }

        StyledText {
            visible: root.description !== ""
            text: root.description
            color: Colours.palette.m3outline
        }
    }

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
