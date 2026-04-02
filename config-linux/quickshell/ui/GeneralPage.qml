import QtQuick

Column {
    required property var shell
    spacing: 12

    function summaryItems() {
        var wifiIcon = shell.wifiEnabled
            ? (shell.networkSsid !== "" ? "󰤨" : "󰤮")
            : "󰤭";

        return [
            {
                icon: wifiIcon,
                title: "Network",
                subtitle: shell.wifiEnabled ? (shell.networkSsid !== "" ? shell.networkSsid : "Enabled") : "Disabled"
            },
            {
                icon: shell.bluetoothEnabled ? "" : "󰂲",
                title: "Bluetooth",
                subtitle: shell.bluetoothEnabled ? (shell.bluetoothConnections + " connected") : "Disabled"
            },
            {
                icon: shell.audioMuted ? "" : "󰕾",
                title: "Output",
                subtitle: shell.audioMuted ? "Muted" : (shell.audioVolume + "%")
            },
            {
                icon: "󱊣",
                title: "Battery",
                subtitle: shell.batteryPercent + "% (" + shell.batteryStatus + ")"
            }
        ];
    }

    Rectangle {
        width: parent.width
        height: 90
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16

            Repeater {
                model: summaryItems()

                SummaryTile {
                    required property var modelData
                    width: (parent.width - (3 * 16)) / 4
                    icon: modelData.icon
                    title: modelData.title
                    subtitle: modelData.subtitle
                    fg: shell.fg
                    muted: shell.grey1
                }
            }
        }
    }
}
