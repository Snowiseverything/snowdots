import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

RowLayout {
    id: root

    required property var lock

    spacing: Tokens.spacing.large * 2

    component HoverPanel: StyledRect {
        property real hoverScale: 1

        transform: Scale {
            origin.x: width / 2
            origin.y: height / 2
            xScale: hoverScale
            yScale: hoverScale
        }

        Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: parent.hoverScale = hovered ? 1.02 : 1
        }
    }

    component HoverClippingPanel: StyledClippingRect {
        property real hoverScale: 1

        transform: Scale {
            origin.x: width / 2
            origin.y: height / 2
            xScale: hoverScale
            yScale: hoverScale
        }

        Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: parent.hoverScale = hovered ? 1.02 : 1
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        HoverPanel {
            Layout.fillWidth: true
            implicitHeight: weather.implicitHeight

            topLeftRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            WeatherInfo {
                id: weather

                rootHeight: root.height
            }
        }

        HoverPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Fetch {}
        }

        HoverClippingPanel {
            Layout.fillWidth: true
            implicitHeight: media.implicitHeight

            bottomLeftRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Media {
                id: media

                lock: root.lock
            }
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        HoverPanel {
            Layout.fillWidth: true
            implicitHeight: resources.implicitHeight

            topRightRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Resources {
                id: resources
            }
        }

        HoverPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Tokens.rounding.large
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
