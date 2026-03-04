import Quickshell
import QtQuick
import "ui"

Scope {
    id: root

    property string page: "wifi"

    SettingsStore {
        id: store
    }

    Variants {
        model: Quickshell.screens

        FloatingWindow {
            required property var modelData
            title: "Settings"
            screen: modelData
            visible: store.initialScreenResolved && store.shouldShowOnScreen(modelData)
            implicitWidth: store.panelWidth
            implicitHeight: Math.max(640, store.screenHeight(modelData) - (store.windowGap * 2))
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: store.bg0
                radius: store.windowRadius
                border.width: store.windowBorder
                border.color: store.bg3
                clip: true

                Rectangle {
                    id: sidebar
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 176
                    color: store.bgDim
                    border.width: store.windowBorder
                    border.color: store.bg3

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "Settings"
                            color: store.fg
                            font.pixelSize: 19
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: store.bg3
                        }

                        Repeater {
                            model: [
                                { id: "general", label: "General", icon: "󰒓" },
                                { id: "wifi", label: "Wi-Fi", icon: "󰤨" },
                                { id: "bluetooth", label: "Bluetooth", icon: "" },
                                { id: "audio", label: "Audio", icon: "󰕾" },
                                { id: "themes", label: "Themes", icon: "󰸌" }
                            ]

                            Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 34
                                radius: 8
                                color: root.page === modelData.id ? store.bg3 : navArea.containsMouse ? store.bg2 : "transparent"

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: modelData.icon + "  " + modelData.label
                                    color: root.page === modelData.id ? store.fg : store.grey1
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: navArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.page = modelData.id
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: 1
                        }

                        Text {
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: store.settingsStatus
                            color: store.yellow
                            font.pixelSize: 10
                        }
                    }
                }

                Item {
                    anchors.left: sidebar.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 14
                        sourceComponent: {
                            if (root.page === "general")
                                return generalPage;
                            if (root.page === "wifi")
                                return wifiPage;
                            if (root.page === "bluetooth")
                                return bluetoothPage;
                            if (root.page === "audio")
                                return audioPage;
                            if (root.page === "themes")
                                return themesPage;
                            return generalPage;
                        }
                    }
                }
            }
        }
    }

    Component {
        id: generalPage
        GeneralPage {
            shell: store
        }
    }

    Component {
        id: wifiPage
        WifiPage {
            shell: store
            wifiModel: store.wifiModel
        }
    }

    Component {
        id: bluetoothPage
        BluetoothPage {
            shell: store
            btModel: store.btModel
        }
    }

    Component {
        id: audioPage
        AudioPage {
            shell: store
            sinksModel: store.sinksModel
        }
    }

    Component {
        id: themesPage
        ThemesPage {
            shell: store
            themesListModel: store.themesListModel
            backgroundsModel: store.backgroundsModel
        }
    }
}
