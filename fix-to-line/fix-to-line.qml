/*
 * Copyright (C) 2023 Marc Sabatella
 * Edited        2025 XiaoMigros
 */

import QtQuick 2.0
import MuseScore 3.0
import QtQuick.Layouts
import Muse.UiComponents 1.0 as MU
import Muse.Ui 1.0

MuseScore {
    title: qsTr("Fix to Line")
    categoryCode: "composing-arranging-tools"
    description: qsTr("This plugin allows you to fix notes to specific lines on a staff, irrespective of their pitch.")
    version:    "1.0.4"
    pluginType: "dialog"
    requiresScore: true

    function applyToNotesAndRestsInSelection(func, value) {
        if (!curScore) {
            return
        }
        for (var i in curScore.selection.elements) {
            var e = curScore.selection.elements[i]
            if (e.type == Element.NOTE) {
                // not currently supported for rests
                func(e, value)
            }
        }
    }

    function setFixed(noterest, fixed) {
        noterest.fixed = fixed
    }

    function setFixedLine(noterest, line) {
        noterest.fixedLine = line
    }

    width: childrenRect.width
    height: childrenRect.height

    ColumnLayout {
        id: content

        RowLayout {
            Layout.margins: 8

            MU.CheckBox {
                id: fix
                checked: true
                text: qsTr("Fix notes to line")
                onClicked: {
                    checked = !checked
                }
            }

            MU.IncrementalPropertyControl {
                Layout.maximumWidth: 60
                id: line
                enabled: fix.checked
                minValue: -99
                maxValue: 99
                currentValue: 0
                step: 1
                onValueEdited: function(newValue) {
                    currentValue = newValue
                }
            }
        }

        RowLayout {
            Layout.margins: 8
            Layout.alignment: Qt.AlignRight
            spacing: 8

            MU.FlatButton {
                text: qsTr("Cancel")
                onClicked: {
                    quit()
                }
            }

            MU.FlatButton {
                accentButton: true
                text: qsTr("OK")
                onClicked: {
                    curScore.startCmd("(Un)fix notes to line")
                    applyToNotesAndRestsInSelection(setFixed, fix.checked)
                    applyToNotesAndRestsInSelection(setFixedLine, line.currentValue)
                    curScore.endCmd()
                    quit()
                }
            }
        }
    }
}
