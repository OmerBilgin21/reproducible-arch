import QtQuick

Column {
    required property var shell
    required property var btModel
    spacing: 10

    Row {
        spacing: 8

        Rectangle {
            width: 180
            height: 32
            radius: 8
            color: btToggleArea.pressed ? shell.green : btToggleArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: shell.bluetoothEnabled ? "Turn Bluetooth Off" : "Turn Bluetooth On"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: btToggleArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    shell.toggleBluetooth()
                }
            }
        }

        Rectangle {
            width: 80
            height: 32
            radius: 8
            color: btScanArea.pressed ? shell.green : btScanArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: shell.bluetoothScanning ? ("Scan" + (shell.bluetoothScanTick % 3 === 0 ? "." : shell.bluetoothScanTick % 3 === 1 ? ".." : "...")) : "Scan"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: btScanArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: shell.startBluetoothScan()
            }
        }
    }

    Text {
        text: shell.bluetoothListStatus
        color: shell.grey1
        font.pixelSize: 11
    }

    Rectangle {
        width: parent.width
        height: 550
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        ListView {
            visible: !shell.bluetoothScanning && btModel.count > 0
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            spacing: 6
            model: btModel

            delegate: Rectangle {
                required property string address
                required property bool connected
                required property string name

                width: ListView.view.width
                height: 36
                radius: 7
                color: connected ? "#384B55" : shell.bg2

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: name + " (" + address + ")"
                    color: shell.fg
                    font.pixelSize: 11
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 92
                    height: 24
                    radius: 6
                    color: btConnArea.pressed ? shell.green : btConnArea.containsMouse ? shell.bg3 : shell.bg0

                    Text {
                        anchors.centerIn: parent
                        text: connected ? "Disconnect" : "Connect"
                        color: shell.fg
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: btConnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            shell.connectBluetooth(address, connected)
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
            visible: shell.bluetoothScanning || btModel.count === 0
            text: shell.bluetoothScanning ? ("Scanning Bluetooth" + (shell.bluetoothScanTick % 3 === 0 ? "." : shell.bluetoothScanTick % 3 === 1 ? ".." : "...")) : shell.bluetoothListStatus
            color: shell.grey1
            font.pixelSize: 12
        }
    }
}
