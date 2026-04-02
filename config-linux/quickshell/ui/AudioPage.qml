import QtQuick
import QtQuick.Controls

Column {
    required property var shell
    required property var sinksModel
    spacing: 12

    Rectangle {
        width: parent.width
        height: 120
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Row {
                width: parent.width
                spacing: 8
                Text {
                    width: 118
                    text: "Output " + shell.audioVolume + "%"
                    color: shell.fg
                    font.pixelSize: 11
                }

                Slider {
                    width: Math.max(120, parent.width - 118 - 80 - 16)
                    from: 0
                    to: 100
                    value: shell.audioVolume
                    onMoved: shell.audioVolume = Math.round(value)
                    onPressedChanged: {
                        if (!pressed) {
                            shell.audioVolume = Math.round(value)
                            shell.setAudioVolume(Math.round(value))
                        }
                    }
                }

                Rectangle {
                    width: 80
                    height: 26
                    radius: 6
                    color: outputMuteArea.pressed ? shell.green : outputMuteArea.containsMouse ? shell.bg3 : shell.bg2
                    Text {
                        anchors.centerIn: parent
                        text: shell.audioMuted ? "Unmute" : "Mute"
                        color: shell.fg
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: outputMuteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            shell.toggleAudioMute()
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8
                Text {
                    width: 118
                    text: "Mic " + shell.micVolume + "%"
                    color: shell.fg
                    font.pixelSize: 11
                }

                Slider {
                    width: Math.max(120, parent.width - 118 - 80 - 16)
                    from: 0
                    to: 100
                    value: shell.micVolume
                    onMoved: shell.micVolume = Math.round(value)
                    onPressedChanged: {
                        if (!pressed) {
                            shell.micVolume = Math.round(value)
                            shell.setMicVolume(Math.round(value))
                        }
                    }
                }

                Rectangle {
                    width: 80
                    height: 26
                    radius: 6
                    color: micMuteArea.pressed ? shell.green : micMuteArea.containsMouse ? shell.bg3 : shell.bg2
                    Text {
                        anchors.centerIn: parent
                        text: shell.micMuted ? "Unmute" : "Mute"
                        color: shell.fg
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: micMuteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            shell.toggleMicMute()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 430
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        ListView {
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            spacing: 6
            model: sinksModel

            delegate: Rectangle {
                required property string name
                required property string description
                required property int volume

                width: ListView.view.width
                height: 36
                radius: 7
                color: shell.defaultSink === name ? "#3C4841" : shell.bg2

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: description + " (" + volume + "%)"
                    color: shell.fg
                    font.pixelSize: 11
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    height: 24
                    radius: 6
                    color: sinkUseArea.pressed ? shell.green : sinkUseArea.containsMouse ? shell.bg3 : shell.bg0

                    Text {
                        anchors.centerIn: parent
                        text: shell.defaultSink === name ? "Using" : "Use"
                        color: shell.fg
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: sinkUseArea
                        anchors.fill: parent
                        enabled: shell.defaultSink !== name
                        hoverEnabled: true
                        onClicked: {
                            shell.doSetDefaultSink(name)
                            shell.setStatus("Default output set")
                        }
                    }
                }
            }
        }
    }
}
