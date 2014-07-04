import QtQuick 2.2
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Window {
    visible: true
    width: 700
    height: 500
    title: "Cryptonote Easy Miner"
    color: "honeydew"

    TabView {
        anchors.fill: parent
        id: tabView
        style: TabViewStyle {
            tab: Rectangle { }
            tabsMovable: true
        }

        Component.onCompleted: {
            addTab("Mining", Qt.createComponent("mining.qml"));
        }
    }
}
