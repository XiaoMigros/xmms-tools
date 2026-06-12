import QtQuick
import QtQuick.Layouts

import Muse.Ui
import Muse.UiComponents as MU

import MuseScore 3.0

MuseScore {
    version: "4.7"
    title: qsTr("Master Positioner")
    description: qsTr("Modify positions of items using global values and see exact positions for line handles.")
    pluginType: "dialog"
    categoryCode: "Engraving"
    // thumbnailName: "modal_tuning.png"
    id: root
    width: 300
    height: 480
    requiresScore: true

    readonly property int defaultSpacing: 12

    readonly property var objectModel: [
        { "propertyName": "offset",    "displayName": qsTr("Base position") },
        { "propertyName": "userOff2",  "displayName": qsTr("Line end position") },
        { "propertyName": "slurUoff1", "displayName": qsTr("Slur control point 1 position") },
        { "propertyName": "slurUoff2", "displayName": qsTr("Slur control point 2 position") },
        { "propertyName": "slurUoff3", "displayName": qsTr("Slur control point 3 position") },
        { "propertyName": "slurUoff4", "displayName": qsTr("Slur control point 4 position") },
    ]

    property int unit: 0
    readonly property var unitModel: ["Spatiums", "Milimetres", "Inches"]
    readonly property var inch: 25.4 // engraving::INCH
    property int decimals: 2
    property bool cornerMode: false

    property var element: false
    property bool elementIsLine: false
    property bool elementIsSlurTie: false

    // UI
    Item {
        anchors.fill: parent

        MU.StyledFlickable {
            id: propertiesFlickable
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: defaultSpacing
            height: 360
            focus: true

            contentWidth: Math.max(contentLayout.implicitWidth, propertiesFlickable.width)
            contentHeight: contentLayout.implicitHeight

            Column {
                id: contentLayout
                width: parent.width
                height: implicitHeight
                spacing: defaultSpacing

                MU.StyledTextLabel {
                    width: parent.width
                    text: qsTr("Note: Support for slurs is limited due to inaccurate API values.")
                    wrapMode: Text.Wrap
                    visible: root.elementIsSlurTie
                    horizontalAlignment: Text.AlignLeft
                }

                Repeater {
                    id: propertiesList
                    model: objectModel

                    Column {
                        id: propertyItem

                        // anchors.left: parent ? parent.left : undefined
                        // anchors.right: parent ? parent.right : undefined
                        // anchors.rightMargin: defaultSpacing + propertiesFlickable.visualScrollBarInset

                        width: propertiesFlickable.width
                        spacing: defaultSpacing

                        property var value: undefined
                        visible: value !== undefined

                        RowLayout {
                            height: childrenRect.height
                            width: parent.width
                            spacing: defaultSpacing

                            MU.StyledTextLabel {
                                text: modelData.displayName
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                            }

                            MU.FlatButton {
                                icon: IconCode.UNDO
                                onClicked: {
                                    root.propertyReset(modelData.propertyName)
                                    root.refresh()
                                }
                            }
                        }

                        Row {
                            id: row
                            height: childrenRect.height
                            width: parent.width
                            spacing: defaultSpacing


                            MU.IncrementalPropertyControl {
                                id: horizontalOffsetControl

                                width: row.width / 2 - row.spacing / 2

                                decimals: root.decimals
                                step: 1
                                minValue: -9999
                                maxValue: 9999

                                icon: IconCode.HORIZONTAL

                                isIndeterminate: propertyItem.value === undefined
                                enabled: !isIndeterminate
                                currentValue: !isIndeterminate ? propertyItem.value.x : 0
                                measureUnitsSymbol: root.currentUnit(root.unit)

                                onValueEditingFinished: function(newValue) {
                                    root.propertyChangedX(modelData.propertyName, newValue - currentValue)
                                    root.refresh()
                                }
                            }

                            MU.IncrementalPropertyControl {
                                id: verticalOffsetControl

                                width: row.width / 2 - row.spacing / 2

                                icon: IconCode.VERTICAL

                                decimals: root.decimals
                                step: 1
                                minValue: -9999
                                maxValue: 9999

                                isIndeterminate: propertyItem.value === undefined
                                enabled: !isIndeterminate
                                currentValue: !isIndeterminate ? propertyItem.value.y : 0
                                measureUnitsSymbol: root.currentUnit(root.unit)

                                onValueEditingFinished: function(newValue) {
                                    root.propertyChangedY(modelData.propertyName, newValue - currentValue)
                                    root.refresh()
                                }
                            }
                        }

                        MU.SeparatorLine { /* visible: index + 1 < propertiesList.model.length */ }
                    }
                }

                MU.StyledTextLabel {
                    horizontalAlignment: Text.AlignLeft
                    width: parent.width
                    text: qsTr("Bounding box position:")
                    visible: !!root.element
                }

                Rectangle {
                    radius: 3
                    color: ui.theme.backgroundSecondaryColor
                    width: parent.width
                    height: 120
                    visible: !!root.element

                    GridLayout {
                        visible: !root.cornerMode
                        rowSpacing: defaultSpacing
                        columnSpacing: defaultSpacing
                        columns: 3
                        anchors.fill: parent
                        anchors.margins: defaultSpacing

                        Item { }

                        MU.StyledTextLabel {
                            id: bboxTopText
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item { }

                        MU.StyledTextLabel {
                            id: bboxLeftText
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { }

                        MU.StyledTextLabel {
                            id: bboxRightText
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
                        }

                        Item { }

                        MU.StyledTextLabel {
                            id: bboxBottomText
                            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Item { }
                    }

                    Rectangle {
                        visible: root.cornerMode
                        width: 1
                        height: parent.height
                        color: ui.theme.strokeColor
                        anchors.centerIn: parent
                    }

                    Rectangle {
                        visible: root.cornerMode
                        width: parent.width
                        height: 1
                        color: ui.theme.strokeColor
                        anchors.centerIn: parent
                    }

                    GridLayout {
                        visible: root.cornerMode
                        rowSpacing: defaultSpacing
                        columnSpacing: defaultSpacing
                        columns: 2
                        anchors.fill: parent
                        anchors.margins: defaultSpacing

                        MU.StyledTextLabel {
                            id: topLeftText
                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            Layout.fillWidth: true
                        }

                        MU.StyledTextLabel {
                            id: topRightText
                            Layout.alignment: Qt.AlignTop | Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }

                        MU.StyledTextLabel {
                            id: bottomLeftText
                            Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            Layout.fillWidth: true
                        }

                        MU.StyledTextLabel {
                            id: bottomRightText
                            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: root.cornerMode = !root.cornerMode
                    }
                }
            }
        }

        Rectangle {
            height: 24
            anchors.top: propertiesFlickable.top
            anchors.left: propertiesFlickable.left
            anchors.right: propertiesFlickable.right
            // anchors.rightMargin: scrollBar.width
            visible: !propertiesFlickable.atYBeginning
            gradient: Gradient {
                GradientStop {position: 0.0; color: ui.theme.backgroundPrimaryColor }
                GradientStop {position: 1.0; color: "transparent"}
            }
        }

        Rectangle {
            height: 24
            anchors.left: propertiesFlickable.left
            anchors.right: propertiesFlickable.right
            // anchors.rightMargin: scrollBar.width
            anchors.bottom: propertiesFlickable.bottom
            visible: !propertiesFlickable.atYEnd
            gradient: Gradient {
                GradientStop {position: 0.0; color: "transparent"}
                GradientStop {position: 1.0; color: ui.theme.backgroundPrimaryColor}
            }
        }

        GridLayout {
            rowSpacing: defaultSpacing
            columnSpacing: defaultSpacing
            columns: 2
            anchors.top: propertiesFlickable.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: defaultSpacing

            MU.StyledTextLabel {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
                text: qsTr("Unit:")
            }

            MU.StyledDropdown {
                id: unitDropdown
                model: unitModel
                currentIndex: root.unit
                onActivated: function(index, value) {
                    root.unit = index
                    root.refresh()
                }
            }

            MU.StyledTextLabel {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
                text: qsTr("Decimals:")
            }

            MU.IncrementalPropertyControl {
                id: decimalsControl

                Layout.maximumWidth: unitDropdown.width

                decimals: 0
                step: 1
                minValue: 0
                maxValue: 4

                currentValue: root.decimals

                onValueEditingFinished: function(newValue) {
                    root.decimals = newValue
                    refresh()
                }
            }
        }
    }

    // Units and conversion
    function currentUnit(unitType) {
        switch (unitType) {
            case 0:
                return "sp"
            case 1:
                return "mm"
            case 2:
                return "in"
        }
        return ""
    }

    function valueFromLocalSp(value) {
        if (root.unit == 0) {
            value *= root.element.spatium
            value /= curScore.spatium
        } else {
            value *= root.element.spatium
            value /= mscoreDPI
            if (root.unit == 1) {
                value *= root.inch
            }
        }
        return value
    }

    function valueInLocalSp(value) {
        if (root.unit == 0) {
            value *= curScore.spatium
            value /= root.element.spatium
        } else {
            if (root.unit == 1) {
                value /= root.inch
            }
            value *= mscoreDPI
            value /= root.element.spatium
        }
        return value
    }

    // Properties
    function valueForProperty(propertyName) {
        var element = root.element
        if (!element) {
            return undefined
        }

        if (propertyName != "offset") {
            if (root.elementIsSlurTie || root.elementIsLine) {
                if ((propertyName == "userOff2") == root.elementIsSlurTie) {
                    return undefined
                }
            } else {
                return undefined
            }
        }

        // Fallback check
        if (typeof element[propertyName] === "undefined" || element[propertyName] == undefined) {
            return undefined
        }
        var perDim = function(d) {
            var pt = element.pagePos[d]
            switch (propertyName) {
                case "offset":
                    break
                case "userOff2":
                    pt += element.pos2[d]
                    break
                /// @todo proper accounting for slur control points (not exposed in API)
                default:
                    pt += element[propertyName][d]
                    break
            }
            return valueFromLocalSp(pt)
        }
        return Qt.point(perDim("x"), perDim("y"))
    }

    function propertyChangedX(propertyName, value) {
        curScore.startCmd(qsTr("Edit %1").arg(propertyName))
        root.element[propertyName].x += valueInLocalSp(value)
        curScore.endCmd()
    }

    function propertyChangedY(propertyName, value) {
        curScore.startCmd(qsTr("Edit %1").arg(propertyName))
        root.element[propertyName].y += valueInLocalSp(value)
        if (propertyName == "userOff2") {
            root.element.diagonal = true
        }
        curScore.endCmd()
    }

    function propertyReset(propertyName) {
        curScore.startCmd(qsTr("Reset %1").arg(propertyName))
        root.element[propertyName] = undefined
        if (propertyName == "userOff2" && root.element.diagonal) {
            root.element.diagonal = undefined
        }
        curScore.endCmd()
    }

    // Non-bindable properties
    onRun: {
        updateTimer.start()
    }

    function refresh() {
        if (root.element) {
            root.elementIsSlurTie = /Slur/gm.test(root.element.name) || /Tie/gm.test(root.element.name) || /HammerOnPullOff/gm.test(root.element.name)
            root.elementIsLine = !root.elementIsSlurTie && /([A-z])+?Segment$/gm.test(root.element.name)

            var topLeftPt = Qt.point(valueFromLocalSp(root.element.pagePos.x + root.element.bbox.x), valueFromLocalSp(root.element.pagePos.y + root.element.bbox.y))
            var bottomRightPt = Qt.point(topLeftPt.x + valueFromLocalSp(root.element.bbox.width), topLeftPt.y + valueFromLocalSp(root.element.bbox.height))
            // sides
            bboxTopText.text = "%1%2".arg(Number(topLeftPt.y).toFixed(root.decimals)).arg(currentUnit(root.unit))
            bboxLeftText.text = "%1%2".arg(Number(topLeftPt.x).toFixed(root.decimals)).arg(currentUnit(root.unit))
            bboxRightText.text = "%1%2".arg(Number(bottomRightPt.x).toFixed(root.decimals)).arg(currentUnit(root.unit))
            bboxBottomText.text = "%1%2".arg(Number(bottomRightPt.y).toFixed(root.decimals)).arg(currentUnit(root.unit))
            // corners
            topLeftText.text = "%1 / %2".arg(bboxLeftText.text).arg(bboxTopText.text)
            topRightText.text = "%1 / %2".arg(bboxRightText.text).arg(bboxTopText.text)
            bottomLeftText.text = "%1 / %2".arg(bboxLeftText.text).arg(bboxBottomText.text)
            bottomRightText.text = "%1 / %2".arg(bboxRightText.text).arg(bboxBottomText.text)
        } else {
            root.elementIsLine = false
            root.elementIsSlurTie = false
        }
        for (var i in propertiesList.model) {
            propertiesList.itemAt(i).value = root.valueForProperty(propertiesList.model[i].propertyName)
        }
    }

    Timer {
        id: updateTimer
        interval: 33 // ms
        repeat: true
        onTriggered: {
            var oldElement = root.element
            if (curScore && curScore.selection.elements.length > 0) {
                root.element = curScore.selection.elements[0]
                if (!oldElement || !root.element.is(oldElement)) {
                    refresh()
                }
            } else {
                root.element = false
                refresh()
            }
        }
    }

    Settings {
        id: options
        category: "MasterPositioner"
        property alias unit: root.unit
        property alias decimals: root.decimals
        property alias cornerMode: root.cornerMode
    }
}
