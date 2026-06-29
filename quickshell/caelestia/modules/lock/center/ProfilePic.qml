pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    implicitWidth: centerWidth
    implicitHeight: Math.round(centerWidth * 0.55)

    Rectangle {
        id: shape

        anchors.centerIn: parent
        width: root.implicitWidth
        height: root.implicitHeight
        radius: Tokens.rounding.large
        color: Qt.alpha(root.bgColour, 1)
        opacity: root.bgColour.a
        layer.enabled: true
    }

    MaterialIcon {
        anchors.centerIn: parent

        text: "person"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size(root.centerWidth / 4).build()
        visible: pfp.status !== Image.Ready
    }

    CachingImage {
        id: pfp

        anchors.fill: shape
        anchors.margins: Tokens.padding.small
        path: `${Paths.home}/.cache/skwd-wall/current-wallpaper`
        fillMode: Image.PreserveAspectCrop

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shape
        }
    }
}
