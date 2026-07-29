import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property Props props
    required property DrawerVisibilities visibilities

    readonly property int activeWsId: Hypr.activeWsId
    readonly property var occupied: (() => {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    })()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.fillWidth: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.small

                Repeater {
                    model: 10

                    delegate: Item {
                        required property int index

                        readonly property int wsId: index + 1
                        readonly property bool isActive: root.activeWsId === wsId
                        readonly property bool isOccupied: root.occupied[wsId] ?? false

                        Layout.fillWidth: true
                        implicitHeight: 32

                        StyledRect {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            color: isActive ? Colours.palette.m3primary : (isOccupied ? Colours.palette.m3surfaceContainerHigh : "transparent")
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Tokens.padding.medium
                            text: wsId.toString()
                            color: isActive ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            font.pixelSize: 14
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.padding.medium
                            text: isOccupied ? "●" : "○"
                            color: isActive ? Colours.palette.m3onPrimary : (isOccupied ? Colours.palette.m3primary : Colours.palette.m3outlineVariant)
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Hypr.activeWsId !== wsId)
                                    Hypr.dispatch("workspace " + wsId)
                                else
                                    Hypr.dispatch("togglespecialworkspace special")
                            }
                        }
                    }
                }

                // Wheel handler covers the workspace list area
                MouseArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    acceptedButtons: Qt.NoButton
                    onWheel: event => {
                        if (event.angleDelta.y > 0)
                            Hypr.dispatch("workspace r-1");
                        else
                            Hypr.dispatch("workspace r+1");
                        event.accepted = true;
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                props: root.props
                visibilities: root.visibilities
            }
        }

        StyledRect {
            Layout.topMargin: Tokens.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
