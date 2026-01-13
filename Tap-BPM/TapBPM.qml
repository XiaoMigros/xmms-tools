import QtQuick
import QtQuick.Layouts

import MuseScore 3.0
import Muse.UiComponents 1.0 as MU
import Muse.Ui 1.0

MuseScore {
    id: root
    title: qsTr("Tap BPM")
    description: qsTr("Select a tempo marking, and tap the BPM!")
    version: "4.6"
    requiresScore: true
    pluginType: "dialog"

    readonly property int spacing: 10
    property var tempoElement: false
    property var tapEvents: []
    property bool shifted: false

    //============
    //  Settings
    //============
    property int displayDecPlaces: 2 //  Number of decimal places to display in plugin window
    property int timeOutLimit: 10    //  Seconds after which BPM stops being counted

    Timer {
        id: timeFind
        interval: 33
        triggeredOnStart: true
        repeat: true
        running: true
        onTriggered: {
            if (curScore.selection.elements && curScore.selection.elements[0].type == Element.TEMPO_TEXT) {
                tempoElement = curScore.selection.elements[0]
                stop()
            } else {
                var cursor = curScore.newCursor()
                cursor.inputStateMode = Cursor.INPUT_STATE_SYNC_WITH_SCORE
                if (cursor.segment) {
                    for (var e of cursor.segment.annotations) {
                        if (e.type == Element.TEMPO_TEXT) {
                            tempoElement = e
                            stop()
                            return
                        }
                    }
                }
            }
        }
    }

    height: 200
    width: 294

    ColumnLayout {
        visible: tempoElement
        spacing: root.spacing
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: root.spacing
        }

        Row {
            spacing: root.spacing
            anchors.horizontalCenter: parent.horizontalCenter
            height: childrenRect.height

            MU.StyledTextLabel {
                anchors.verticalCenter: parent.verticalCenter
                //font.bold: true
                text: qsTr("Current BPM:")
            }

            MU.TextInputField {
                id: bpmField
                implicitWidth: 90
                hint: qsTr("Tap away...")
                onTextEdited: root.addTapEvent()
            }

            MU.FlatButton {
                icon: IconCode.UNDO
                enabled: bpmField.currentText.length
                onClicked: root.resetTapEvents()
            }
        }
        Row {
            spacing: root.spacing
            anchors.horizontalCenter: parent.horizontalCenter
            height: childrenRect.height

            MU.StyledTextLabel {
                text: qsTr("Round to")
                anchors.verticalCenter: parent.verticalCenter
            }

            MU.IncrementalPropertyControl {
                id: rounding
                implicitWidth: 60
                step: 1
                minValue: 0
                maxValue: 2
                decimals: 0
                currentValue: 0
                onValueEdited: newValue => currentValue = newValue
            }

            MU.StyledTextLabel {
                text: qsTr("decimal places")
                font: ui.theme.bodyFont
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MU.FlatButton {
            id: tapButton
            accentButton: true
            text: qsTr("Tap!")
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: root.addTapEvent()
        }

        MU.StyledTextLabel {
            text: qsTr("Hint: Click the button or type in the text field")
            anchors.horizontalCenter: parent.horizontalCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.margins: root.spacing
            spacing: root.spacing


            MU.FlatButton {
                text: qsTr("Cancel")
                onClicked: smartQuit()
            }

            MU.FlatButton {
                text: qsTr("Apply")
                accentButton: true
                onClicked: writeTempo()
            }
        }
    }

    MU.StyledTextLabel {
        visible: !tempoElement
        anchors.centerIn: parent
        text: qsTr("Please select a BPM marking!")
    }


    function addTapEvent() {
        tapEvents.push(Date.now())
        timeOut.restart()

        if (tapEvents.length <= 1) {
            bpmField.currentText = ""
            return
        }

        if (!shifted && tapEvents.length > 4) {
            tapEvents.shift()
            shifted = true
        }

        var calcBPM = (tapEvents.length - 1) * 60000 / (tapEvents[tapEvents.length - 1] - tapEvents[0])
        bpmField.currentText = calcBPM.toFixed(displayDecPlaces).toString()
    }

    function resetTapEvents() {
        tapEvents = []
        bpmField.currentText = ""
    }

    Timer {
        id: timeOut
        interval: root.timeOutLimit * 1000
        onTriggered: root.resetTapEvents()
    }

    function writeTempo() {
        curScore.startCmd("Apply tapped tempo")
        //tempoElement.text = tempoElement.text.replace (/= \b\d+\b/g, "= " + bpmField.currentText)
        var bpmLocateRegEx = /=[^="]*?(\d*(\.|,))?\d+/g
        var locatedBPMstring = tempoElement.text.match(bpmLocateRegEx)[0]
        locatedBPMstring = locatedBPMstring.replace(/(\d*(\.|,))?\d+/g, parseFloat(bpmField.currentText).toFixed(parseInt(rounding.currentValue)).toString())
        tempoElement.text = tempoElement.text.replace(bpmLocateRegEx, locatedBPMstring)
        if (tempoElement.tempoFollowText) {
            tempoElement.tempoFollowText = false
            tempoElement.tempoFollowText = true
        }
        curScore.endCmd()
        smartQuit()
    }

    function smartQuit() {
        timeOut.stop()
        quit()
    }

    Settings {
        category: "Tap BPM Plugin"
        property alias rounding: rounding.currentValue
    }
}//MuseScore
