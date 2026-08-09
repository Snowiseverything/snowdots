import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Details content for the CPU HeroCard's "Details" tab.
// Pure content — the HeroCard provides the card chrome.
ColumnLayout {
    id: root

    readonly property color accent: Colours.palette.m3primary

    // Keep the SystemUsage timer alive while this content is visible
    Component.onCompleted: SystemUsage.refCount += 1
    Component.onDestruction: SystemUsage.refCount -= 1

    spacing: Tokens.spacing.medium

    // Per-core usage bars
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        clip: true

        Row {
            anchors.fill: parent
            spacing: 2
            Repeater {
                model: SystemUsage.perCorePerc

                delegate: Item {
                    required property real modelData

                    width: 6
                    height: parent.height

                    StyledRect {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * Math.max(modelData, 0.03)
                        color: root.accent
                        radius: 2

                        Behavior on height {
                            Anim {}
                        }
                    }
                }
            }
        }
    }

    // Current frequency + core count
    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "bolt"
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Frequency")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: SystemUsage.cpuFreqMhz > 0 ? `${Math.round(SystemUsage.cpuFreqMhz)} MHz` : "—"
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: root.accent
        }

        StyledText {
            text: SystemUsage.coreCount > 0 ? `${SystemUsage.coreCount} cores` : ""
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Load average as % of cores
    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "monitoring"
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Load avg")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: {
                if (SystemUsage.coreCount <= 0)
                    return "—";
                const pct = load => Math.round(load / SystemUsage.coreCount * 100) + "%";
                return `1m ${pct(SystemUsage.loadAvg1)} · 5m ${pct(SystemUsage.loadAvg5)} · 15m ${pct(SystemUsage.loadAvg15)}`;
            }
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }

    // Overall usage bar
    StyledProgressBar {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        implicitHeight: Tokens.padding.small
        value: SystemUsage.cpuPerc
        fgColour: root.accent
        indeterminate: isNaN(SystemUsage.cpuPerc)
    }

    // Estimated CPU power (RAPL energy_uj is root-only; estimated from utilization + max limit)
    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "bolt"
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("Power")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: SystemUsage.cpuPowerW > 0 ? `${SystemUsage.cpuPowerW.toFixed(1)} W` : "—"
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: root.accent
        }
    }
}
