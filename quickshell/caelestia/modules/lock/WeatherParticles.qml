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
            index: index
            onDestroyed: root.tryRecreate(this)
        }
    }

    function tryRecreate(particle: Item): void {
        if (particleCount > 0)
            particle.forceRestart();
    }

    component Particle: Item {
        id: particle

        required property string condition
        required property int index

        property real vx: 0
        property real vy: 0
        property real size: 0
        property real speed: 0
        property real opacityVal: 0.3

        readonly property real startX: Math.random() * root.width
        readonly property real startY: -size

        x: startX
        y: startY

        Component.onCompleted: init()
        function init(): void {
            switch (condition) {
                case "rain":
                    size = 2 + Math.random() * 2;
                    speed = 300 + Math.random() * 400;
                    vx = -20 + Math.random() * 40;
                    vy = speed;
                    opacityVal = 0.2 + Math.random() * 0.3;
                    break;
                case "snow":
                    size = 3 + Math.random() * 4;
                    speed = 30 + Math.random() * 50;
                    vx = -10 + Math.random() * 20;
                    vy = speed;
                    opacityVal = 0.4 + Math.random() * 0.3;
                    break;
                case "fog":
                    size = 40 + Math.random() * 60;
                    speed = 5 + Math.random() * 10;
                    vx = speed;
                    vy = -1 + Math.random() * 2;
                    opacityVal = 0.05 + Math.random() * 0.08;
                    break;
                case "cloud":
                    size = 60 + Math.random() * 80;
                    speed = 2 + Math.random() * 4;
                    vx = speed;
                    vy = 0;
                    opacityVal = 0.06 + Math.random() * 0.08;
                    break;
                case "clear":
                    size = 2 + Math.random() * 3;
                    speed = 10 + Math.random() * 20;
                    vx = -speed / 2 + Math.random() * speed;
                    vy = -speed;
                    opacityVal = 0.3 + Math.random() * 0.5;
                    break;
            }

            animX.from = startX;
            animY.from = startY;
            animX.to = condition === "fog" || condition === "cloud" ? root.width + size : startX + vx * 8;
            animY.to = condition === "clear" ? -size : root.height + size;
            animDuration = condition === "clear" ? 3000 + Math.random() * 3000 : Math.abs(animY.to - startY) / Math.abs(vy) * 1000;

            if (condition === "clear") {
                flickerAnim.start();
            }
        }

        function forceRestart(): void {
            x = Math.random() * root.width;
            y = -size;
            animX.from = x;
            animY.from = y;
            animX.to = condition === "fog" || condition === "cloud" ? root.width + size : x + vx * 8;
            animY.to = condition === "clear" ? -size : root.height + size;
            animDuration = condition === "clear" ? 3000 + Math.random() * 3000 : Math.abs(animY.to - y) / Math.abs(vy) * 1000;
            animX.running = false;
            animY.running = false;
            animX.running = true;
            animY.running = true;
            if (condition === "clear") {
                flickerAnim.restart();
            }
        }

        readonly property real animDuration: 5000
        readonly property real animXto: 0
        readonly property real animYto: 0

        NumberAnimation on x {
            id: animX
            duration: particle.animDuration
            to: particle.animXto
            from: particle.startX
            easing.type: Easing.Linear
            loops: 1
            onFinished: particle.destroy()
        }

        NumberAnimation on y {
            id: animY
            duration: particle.animDuration
            to: particle.animYto
            from: particle.startY
            easing.type: Easing.Linear
            loops: 1
        }

        NumberAnimation on opacity {
            id: flickerAnim
            running: false
            from: particle.opacityVal
            to: 0.1
            duration: 500 + Math.random() * 1000
            easing.type: Easing.InOutSine
            loops: Animation.Infinite
        }

        visible: condition !== "none"

        Rectangle {
            anchors.centerIn: parent
            width: condition === "rain" ? 1.5 : condition === "fog" || condition === "cloud" ? parent.size : parent.size
            height: condition === "rain" ? 8 + Math.random() * 12 : condition === "fog" || condition === "cloud" ? parent.size : parent.size
            radius: condition === "snow" ? width / 2 : condition !== "rain" ? width / 4 : 0
            color: condition === "rain" ? Colours.palette.m3primary : condition === "snow" ? Qt.rgba(1, 1, 1, opacity) : condition === "clear" ? Qt.rgba(1, 1, 0.8, opacity) : Qt.rgba(1, 1, 1, opacity)
            opacity: particle.opacityVal
        }
    }
}
