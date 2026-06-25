pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Item {
    id: root

    required property var weather

    readonly property string condition: {
        const icon = Weather.icon;
        if (icon.includes("snow")) return "snow";
        if (icon.includes("rain") || icon.includes("pour")) return "rain";
        if (icon.includes("fog") || icon.includes("mist")) return "fog";
        if (icon.includes("cloud")) return "cloud";
        if (icon.includes("clear")) return "clear";
        return "none";
    }

    readonly property int particleCount: {
        switch (condition) {
            case "rain": return 80;
            case "snow": return 50;
            case "fog":  return 15;
            case "cloud": return 8;
            case "clear": return 12;
            default: return 0;
        }
    }

    Repeater {
        model: root.particleCount

        Particle {
            condition: root.condition
        }
    }

    component Particle: Item {
        id: particle

        required property string condition

        readonly property real particleSize: {
            switch (condition) {
                case "rain": return 2 + Math.random() * 2;
                case "snow": return 3 + Math.random() * 4;
                case "fog":  return 40 + Math.random() * 60;
                case "cloud":return 60 + Math.random() * 80;
                case "clear":return 2 + Math.random() * 3;
                default: return 0;
            }
        }

        readonly property real particleSpeed: {
            switch (condition) {
                case "rain": return 300 + Math.random() * 400;
                case "snow": return 30 + Math.random() * 50;
                case "fog":  return 5 + Math.random() * 10;
                case "cloud":return 2 + Math.random() * 4;
                case "clear":return 10 + Math.random() * 20;
                default: return 0;
            }
        }

        readonly property real particleOpacity: {
            switch (condition) {
                case "rain": return 0.2 + Math.random() * 0.3;
                case "snow": return 0.4 + Math.random() * 0.3;
                case "fog":  return 0.05 + Math.random() * 0.08;
                case "cloud":return 0.06 + Math.random() * 0.08;
                case "clear":return 0.3 + Math.random() * 0.5;
                default: return 0;
            }
        }

        readonly property real randX: Math.random()
        readonly property real randY: 1 - Math.random() * 0.3

        readonly property real endX: condition === "fog" || condition === "cloud" ? root.width + particleSize : randX * root.width + (condition === "rain" ? (-20 + Math.random() * 40) * 8 : (condition === "snow" ? (-10 + Math.random() * 20) * 8 : (condition === "clear" ? (-particleSpeed / 2 + Math.random() * particleSpeed) * 3 : 0)))

        x: condition === "clear" ? randX * root.width : randX * root.width
        y: condition === "clear" ? root.height + particleSize : -particleSize

        visible: condition !== "none"

        NumberAnimation on y {
            id: fallAnim
            from: particle.y
            to: condition === "clear" ? -particleSize : root.height + particleSize
            duration: condition === "clear" ? 3000 + Math.random() * 3000 : Math.abs((root.height + particleSize * 2) / (particleSpeed / 1000))
            easing.type: condition === "clear" ? Easing.OutQuad : Easing.Linear
            loops: Animation.Infinite
        }

        NumberAnimation on x {
            id: driftAnim
            running: condition !== "clear"
            from: particle.x
            to: condition === "fog" || condition === "cloud" ? root.width + particleSize : particle.endX
            duration: Math.abs((root.width + particleSize) / (condition === "fog" || condition === "cloud" ? particleSpeed / 1000 : particleSpeed / 2000))
            easing.type: Easing.Linear
            loops: Animation.Infinite
        }

        NumberAnimation on opacity {
            running: condition === "clear"
            from: particle.particleOpacity
            to: 0.1
            duration: 500 + Math.random() * 1000
            easing.type: Easing.InOutSine
            loops: Animation.Infinite
        }

        Rectangle {
            anchors.centerIn: parent
            width: condition === "rain" ? 1.5 : particle.particleSize
            height: condition === "rain" ? 8 + Math.random() * 12 : particle.particleSize
            radius: condition === "snow" ? width / 2 : condition !== "rain" ? width / 4 : 0
            color: condition === "rain" ? Colours.palette.m3primary : condition === "snow" ? Qt.rgba(1, 1, 1, particleOpacity) : Qt.rgba(1, 1, 0.8, particleOpacity)
            opacity: particle.particleOpacity
        }
    }
}
