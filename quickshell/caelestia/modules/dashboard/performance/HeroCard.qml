pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage
    required property real temperature
    property Component detailsContent: null
    property Component systemContent: null

    // 0 = Overview, 1 = Details, 2 = System
    property int currentTab: 0
    onCurrentTabChanged: {
        if (currentTab > tabCount - 1)
            currentTab = tabCount - 1;
        else if (currentTab < 0)
            currentTab = 0;
    }

    readonly property bool hasDetails: detailsContent !== null
    readonly property bool hasSystem: systemContent !== null
    readonly property bool hasTabs: hasDetails || hasSystem
    readonly property int tabCount: (hasDetails ? 1 : 0) + (hasSystem ? 1 : 0) + 1 // + Overview

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfHeroCardWidth
    readonly property real overviewHeight: Math.max(tempProg.implicitHeight + detailsRow.implicitHeight + Tokens.spacing.large, usageShape.implicitHeight + usageLabel.implicitHeight) + Tokens.padding.large * 2
    implicitHeight: (hasTabs ? tabStrip.implicitHeight + Tokens.spacing.small : 0) + overviewHeight

    // --- Overview content (circular gauge + temp row + usage shape) ---
    Item {
        id: overview

        visible: root.currentTab === 0
        anchors.fill: parent
        anchors.bottomMargin: root.hasTabs ? tabStrip.implicitHeight + Tokens.spacing.small : 0

        CircularProgress {
            id: tempProg

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large

            fgColour: root.accent

            spacing: Tokens.spacing.extraSmall
            strokeWidth: Tokens.padding.extraSmall
            implicitSize: Math.max(icon.implicitWidth, icon.implicitHeight) + Tokens.padding.medium * 2
            value: root.usage

            Behavior on clampedVal {
                Anim {}
            }

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: root.icon
                color: root.accent
                fontStyle: Tokens.font.icon.medium
            }
        }

        ColumnLayout {
            anchors.left: tempProg.right
            anchors.right: parent.right
            anchors.verticalCenter: tempProg.verticalCenter
            anchors.margins: Tokens.spacing.large
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: root.label
                font: Tokens.font.title.medium
                color: root.accent
            }

            StyledText {
                Layout.fillWidth: true
                text: root.subLabel
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            id: detailsRow

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.leftMargin: -Tokens.padding.extraSmall
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    Layout.topMargin: Math.round(fontInfo.pointSize * 0.08)
                    text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                    color: root.temperature > 90 ? Colours.palette.m3error : root.accent
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                StyledText {
                    text: `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? root.temperature * 1.8 + 32 : root.temperature)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`
                    font: Tokens.font.body.builders.medium.build()
                }
            }

            StyledProgressBar {
                value: root.temperature / 100
                implicitHeight: Tokens.padding.small
                fgColour: root.accent
                indeterminate: isNaN(root.usage) || isNaN(root.temperature)
            }
        }

        MaterialShape {
            id: usageShape

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Tokens.padding.medium

            implicitSize: Tokens.sizes.dashboard.perfUsageShapeSize
            color: Colours.palette.m3secondaryContainer
            shape: {
                if (root.usage >= 0.8)
                    return MaterialShape.SoftBurst;
                if (root.usage >= 0.4)
                    return MaterialShape.Sunny;
                return MaterialShape.Cookie4Sided;
            }

            Behavior on color {
                CAnim {}
            }

            StyledText {
                id: usageLabel

                anchors.bottom: parent.top
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Usage")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                anchors.centerIn: parent
                text: isNaN(root.usage) ? "...%" : Math.round(root.usage * 100) + "%"
                color: root.accent
                font: Tokens.font.headline.builders.small.width(50).build()
            }
        }
    }

    // --- Details / System scrollable content ---
    Flickable {
        id: contentScroll

        visible: root.currentTab !== 0
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.medium
        anchors.rightMargin: Tokens.spacing.medium
        anchors.bottomMargin: root.hasTabs ? tabStrip.implicitHeight + Tokens.spacing.small : Tokens.spacing.medium

        clip: true
        contentWidth: width
        contentHeight: contentLoader.implicitHeight

        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Loader {
            id: contentLoader

            width: contentScroll.width
            active: root.hasDetails || root.hasSystem
            asynchronous: true

            sourceComponent: root.currentTab === root.tabCount - 1 && root.hasSystem ? root.systemContent : root.detailsContent
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: contentScroll
        }
    }

    // --- Overview / Details / System tab strip (theme Tab pattern) ---
    Item {
        id: tabStrip

        visible: root.hasTabs
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.small

        implicitHeight: bar.implicitHeight + bar.anchors.topMargin + indicator.implicitHeight + indicator.anchors.topMargin

        TabBar {
            id: bar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Tokens.sizes.dashboard.tabIndicatorSpacing

            currentIndex: root.currentTab
            onCurrentIndexChanged: root.currentTab = currentIndex

            implicitHeight: contentHeight
            background: null
            contentItem: RowLayout {
                spacing: 0

                Repeater {
                    model: bar.contentModel
                }
            }

            // Model built dynamically so hidden tabs never occupy an index
            readonly property var tabModel: {
                const m = [{ iconName: "speed", text: qsTr("Overview") }];
                if (root.hasDetails)
                    m.push({ iconName: "tune", text: qsTr("Details") });
                if (root.hasSystem)
                    m.push({ iconName: "info", text: qsTr("System") });
                return m;
            }

            Repeater {
                model: bar.tabModel

                delegate: StripTab {
                    required property var modelData

                    iconName: modelData.iconName
                    text: modelData.text
                }
            }
        }

        // Keep currentTab in bounds when tabs are added/removed

        Item {
            id: indicator

            anchors.top: bar.bottom
            anchors.topMargin: 5

            // Auto-size to the current tab's width, sliding between tabs
            // (mirrors Tabs.qml's top-bar indicator exactly)
            implicitWidth: {
                const tab = bar.currentItem;
                if (tab)
                    return tab.implicitWidth;
                const width = (tabStrip.width - bar.spacing * (bar.count - 1)) / bar.count;
                return width;
            }
            implicitHeight: 3

            x: {
                const tab = bar.currentItem;
                const width = (tabStrip.width - bar.spacing * (bar.count - 1)) / bar.count;
                const tabWidth = tab?.implicitWidth ?? width;
                return width * bar.currentIndex + (width - tabWidth) / 2;
            }

            clip: true

            StyledRect {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight * 2

                color: root.accent
                radius: Tokens.rounding.full
            }

            Behavior on x {
                Anim {}
            }

            Behavior on implicitWidth {
                Anim {}
            }
        }
    }

    // Matches Tabs.qml's Tab component: icon above label, wheel switches tab
    component StripTab: TabButton {
        id: tab

        required property string iconName
        readonly property bool current: TabBar.tabBar.currentItem === this

        Layout.fillWidth: true
        Layout.preferredWidth: 1 // Uniform width across all tabs
        implicitWidth: implicitContentWidth
        implicitHeight: implicitContentHeight
        background: null

        contentItem: CustomMouseArea {
            id: mouse

            function onWheel(event: WheelEvent): void {
                if (event.angleDelta.y < 0)
                    root.currentTab = Math.min(root.currentTab + 1, root.tabCount - 1);
                else if (event.angleDelta.y > 0)
                    root.currentTab = Math.max(root.currentTab - 1, 0);
            }

            implicitWidth: Math.max(icon.width, label.width)
            implicitHeight: icon.height + label.height

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: root.currentTab = tab.TabBar.index

            StateLayer {
                id: stateLayer

                anchors.fill: undefined
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height + Tokens.sizes.dashboard.tabIndicatorSpacing * 2

                radius: Tokens.rounding.medium
                color: tab.current ? root.accent : Colours.palette.m3onSurface
                onClicked: root.currentTab = tab.TabBar.index
            }

            MaterialIcon {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: label.top

                text: tab.iconName
                color: tab.current ? root.accent : Colours.palette.m3onSurfaceVariant
                fill: tab.current ? 1 : 0
                fontStyle: Tokens.font.icon.medium

                Behavior on fill {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            StyledText {
                id: label

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                text: tab.text
                color: tab.current ? root.accent : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
