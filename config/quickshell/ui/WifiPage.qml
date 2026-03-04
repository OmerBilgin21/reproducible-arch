import QtQuick

Column {
    required property var shell
    required property var wifiModel
    spacing: 10

    Row {
        spacing: 8

        Rectangle {
            width: 160
            height: 32
            radius: 8
            color: wifiToggleArea.pressed ? shell.green : wifiToggleArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: shell.wifiEnabled ? "Turn Wi-Fi Off" : "Turn Wi-Fi On"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: wifiToggleArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    shell.toggleWifi()
                }
            }
        }

        Rectangle {
            width: 80
            height: 32
            radius: 8
            color: scanArea.pressed ? shell.green : scanArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: shell.wifiScanning ? ("Scanning" + (shell.scanTick % 3 === 0 ? "." : shell.scanTick % 3 === 1 ? ".." : "...")) : "Scan"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: scanArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: shell.startWifiScan()
            }
        }
    }

    Text {
        text: shell.networkState === "connected" ? "Connected to " + shell.networkSsid : "Not connected"
        color: shell.grey1
        font.pixelSize: 11
    }

    Rectangle {
        width: parent.width
        height: 520
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        ListView {
            visible: !shell.wifiScanning && wifiModel.count > 0
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            spacing: 6
            model: wifiModel

            delegate: Rectangle {
                required property bool inUse
                required property string bssid
                required property string ssid
                required property int signal
                required property string security

                width: ListView.view.width
                height: 36
                radius: 7
                color: inUse ? "#3C4841" : shell.bg2

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (ssid !== "" ? ssid : bssid) + "  " + signal + "%"
                    color: shell.fg
                    font.pixelSize: 11
                }

                Text {
                    anchors.right: actionRect.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: security !== "" ? security : "Open"
                    color: shell.grey1
                    font.pixelSize: 10
                }

                Rectangle {
                    id: actionRect
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 70
                    height: 24
                    radius: 6
                    color: inUse ? shell.bg3 : connectArea.pressed ? shell.green : connectArea.containsMouse ? shell.bg3 : shell.bg0

                    Text {
                        anchors.centerIn: parent
                        text: inUse ? "Active" : "Connect"
                        color: shell.fg
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: connectArea
                        anchors.fill: parent
                        enabled: !inUse
                        hoverEnabled: true
                        onClicked: {
                            var target = bssid !== "" ? bssid : ssid
                            shell.connectWifi(target)
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - 28
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: shell.wifiScanning || wifiModel.count === 0
            text: shell.wifiScanning ? ("Scanning Wi-Fi" + (shell.scanTick % 3 === 0 ? "." : shell.scanTick % 3 === 1 ? ".." : "...")) : shell.wifiListStatus
            color: shell.grey1
            font.pixelSize: 12
        }
    }
}
