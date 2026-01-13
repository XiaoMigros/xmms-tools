import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0

import MuseScore 3.0
import MuseScore.UiComponents 1.0 as MU
import MuseScore.Ui 1.0

MuseScore {
    id: root
    menuPath: "Plugins." + qsTr("Tap BPM")
    description: qsTr("Select a tempo marking, and tap the BPM!")
    version: "1.0"
    requiresScore: true

    readonly property int spacing: 10
    property var tempoElement: false
    property var tapEvents: []
    property bool shifted: false

    //============
    //  Settings
    //============
    property int displayDecPlaces: 2 //  Number of decimal places to display in plugin window
    property int timeOutLimit: 10    //  Seconds after which BPM stops being counted

    onRun: {
        if (curScore.selection.elements && curScore.selection.elements[0].type == Element.TEMPO_TEXT) {
            tempoElement = curScore.selection.elements[0]
        } else {
            var cursor = curScore.newCursor()
            cursor.inputStateMode = Cursor.INPUT_STATE_SYNC_WITH_SCORE
            if (cursor.segment) {
                for (var i in cursor.segment.annotations) {
                    if (cursor.segment.annotations[i].type == Element.TEMPO_TEXT) {
                        tempoElement = cursor.segment.annotations[i]
                        break
                    }
                }
            }
        }
        if (tempoElement) {
            dialog.show()
        } else {
            quit()
        }
    }

    ApplicationWindow {
        id: dialog
        height: 240
        width: 294
        minimumHeight: height
        maximumHeight: height
        minimumWidth: width
        maximumWidth: width
        title: qsTr("Tap BPM")
        flags: Qt.Dialog

        ColumnLayout {
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

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font: ui.theme.bodyBoldFont
                    //font.bold: true
                    text: qsTr("Current BPM:")
                }

                TextField {
                    id: bpmField
                    implicitWidth: 90
                    placeholderText: qsTr("Tap away...")
                    onTextEdited: root.addTapEvent()
                }
            }
            Row {
                spacing: root.spacing
                anchors.horizontalCenter: parent.horizontalCenter
                height: childrenRect.height

                Label {
                    text: qsTr("Round to")
                    font: ui.theme.bodyFont
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
                    onValueEdited: function(newValue) {currentValue = newValue}
                }

                Label {
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

            MU.FlatButton {
                text: qsTr("Reset")
                onClicked: root.resetTapEvents()
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: qsTr("Hint: Click the button or type in the text field")
                font: ui.theme.bodyFont
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        RowLayout {
            spacing: root.spacing
            anchors {
                margins: root.spacing
                bottom: parent.bottom
                right: parent.right
            }

            MU.FlatButton {
                text: qsTr("Cancel")
                onClicked: smartQuit()
            }

            MU.FlatButton {
                text: qsTr("Add to score")
                accentButton: true
                onClicked: writeTempo()
            }
        }
    }

    function addTapEvent() {
        tapEvents.push(Date.now())
        timeOut.restart()
        if (tapEvents.length > 1) {
            if (!shifted && tapEvents.length > 4) {
                tapEvents.shift()
                shifted = true
            }
            var calcBPM = (tapEvents.length - 1) * 60000 / (tapEvents[tapEvents.length-1] - tapEvents[0])
            bpmField.currentText = roundToPlaces(calcBPM, displayDecPlaces).toString()
        }
        else bpmField.currentText = ""
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

    function roundToPlaces(number, places) {
        return Math.round(number * Math.pow(10, places)) / Math.pow(10, places)
    }

    function writeTempo() {
        curScore.startCmd()
        //tempoElement.text = tempoElement.text.replace (/= \b\d+\b/g, "= " + bpmField.currentText)
        var bpmLocateRegEx = /=[^="]*?(\d*(\.|,))?\d+/g
        var locatedBPMstring = tempoElement.text.match(bpmLocateRegEx)[0]
        locatedBPMstring = locatedBPMstring.replace(/(\d*(\.|,))?\d+/g, roundToPlaces(parseFloat(bpmField.currentText), parseInt(rounding.currentValue)).toString())
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
        dialog.close()
        quit()
    }

    Settings {
        category: "Tap BPM Plugin"
        property alias rounding: rounding.currentValue
    }
}//MuseScore
