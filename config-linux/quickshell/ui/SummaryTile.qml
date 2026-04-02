import QtQuick

Rectangle {
    id: root

    required property string icon
    required property string title
    required property string subtitle
    required property color fg
    required property color muted

    width: 160
    height: 66
    radius: 8
    color: "transparent"

    Column {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        Text {
            text: root.icon + "  " + root.title
            color: root.fg
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Text {
            text: root.subtitle
            color: root.muted
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
