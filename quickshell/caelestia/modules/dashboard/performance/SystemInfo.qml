import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// System specs content for the HeroCard's "System" tab.
// Single-column, compact spacing so it fits without scrolling.
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    Component.onCompleted: SystemUsage.refCount += 1
    Component.onDestruction: SystemUsage.refCount -= 1

    SpecRow {
        icon: "memory"
        label: qsTr("CPU")
        value: SystemUsage.cpuName
    }

    SpecRow {
        icon: "desktop_windows"
        label: qsTr("GPU")
        value: SystemUsage.gpuName
    }

    SpecRow {
        icon: "tune"
        label: qsTr("Cores")
        value: SystemUsage.cpuPhysicalCores > 0 ? `${SystemUsage.cpuPhysicalCores} cores / ${SystemUsage.coreCount} threads` : `${SystemUsage.coreCount} threads`
    }

    SpecRow {
        icon: "layers"
        label: qsTr("Driver")
        value: SystemUsage.gpuDriver || "—"
    }

    SpecRow {
        icon: "bolt"
        label: qsTr("Clock")
        value: SystemUsage.cpuBaseMhz > 0 && SystemUsage.cpuMaxMhz > 0 ? `${(SystemUsage.cpuBaseMhz / 1000).toFixed(1)} – ${(SystemUsage.cpuMaxMhz / 1000).toFixed(1)} GHz` : SystemUsage.cpuMaxMhz > 0 ? `${(SystemUsage.cpuMaxMhz / 1000).toFixed(1)} GHz` : "—"
    }

    SpecRow {
        icon: "memory_alt"
        label: qsTr("VRAM")
        value: SystemUsage.gpuVramTotal > 0 ? `${Math.round(SystemUsage.gpuVramTotal)} MiB` : "—"
    }

    SpecRow {
        icon: "bolt"
        label: qsTr("Power")
        value: SystemUsage.cpuPowerW > 0 ? `${SystemUsage.cpuPowerW.toFixed(1)} W` : "—"
    }

    SpecRow {
        icon: "speed"
        label: qsTr("RAM Speed")
        value: SystemUsage.ramSpeedMhz > 0 ? `${SystemUsage.ramSpeedMhz} MT/s` : "—"
    }

    SpecRow {
        icon: "ram"
        label: qsTr("RAM")
        value: SystemUsage.memTotal > 0 ? (() => { const f = SystemUsage.formatKib(SystemUsage.memTotal); return `${f.value.toFixed(0)} ${f.unit}`; })() : "—"
    }

    SpecRow {
        icon: "developer_board"
        label: qsTr("Motherboard")
        value: (() => { const v = SystemUsage.moboVendor; const n = SystemUsage.moboName; return (v && n) ? `${v} ${n}` : (v || n || "—"); })()
    }

    component SpecRow: RowLayout {
        id: row

        required property string icon
        required property string label
        required property string value

        spacing: Tokens.spacing.small

        MaterialIcon {
            text: row.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            StyledText {
                text: row.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                text: row.value
                font: Tokens.font.body.builders.medium.build()
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
            }
        }
    }
}
