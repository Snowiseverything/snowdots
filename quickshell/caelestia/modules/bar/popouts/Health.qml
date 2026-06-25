import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root
    spacing: Tokens.spacing.small

    property string snowpi: "?"
    property string internet: "?"
    property string dns: "?"

    function cap(v: string): string {
        if (v === "up") return "UP";
        if (v === "down") return "DOWN";
        if (v === "ok") return "OK";
        if (v === "fail") return "FAIL";
        return v;
    }

    Process {
        id: reader
        command: ["cat", "/tmp/health-status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split('\n')) {
                    const [key, val] = line.split('=');
                    if (key === 'snowpi') root.snowpi = val;
                    else if (key === 'internet') root.internet = val;
                    else if (key === 'dns') root.dns = val;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: reader.running = true
    }

    StyledText {
        text: qsTr("Snowpi: %1").arg(cap(root.snowpi))
    }

    StyledText {
        text: qsTr("DNS: %1").arg(cap(root.dns))
    }

    StyledText {
        text: qsTr("Internet: %1").arg(cap(root.internet))
    }
}
