import QtQuick 2.0
import MuseScore 3.0
import QtQuick.Controls
import QtQuick.Layouts
import Muse.UiComponents 1.0 as MU
import Muse.Ui 1.0

MuseScore {
    title: qsTr("Evenly distribute systems across pages")
    description: qsTr("Evenly spreads systems across pages") + "\n" +
        qsTr("Requires MuseScore 4.6 or later ")
    version: "4.6"
    requiresScore: true

    pluginType: "dialog"

    readonly property int spacing: 8
    readonly property var spacingMode: ({
        WIDE: 0, REGULAR: 1, COMPACT: 2
    })

    property var pageBreak: false
    property var systemBreak: false
    property int nSystemsNoVBOX: 0

    width: childrenRect.width + 2 * spacing
    height: childrenRect.height + 2 * spacing

    onRun: {
        applyAutoSpacing.checked = curScore.style.value("enableVerticalSpread")
    }

    function runPlugin() {
        pageBreak = newElement(Element.LAYOUT_BREAK)
        pageBreak.layoutBreakType = LayoutBreak.PAGE

        systemBreak = newElement(Element.LAYOUT_BREAK)
        systemBreak.layoutBreakType = LayoutBreak.LINE

        nSystemsNoVBOX = getNoVBOXNumber(curScore)

        // Replace existing page breaks with line breaks, unless systems are locked
        for (var i in curScore.pages) {
            var system = curScore.pages[i].systems[curScore.pages[i].systems.length - 1]
            if (!system || !system.pageBreak) {
                continue
            }
            replacePageBreakWithLineBreakIfNeeded(system)
        }

        return applyLayout(calculateDistribution(nSystemsNoVBOX))
    }

    function findSystemsNoVBOX(number) {
        var skipped = number
        for (var i = 0; i <= skipped; ++i) {
            if (!curScore.systems[i].firstMeasure) {
                ++skipped;
            }
        }
        return skipped
    }

    function getNoVBOXNumber(object) {
        var n = 0
        for (var i in object.systems) {
            if (object.systems[i].firstMeasure) {
                ++n
            }
        }
        return n
    }

    function getFirstNonVBOXSystemOnPage(page) {
        var system = false
        for (var i in page.systems) {
            if (page.systems[i].firstMeasure) {
                system = page.systems[i]
                break
            }
        }
        var index = 0
        for (var i in curScore.systems) {
            if (curScore.systems[i].is(system)) {
                return index
            }
            if (curScore.systems[i].firstMeasure) {
                ++index
            }
        }
        return nSystemsNoVBOX // code will return
    }

    function replacePageBreakWithLineBreakIfNeeded(system) {
        for (var i in system.last.elements) {
            var element = system.last.elements[i]
            if (element.type == Element.LAYOUT_BREAK && element.layoutBreakType == LayoutBreak.PAGE) {
                removeElement(element)
                if (!system.isLocked) {
                    system.last.add(systemBreak.clone())
                }
            }
        }
    }

    function applyLayout(distribution) {
        var prevSystem = -1
        var successfullyModified = false
        for (var i in distribution) {
            if (distribution[i] >= nSystemsNoVBOX) {
                return // should never happen
            }
            // Remove any line breaks
            var system = curScore.systems[findSystemsNoVBOX(distribution[i])]
            if (!system) throw new Error("Can't find system for layout at index " + distribution[i])
            for (var j in system.last.elements) {
                var element = system.last.elements[j]
                if (element.type == Element.LAYOUT_BREAK && element.layoutBreakType == LayoutBreak.LINE) {
                    removeElement(element)
                }
            }
            // Add a page break
            if (!system.pageBreak) {
                system.last.add(pageBreak.clone())
            }

            if (i >= distribution.length - 1) {
                continue
            }

            // Layout the score to see if systems fit as desired (not working yet)
            curScore.doLayout(fraction(0, 1), fraction(-1, 1))
            // Systems are destroyed and recreated on layout
            system = curScore.systems[findSystemsNoVBOX(distribution[i])]
            // If systems don't fit on page, recalculate from given position
            if (getNoVBOXNumber(system.parent) != distribution[i] - prevSystem) {
                var firstNonVBOXSystemOnPage = getFirstNonVBOXSystemOnPage(system.parent)
                console.log("Can't fit systems, recalculating from system " + (firstNonVBOXSystemOnPage + 1))
                replacePageBreakWithLineBreakIfNeeded(system)
                return applyLayout(calculateDistribution(nSystemsNoVBOX, firstNonVBOXSystemOnPage))
            }
            successfullyModified = true
            prevSystem = distribution[i]
        }
        return successfullyModified
    }

    function calculateDistribution(nSystems, currentSystem = -1) {
        const minSPP = minSPPBox.currentValue
        const maxSPP = maxSPPBox.currentValue
        const maxSPP1 = maxSPP1Box.currentValue
        const wideSpacing = spacingModeList.currentValue == spacingMode.WIDE
        const compactSpacing = spacingModeList.currentValue == spacingMode.COMPACT
        const isFirst = currentSystem == -1

        var pageModel = [] // Array that contains the number of systems per page
        var remainingSystems = nSystems - currentSystem // Used to track unassigned systems

        // This is the lowest possible number of pages while respecting maxSPP and maxSPP1
        const minNPages = isFirst ? Math.ceil((Math.max(remainingSystems - maxSPP1, 0)) / maxSPP) + 1 : Math.ceil(remainingSystems / maxSPP)

        if (wideSpacing) {
            // Create as many pages as possible while respecting minimum number of systems
            const maxNPages = Math.max(Math.floor(remainingSystems / minSPP), minNPages)

            // This is the maximum amount of systems a page can possibly need
            const upperBound = Math.ceil(remainingSystems / maxNPages)

            for (var i = 0; i < maxNPages; i++) {
                pageModel.push(upperBound)
                remainingSystems -= pageModel[i]
            }

            // We may have added too many systems, so now we go back and remove them
            // First subtract from first page, then loop through backwards
            for (var i = isFirst ? 0 : 1; remainingSystems < 0; i++) {
                --pageModel[(maxNPages - i) % maxNPages]
                ++remainingSystems
            }
        } else {
            //respect maxSPP and maxSPP1 at all costs, but not minSPP

            // In an evenly-as-possibly distributed score, the minimum systems per page is this number
            const base = Math.floor(remainingSystems / minNPages)

            // On the first page, either put the smallest number of systems that doesn't affect page number, or the allowed maximum
            pageModel.push(isFirst ? Math.min(base, maxSPP1) : base)
            remainingSystems -= pageModel[0]

            // Add as many systems to the other pages as possible, provided they all have the same amount
            for (var i = 1; i < minNPages; i++) {
                pageModel.push(base)
                remainingSystems -= pageModel[i]
            }

            // Distribute the remaining systems (if any)
            for (var i = isFirst ? 1 : 0; remainingSystems > 0; i++) {
                ++pageModel[i % minNPages]
                --remainingSystems
            }

            // Compact spacing: Fill systems starting from the front until they reach the minimum,
            // but leave an emptier (and less even) last page.
            if (compactSpacing) {
                for (var i = 0; i < minNPages - 1; i++) {
                    while (pageModel[i] < minSPP && pageModel[pageModel.length - 1] > 0) {
                        --pageModel[pageModel.length - 1]
                        ++pageModel[i]
                    }
                }
            }
        }

        // console.log("Calculated Systems per Page: " + pageModel.toString())

        // Turn pageModel into a readable format:
        // - absolute instead of relative system values
        // - include starting offset (currentSystem) (-1 for indexing)
        pageModel[0] += currentSystem
        for (var i = 1; i < pageModel.length; i++) {
            pageModel[i] += pageModel[i-1]
        }

        return pageModel
    }

    ColumnLayout {
        x: spacing * 2
        y: spacing * 2
        anchors.margins: spacing
        spacing: spacing


        MU.StyledGroupBox {
            title: qsTr("Distribute systems")
            Layout.fillWidth: true

            GridLayout {
                anchors.fill: parent
                rowSpacing: spacing
                columnSpacing: spacing
                columns: 2

                MU.StyledTextLabel {
                    text: qsTr("Min. # of systems per page:")
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                MU.IncrementalPropertyControl {
                    id: minSPPBox
                    minValue: 1
                    currentValue: 4
                    step: 1
                    Layout.maximumWidth: 60
                    onValueEdited: function(newValue) {
                        currentValue = newValue
                        maxSPPBox.currentValue = Math.max(maxSPPBox.currentValue, newValue)
                        maxSPP1Box.currentValue = Math.max(maxSPP1Box.currentValue, newValue)
                    }
                }

                MU.StyledTextLabel {
                    text: qsTr("Max. # of systems per page:")
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                MU.IncrementalPropertyControl {
                    id: maxSPPBox
                    minValue: 1
                    currentValue: 6
                    step: 1
                    Layout.maximumWidth: 60
                    onValueEdited: function(newValue) {
                        currentValue = newValue
                        minSPPBox.currentValue = Math.min(minSPPBox.currentValue, newValue)
                    }
                }

                MU.StyledTextLabel {
                    text: qsTr("Max. # of systems on page 1:")
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                MU.IncrementalPropertyControl {
                    id: maxSPP1Box
                    minValue: 1
                    currentValue: 5
                    step: 1
                    Layout.maximumWidth: 60
                    onValueEdited: function(newValue) {
                        currentValue = newValue
                    }
                }
            }
        }

        MU.StyledGroupBox {
            title: qsTr("Spacing Mode")
            Layout.fillWidth: true

            MU.FlatRadioButtonList {
                id: spacingModeList
                spacing: spacing
                currentValue: settings.spacingMode

                model: [
                    { text: qsTr("Wide"),    value: 0 },
                    { text: qsTr("Regular"), value: 1 },
                    { text: qsTr("Compact"), value: 2 }
                ]

                onToggled: function(newValue) {
                    settings.spacingMode = newValue
                }
            }
        }

        MU.StyledGroupBox {
            title: qsTr("Score style options")
            Layout.fillWidth: true

            MU.CheckBox {
                id: applyAutoSpacing
                text: qsTranslate("Ms::MuseScore", "Enable vertical justification of staves")
                onClicked: {
                    checked = !checked
                    curScore.startCmd((checked ? "Enable" : "Disable") + " vertical justification of staves")
                    curScore.style.setValue("enableVerticalSpread", checked)
                    curScore.endCmd()
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: spacing

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
                    try {
                        curScore.startCmd("Evenly distribute systems across pages")
                        if (runPlugin()) {
                            curScore.endCmd()
                        } else {
                            curScore.endCmd(true)
                        }
                        quit()
                    } catch (e) {
                        curScore.endCmd(true)
                        text = e.toString()
                    }
                }
            }
        }
    }

    Settings {
        id: settings
        category: "System Spacer Plugin"
        property alias minSPPBox:  minSPPBox.currentValue
        property alias maxSPPBox:  maxSPPBox.currentValue
        property alias maxSPP1Box: maxSPP1Box.currentValue
        property int spacingMode: 1
    }
}
