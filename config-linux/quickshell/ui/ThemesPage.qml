import QtQuick

Column {
    required property var shell
    required property var themesListModel
    required property var backgroundsModel
    spacing: 10

    Row {
        spacing: 8

        Rectangle {
            width: 86
            height: 32
            radius: 8
            color: themesRefreshArea.pressed ? shell.green : themesRefreshArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: "Refresh"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: themesRefreshArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: shell.refreshThemesData()
            }
        }

        Rectangle {
            width: 106
            height: 32
            radius: 8
            color: shell.selectedTheme === "" ? shell.bg1 : themeApplyArea.pressed ? shell.green : themeApplyArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: "Set Theme"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: themeApplyArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: shell.selectedTheme !== ""
                onClicked: {
                    shell.applySelectedTheme()
                }
            }
        }

        Rectangle {
            width: 140
            height: 32
            radius: 8
            color: shell.selectedBackgroundPath === "" ? shell.bg1 : bgApplyArea.pressed ? shell.green : bgApplyArea.containsMouse ? shell.bg3 : shell.bg2
            Text {
                anchors.centerIn: parent
                text: "Set Background"
                color: shell.fg
                font.pixelSize: 11
            }
            MouseArea {
                id: bgApplyArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: shell.selectedBackgroundPath !== ""
                onClicked: shell.setSelectedBackground()
            }
        }
    }

    Text {
        text: shell.themesStatus
        color: shell.grey1
        font.pixelSize: 11
    }

    Rectangle {
        width: parent.width
        height: 542
        radius: 10
        color: shell.bg1
        border.width: 1
        border.color: shell.bg3

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Rectangle {
                width: 220
                height: parent.height
                radius: 8
                color: shell.bg2
                border.width: 1
                border.color: shell.bg3

                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    spacing: 6
                    model: themesListModel

                    delegate: Rectangle {
                        required property string name
                        required property bool isCurrent
                        width: ListView.view.width
                        height: 34
                        radius: 7
                        color: shell.selectedTheme === name ? "#3C4841" : themeArea.pressed ? shell.green : themeArea.containsMouse ? shell.bg3 : shell.bg0

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: name + (isCurrent ? "  (current)" : "")
                            color: shell.fg
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: themeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: shell.requestThemeBackgrounds(name)
                        }
                    }
                }
            }

            Rectangle {
                width: Math.max(220, parent.width - 230)
                height: parent.height
                radius: 8
                color: shell.bg2
                border.width: 1
                border.color: shell.bg3

                Item {
                    anchors.fill: parent
                    anchors.margins: 10

                    Text {
                        id: selectedThemeLabel
                        text: shell.selectedTheme === "" ? "No theme selected" : ("Theme: " + shell.selectedTheme)
                        color: shell.fg
                        font.pixelSize: 12
                    }

                    GridView {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: selectedThemeLabel.bottom
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 8
                        clip: true
                        cellWidth: 188
                        cellHeight: 132
                        model: backgroundsModel

                        delegate: Rectangle {
                            required property string path
                            width: 178
                            height: 122
                            radius: 8
                            color: shell.bg0
                            border.width: shell.selectedBackgroundPath === path || shell.currentBackgroundPath === path ? 2 : 1
                            border.color: shell.selectedBackgroundPath === path ? shell.aqua : (shell.currentBackgroundPath === path ? shell.green : shell.bg3)

                            Image {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: setBgButton.top
                                anchors.margins: 6
                                anchors.bottomMargin: 4
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                source: path === "__NO_BACKGROUNDS__" ? "" : ("file://" + encodeURI(path))
                            }

                            Rectangle {
                                id: setBgButton
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 6
                                width: 44
                                height: 22
                                radius: 6
                                color: setBgArea.pressed ? shell.green : setBgArea.containsMouse ? shell.bg3 : shell.bg2

                                Text {
                                    anchors.centerIn: parent
                                    text: "Set"
                                    color: shell.fg
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: setBgArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: path !== "__NO_BACKGROUNDS__"
                                    onClicked: {
                                        shell.selectedBackgroundPath = path
                                        shell.setSelectedBackground()
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: path !== "__NO_BACKGROUNDS__"
                                onClicked: shell.selectedBackgroundPath = path
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        visible: backgroundsModel.count === 0 || (backgroundsModel.count === 1 && backgroundsModel.get(0).path === "__NO_BACKGROUNDS__")
                        text: shell.selectedTheme === "" ? "Select a theme to preview its backgrounds" : "No backgrounds in this theme"
                        color: shell.grey1
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
