import QtQuick 2.2
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1

Window {
    property string apiUrl: ''
    property string mineUrl: ''
    property bool minerRunning: false
    property real lastHashrate: 0
    property real currentDifficulty: 0
    property int hashesSubmitted: 0
    property date lastWorkUpdate: new Date(0)

    Connections {
        target: applicationData
        onMinerStarted: {
            minerRunning = true;
            currentDifficulty = 0;
            hashesSubmitted = 0;
        }
        onMinerStopped: {
            minerRunning = false;
            lastHashrate = 0;
        }
        onWorkReceived: lastWorkUpdate = new Date()
        onHashrateUpdated: lastHashrate = hashrate
        onDifficultyUpdated: currentDifficulty = difficulty
        onShareSubmitted: hashesSubmitted += difficulty
    }

    function getThreadSelectionModel(num) {
        if(num < 1) {
            return ['Invalid number of threads!'];
        }

        var ret = [];
        for(var i = 1; i <= num; ++i) {
            ret.push(i === num ? i + ' (max)' : i.toString());
        }
        return ret;
    }

    function cleanUrl(url) {
        var i = url.indexOf('//');
        if(i !== -1) {
            url = url.substr(i + 2);
        }
        while(url[url.length - 1] === '/') {
            url = url.substr(0, url.length - 1);
        }
        return url;
    }

    function httpGet(url, callback) {
        var xhr = new XMLHttpRequest;
        xhr.open('GET', url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if(xhr.status !== 200) {
                    callback(qsTr('Response code: ') + xhr.status)
                } else {
                    callback(null, xhr.responseText);
                }
            }
        }
        xhr.send();
    }

    function getApiUrl(url, callback) {
        if(url.indexOf('//') === -1) {
            url = 'http://' + url;
        }

        httpGet(url, function(err, body) {
            if(err) return callback(err);
            var index = body.indexOf('var api = ');
            if(index !== -1) {
                while(body[index] !== '\'' && body[index] !== '"') {
                    ++index;
                }
                var end = body.indexOf(body[index], index + 1);
                if(end === -1) {
                    return callback(qsTr('Unable to parse api url'));
                }
                var apiUrl = body.substr(index + 1, end - index - 1);
                while(apiUrl[apiUrl.length - 1] === '/') {
                    apiUrl.substr(0, apiUrl.length - 1);
                }

                return callback(null, apiUrl);
            }
            callback(qsTr('Unable to parse api url'));
        });
    }

    function resetPoolData() {
        addressInfoPanel.Layout.preferredHeight = 0;
        poolPortListWidthAnimation.enabled = true;
        poolPortList.width = 0;
        poolPortListWidthAnimation.enabled = false;
        poolName.text = '';
        apiUrl = '';
        mineUrl = '';
        poolPortModel.clear();
    }

    function updateApiInfo() {
        var url = apiUrl + '/stats';
        console.log('Getting stats from ' + url + ' ...');
        httpGet(url, function(err, res) {
            var data;
            if(err || !((data = JSON.parse(res)) && data.config && data.config.ports)) {
                resetPoolData();
                return console.error(err);
            }
            poolPortModel.clear();
            for(var i = 0; i < data.config.ports.length; ++i) {
                poolPortModel.append(data.config.ports[i]);
            }
            poolPortListWidthAnimation.enabled = true;
            poolPortList.width = 240;
            poolPortListWidthAnimation.enabled = false;
            poolName.text = cleanUrl(poolUrl.text);
            mineUrl = data.config.poolHost;
            console.log('Got stats!');
        });
    }

    function updateAddressInfo() {
        var address = minerAddress.text;
        if(address.length < 95  || apiUrl === '' || poolUrl.text === '') {
            addressInfoPanel.Layout.preferredHeight = 0;
            return;
        }

        var url = apiUrl + '/stats_address?address=' + minerAddress.text + '&longpoll=false'
        console.log('Getting stats from ' + url + ' ...');
        httpGet(url, function(err, res) {
            if(err) {
                addressInfoPanel.Layout.preferredHeight = 0;
                return console.error(err);
            }

            var data = JSON.parse(res);
            if(!data.stats || data.error) {
                addressInfoPanel.Layout.preferredHeight = 0;
                return console.error(data.error || 'Invalid response');
            }
            console.log('Got address info!');
            addressInfoPanel.address = address;
            addressInfoPanel.stats = data.stats;
            addressInfoPanel.Layout.preferredHeight = 100;
        });
    }

    Timer {
        id: addressInfoTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: updateAddressInfo()
    }

    function getApiInfo() {
        var pUrl = poolUrl.text;
        console.log('Retreiving api url from ' + pUrl + ' ...');
        getApiUrl(pUrl, function(err, url) {
            if(err) {
                resetPoolData();
                return console.error(err);
            }
            console.log('Got api url: ' + url);
            apiUrl = url;
            updateApiInfo();
            updateAddressInfo();
        });
    }

    Timer {
        id: apiInfoTimeout
        interval: 500
        repeat: false
        running: false
        onTriggered: getApiInfo()
    }

    visible: true
    width: 700
    height: 500
    title: 'CryptoNote Easy Miner'
    color: '#fff'

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        GridLayout {
            id: controls
            columns: 2

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            Layout.fillHeight: false
            Layout.fillWidth: true

            Text {
                text: qsTr('Your Address:')
            }
            TextField {
                id: minerAddress
                Layout.fillWidth: true
                placeholderText: '48Y4SoUJM5L3YXBEfNQ8bFNsvTNsqcH5Rgq8RF7BwpgvTBj2xr7CmWVanaw7L4U9MnZ4AG7U6Pn1pBhfQhFyFZ1rL1efL8z'
                onTextChanged: updateAddressInfo()
            }
            Text {
                text: qsTr('Pool URL:')
            }
            TextField {
                id: poolUrl
                Layout.fillWidth: true
                placeholderText: ''
                onTextChanged: apiInfoTimeout.restart()
            }
        }

        Text {
            id: poolName
            Layout.fillWidth: true
            height: 30
            font.bold: true
            font.pixelSize: 30
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 0
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 500 }
            }
            id: addressInfoPanel
            property string address: ''
            property var stats: {stats: ({})}
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Text {
                    text: '<b>' + addressInfoPanel.address + '</b>'
                    font.pixelSize: 10
                }
                Text {
                    text: 'Hashrate: <b>' + (addressInfoPanel.stats.hashrate || '0 H') + '/s</b> (est.)'
                }
                Text {
                    text: 'Paid: <b>' + addressInfoPanel.stats.paid + '</b>'
                }
                Text {
                    text: 'Pending balance: <b>' + addressInfoPanel.stats.balance + '</b>'
                }
                Text {
                    text: 'Hashes: <b>' + addressInfoPanel.stats.hashes + '</b>'
                }
            }
        }

        SplitView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            ListView {
                id: poolPortList
                Layout.fillHeight: true
                width: 0
                model: poolPortModel
                focus: true

                Behavior on width {
                    id: poolPortListWidthAnimation
                    NumberAnimation { duration: 500 }
                }

                highlight: Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: 'lightsteelblue'
                }
                delegate: Rectangle {
                    height: 30
                    width: parent.width
                    color: 'transparent'
                    MouseArea {
                        anchors.fill: parent
                        onClicked: poolPortList.currentIndex = index
                    }

                    RowLayout {
                        anchors.top: parent.top
                        anchors.margins: 4
                        Rectangle {
                            color: model.protocol === 'tcp' ? '#5cb85c' : '#f0ad4e'
                            radius: 4
                            width: childrenRect.width + 8
                            height: childrenRect.height + 8
                            Text {
                                text: model.protocol
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 4
                            }
                        }
                        Text {
                            text: model.desc + ' [' + model.difficulty + '] :' + model.port
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    Text {
                        font.bold: true
                        font.pixelSize: 20
                        text: (poolPortModel.get(poolPortList.currentIndex) || {}).desc || ''
                    }

                    RowLayout {
                        ColumnLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: 'Difficulty: ' + ((poolPortModel.get(poolPortList.currentIndex) || {}).difficulty || '')
                            }
                            Text {
                                Layout.fillWidth: true
                                text: 'Port: ' + ((poolPortModel.get(poolPortList.currentIndex) || {}).port || '')
                            }
                            ComboBox {
                                id: numMinerThreads
                                model: getThreadSelectionModel(applicationData.numThreads())
                                Layout.preferredWidth: 85
                            }
                            Button {
                                enabled: poolPortModel.count > 0
                                text: minerRunning ? 'Stop Mining' : 'Start Mining'
                                Layout.preferredWidth: 85
                                onClicked: minerRunning ?
                                               applicationData.stopCpuMiner() :
                                               applicationData.startCpuMiner(numMinerThreads.currentIndex + 1,
                                                                             poolPortModel.get(poolPortList.currentIndex).protocol,
                                                                             mineUrl,
                                                                             poolPortModel.get(poolPortList.currentIndex).port,
                                                                             minerAddress.text)
                            }
                        }
                        ColumnLayout {
                            Layout.minimumWidth: 220
                            Layout.maximumWidth: 220
                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                            Text {
                                text: 'AES-NI Supported: ' + (applicationData.cpuSupportsAES() ? '<b>YES</b>' : '<b>NO</b>')
                            }
                            Text {
                                text: 'Hashrate: <b>' + lastHashrate.toFixed(2) + ' H/s</b>'
                            }
                            Text {
                                text: 'Current difficulty: <b>' + currentDifficulty + '</b>'
                            }
                            Text {
                                text: 'Hashes submitted: <b>' + hashesSubmitted + '</b>'
                            }
                            Text {
                                text: 'Last work update: <b>' + lastWorkUpdate.toLocaleTimeString() + '</b>'
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        border.color: 'lightgrey'
                        Flickable {
                            id: minerOutputFlick
                            anchors.fill: parent
                            flickableDirection: Flickable.VerticalFlick

                            Behavior on contentY {
                                NumberAnimation {
                                    duration: 400
                                }
                            }

                            TextArea {
                                width: parent.width
                                height: parent.height
                                id: minerOutput
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                Connections {
                                    target: applicationData
                                    onMinerOutput: minerOutput.text += output
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: poolPortModel
    }
}
