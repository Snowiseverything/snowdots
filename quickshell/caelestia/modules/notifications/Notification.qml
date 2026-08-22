pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Notifications
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.notifications.components

// ─────────────────────────────────────────────────────────────────────────────
// Notification card — original caelestia M3 implementation.
// Effects: ambient blob background, typewriter reveal, inline action buttons.
// Palette: Colours.palette (matugen) + Tokens.
// Sub-parts in ./components/ (editable standalone).
// ─────────────────────────────────────────────────────────────────────────────
StyledRect {
    id: root

    required property NotifData modelData
    readonly property bool hasImage: modelData.image.length > 0
    readonly property bool hasAppIcon: modelData.appIcon.length > 0
    readonly property int bodyTextFormat: /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText
    readonly property int nonAnimHeight: contentCol.implicitHeight + Tokens.padding.medium * 2
    property bool expanded: Config.notifs.openExpanded

    // M3 palette alias (edit colours here or in matugen)
    readonly property color cardBG: modelData.urgency === NotificationUrgency.Critical ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
    readonly property color primaryC: Colours.palette.m3primary
    readonly property color secondaryC: Colours.palette.m3secondaryContainer
    readonly property color onSurface: Colours.palette.m3onSurface
    readonly property color onSurfaceVariant: Colours.palette.m3onSurfaceVariant
    readonly property color onPrimaryC: Colours.palette.m3onPrimary

    color: cardBG
    radius: Tokens.rounding.large

    implicitHeight: contentCol.implicitHeight

    x: implicitWidth
    Component.onCompleted: {
        x = 0;
        modelData.lock(this);
    }
    Component.onDestruction: modelData.unlock(this)

    Behavior on x {
        Anim {}
    }

    clip: true

    // ── blob background decoration ─────────────────────────────────────────
    BlobBackground {
        anchors.fill: parent
        primaryColor: root.primaryC
        secondaryColor: root.secondaryC
        tertiaryColor: Colours.palette.m3tertiary
        baseColor: root.cardBG
    }

    MouseArea {
        id: dragArea

        property int startY
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.expanded && body.hoveredLink ? Qt.PointingHandCursor : pressed ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        preventStealing: true

        onEntered: root.modelData.timer.stop()
        onExited: {
            if (!pressed)
                root.modelData.timer.start();
        }

        drag.target: parent
        drag.axis: Drag.XAxis

        onPressed: event => {
            root.modelData.timer.stop();
            startY = event.y;
            if (event.button === Qt.MiddleButton)
                root.modelData.close();
        }
        onReleased: event => {
            if (!containsMouse)
                root.modelData.timer.start();
            if (Math.abs(root.x) < root.implicitWidth * Config.notifs.clearThreshold)
                root.x = 0;
            else
                root.modelData.popup = false;
        }
        onPositionChanged: event => {
            if (pressed) {
                const diffY = event.y - startY;
                if (Math.abs(diffY) > Config.notifs.expandThreshold)
                    root.expanded = diffY > 0;
            }
        }
        onClicked: event => {
            if (!GlobalConfig.notifs.actionOnClick || event.button !== Qt.LeftButton)
                return;
            const actions = root.modelData.actions;
            if (actions.length === 1)
                actions[0].invoke();
        }

        ColumnLayout {
            id: contentCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.extraSmall

            // ── header row: app icon/image + name + time ────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                Loader {
                    id: iconLoader
                    active: root.hasImage || root.hasAppIcon
                    Layout.preferredWidth: TokenConfig.sizes.notifs.image
                    Layout.preferredHeight: TokenConfig.sizes.notifs.image

                    sourceComponent: StyledClippingRect {
                        radius: Tokens.rounding.full
                        color: root.secondaryC
                        implicitWidth: TokenConfig.sizes.notifs.image
                        implicitHeight: TokenConfig.sizes.notifs.image

                        Image {
                            anchors.fill: parent
                            source: Qt.resolvedUrl(root.modelData.image)
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                            visible: root.hasImage
                        }
                        ColouredIcon {
                            anchors.centerIn: parent
                            width: parent.width * 0.6
                            height: parent.height * 0.6
                            source: Quickshell.iconPath(root.modelData.appIcon)
                            colour: root.onSurfaceVariant
                            visible: root.hasAppIcon && !root.hasImage
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: root.modelData.appName || "System"
                        color: root.onSurfaceVariant
                        font: Tokens.font.label.medium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: root.modelData.timeStr
                        color: root.onSurfaceVariant
                        font: Tokens.font.body.small
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.preferredWidth: expandBtn.implicitWidth
                    Layout.preferredHeight: expandBtn.implicitHeight

                    StateLayer {
                        id: expandBtn
                        radius: Tokens.rounding.full
                        color: root.onSurfaceVariant
                        onClicked: root.expanded = !root.expanded
                        anchors.fill: parent

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "expand_more"
                            fontStyle: Tokens.font.icon.medium
                            rotation: root.expanded ? 180 : 0
                            color: root.onSurface

                            Behavior on rotation {
                                Anim {}
                            }
                        }
                    }
                }
            }

            // ── summary (typewriter reveal on first appearance) ───────────
            TypewriterText {
                id: summaryTyper
                Layout.fillWidth: true
                fullText: root.modelData.summary
                charsPerTick: 2
                tickMs: 12
                startDelay: 120
                playing: !root.expanded
                color: root.onSurface
                font: Tokens.font.title.small
                maximumLineCount: 1
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            // ── body / body preview ─────────────────────────────────────────
            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: parent.width
                textFormat: root.bodyTextFormat
                text: root.modelData.body
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: root.expanded ? undefined : 2
                elide: root.expanded ? Text.ElideNone : Text.ElideRight
                color: root.onSurfaceVariant
                font: Tokens.font.body.small
                visible: root.modelData.body.length > 0
                clip: true

                onLinkActivated: link => {
                    Qt.openUrlExternally(link);
                    root.modelData.popup = false;
                }
            }

            // ── inline action buttons ───────────────────────────────────────
            ActionButtons {
                Layout.fillWidth: true
                Layout.topMargin: root.modelData.actions.length > 0 ? Tokens.spacing.small : 0
                actions: root.modelData.actions
                primaryColor: root.secondaryC
                onPrimaryColor: root.onPrimaryC
                surfaceColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                surfaceHighColor: root.onSurfaceVariant
                onSurfaceColor: root.onSurface
                visible: root.modelData.actions.length > 0
            }
        }
    }
}