import QtQuick 2.2
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Window {
    visible: true
    width: 700
    height: 500
    title: "CryptoNote Easy Miner"
    color: "honeydew"

    TabView {
        anchors.fill: parent
        id: tabView
        style: TabViewStyle {
            tab: Rectangle {
                implicitWidth: text.width + 80
                implicitHeight: 30
                color: styleData.selected ? "paleturquoise" : "honeydew"
                Text {
                    id: text
                    anchors.centerIn: parent
                    font.pixelSize: 20
                    text: styleData.title
                    color: "black"
                }
            }
            tabsMovable: true
            frame: Rectangle { color: "steelblue" }
        }

        Component.onCompleted: {
            addTab("Mining", Qt.createComponent("mining.qml"));
            addTab("Wallet", Qt.createComponent("wallet.qml"));
        }
    }
}
