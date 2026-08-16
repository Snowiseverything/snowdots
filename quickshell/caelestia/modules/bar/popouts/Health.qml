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
    property string diskRoot: "?"
    property string diskHome: "?"
    property string gpu: "?"

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

    Process {
        id: sysReader
        command: ["bash", "-c", "$HOME/Dotfiles/scripts/sys-stats.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split('\n')) {
                    const eq = line.indexOf('=');
                    if (eq < 0)
                        continue;
                    const key = line.slice(0, eq);
                    const val = line.slice(eq + 1);
                    if (key === 'disk_/') root.diskRoot = val + "%";
                    else if (key === 'disk_/home') root.diskHome = val + "%";
                    else if (key === 'gpu') root.gpu = val;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            reader.running = true
            sysReader.running = true
        }
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

    StyledText {
        text: qsTr("Disk /: %1  ·  /home: %2").arg(root.diskRoot).arg(root.diskHome)
    }

    StyledText {
        text: qsTr("GPU: %1").arg(root.gpu)
    }
}
