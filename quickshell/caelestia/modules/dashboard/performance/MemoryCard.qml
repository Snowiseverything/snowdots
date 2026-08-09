import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    readonly property color accent: Colours.palette.m3tertiary

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.medium

    implicitWidth: layout.implicitWidth + Tokens.padding.extraLargeIncreased * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ServiceRef {
        service: Memory
    }

    // Keep the SystemUsage timer alive (swap/available/cached data)
    Component.onCompleted: SystemUsage.refCount += 1
    Component.onDestruction: SystemUsage.refCount -= 1

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: -Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "memory_alt"
                fill: 1
                color: root.accent
                fontStyle: Tokens.font.icon.builders.medium.weight(Font.DemiBold).build() // DemiBold to fix fill issues
            }

            StyledText {
                text: qsTr("Memory")
                font: Tokens.font.title.medium
            }
        }

        CircularProgress {
            Layout.topMargin: Tokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            implicitSize: usageColumn.implicitHeight + thickness + Tokens.padding.largeIncreased * 2
            startAngle: -225
            sweepAngle: 270

            fgColour: root.accent
            value: Memory.percentage

            Behavior on clampedVal {
                Anim {}
            }

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                anchors.verticalCenterOffset: Tokens.padding.extraSmall
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(Memory.percentage * 100) + "%"
                    font: Tokens.font.title.builders.large.width(90).build()
                    color: root.accent
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Used")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const used = SystemUsage.formatKib(Memory.used);
                const total = SystemUsage.formatKib(Memory.total);
                return `${used.value.toFixed(1)} / ${Math.floor(total.value)} ${total.unit}`;
            }
            font: Tokens.font.body.medium
        }

        // Detail grid: Available | Cached / Swap | Speed
        GridLayout {
            Layout.topMargin: Tokens.spacing.large
            columns: 2
            columnSpacing: Tokens.spacing.large
            rowSpacing: Tokens.spacing.small

            // Available
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "check_circle"
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.small.weight(Font.DemiBold).build()
                    fill: 1
                }

                StyledText {
                    text: qsTr("Available")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: SystemUsage.memAvailable > 0 ? `${SystemUsage.formatKib(SystemUsage.memAvailable).value.toFixed(1)} ${SystemUsage.formatKib(SystemUsage.memAvailable).unit}` : "—"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Cached
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "cached"
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.small.weight(Font.DemiBold).build()
                    fill: 1
                }

                StyledText {
                    text: qsTr("Cached")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: SystemUsage.memCached > 0 ? `${SystemUsage.formatKib(SystemUsage.memCached).value.toFixed(1)} ${SystemUsage.formatKib(SystemUsage.memCached).unit}` : "—"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Swap
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "swap_vert"
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.small.weight(Font.DemiBold).build()
                    fill: 1
                }

                StyledText {
                    text: qsTr("Swap")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: SystemUsage.swapTotal > 0 ? `${Math.round(SystemUsage.swapPerc * 100)}%` : "—"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            // Speed (env QS_RAM_SPEED_MHZ — SPD/dmidecode need root)
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "bolt"
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.small.weight(Font.DemiBold).build()
                    fill: 1
                }

                StyledText {
                    text: qsTr("Speed")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: SystemUsage.ramSpeedMhz > 0 ? `${SystemUsage.ramSpeedMhz} MT/s` : "—"
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }
}
