import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Details content for the GPU HeroCard's "Details" tab.
// Pure content — the HeroCard provides the card chrome.
ColumnLayout {
    id: root

    readonly property color accent: Colours.palette.m3secondary

    // Keep the SystemUsage timer alive while this content is visible
    Component.onCompleted: SystemUsage.refCount += 1
    Component.onDestruction: SystemUsage.refCount -= 1

    spacing: Tokens.spacing.medium

    // Clocks + power
    RowLayout {
        spacing: Tokens.spacing.large

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: qsTr("Core clock")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: SystemUsage.gpuClockSm > 0 ? `${Math.round(SystemUsage.gpuClockSm)} MHz` : "—"
                font: Tokens.font.title.medium
                color: root.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: qsTr("Memory clock")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: SystemUsage.gpuClockMem > 0 ? `${Math.round(SystemUsage.gpuClockMem)} MHz` : "—"
                font: Tokens.font.title.medium
                color: root.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: qsTr("Power")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: SystemUsage.gpuPower > 0 ? `${SystemUsage.gpuPower.toFixed(1)} W` : "—"
                font: Tokens.font.title.medium
                color: root.accent
            }
        }
    }

    // VRAM
    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "memory"
            color: root.accent
            fontStyle: Tokens.font.icon.medium
        }

        StyledText {
            text: qsTr("VRAM")
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: SystemUsage.gpuFan > 0 ? `${Math.round(SystemUsage.gpuFan)}% fan` : ""
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: SystemUsage.gpuVramTotal > 0 ? `${Math.round(SystemUsage.gpuVramUsed)} / ${Math.round(SystemUsage.gpuVramTotal)} MiB` : "—"
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            color: root.accent
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.extraSmall
        implicitHeight: Tokens.padding.small
        value: SystemUsage.gpuVramTotal > 0 ? SystemUsage.gpuVramUsed / SystemUsage.gpuVramTotal : 0
        fgColour: root.accent
        indeterminate: isNaN(SystemUsage.gpuVramTotal)
    }
}
