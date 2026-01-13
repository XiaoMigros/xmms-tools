import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    title: qsTr("Split Measure Across System")
    description: qsTr("Splits a measure across a system, saving a few clicks.") + "\n" +
        qsTr("Requires MuseScore 4.6 or later")
    version: "4.6"
    requiresScore: true

    readonly property bool hideLeftBarlineOnNewSystem: false // Gould p. 521

    onRun: {
        // close the plugin if theres no selection
        if (!curScore.selection.elements.length) {
            quit()
        }

        curScore.startCmd("Split measure across system")

        const tick = curScore.selection.elements[0].fraction
        var m = curScore.tick2measure(tick)
        // Split breaks locks, so check for those first
        var systemStartMB = m.parent.first
        var systemEndMB = m.parent.last
        var nextSystemEndMB = m.parent.last.next.parent.last
        const shouldLock = m.parent.isLocked || nextSystemEndMB.parent.isLocked

        // Split the measure, with the start of the selection ending up on the next system
        // Don't split measures if the first point in a measure is selected
        // (the rest of the plugin is allowed to run regardless)
        if (!tick.equals(m.firstSegment.fraction)) {
            cmd('split-measure')
        }


        // Don't count the newly created 'measure' in the measure count
        m = curScore.tick2measure(tick).prevMeasure
        m.irregular = true
        // If systems are locked, move second measure to the new system
        // If not, just add a system break
        if (shouldLock) {
            curScore.makeIntoSystem(systemStartMB ?? m, m)
            curScore.makeIntoSystem(m.nextMeasure, systemEndMB ?? nextSystemEndMB)
        } else {
            var systemBreak = newElement(Element.LAYOUT_BREAK)
            systemBreak.layoutBreakType = LayoutBreak.LINE
            m.add(systemBreak)
        }

        // Hide barlines
        curScore.doLayout(m.tick, m.nextMeasure.tick.plus(m.nextMeasure.ticks))
        var c = curScore.newCursor()
        c.rewindToFraction(m.firstSegment.fraction)
        c.filter = Segment.EndBarLine
        c.next()
        hideBarlines(c, tick)
        if (hideLeftBarlineOnNewSystem) {
            c.filter = Segment.BeginBarLine
            c.rewindToFraction(tick)
            if (c.segment) {
                hideBarlines(c, tick)
                c.segment.leadingSpace = curScore.style.value("clefLeftMargin")
            }
        }

        curScore.endCmd()
        quit()
    }

    function hideBarlines(cursor, tick) {
        if (cursor.fraction.equals(tick)) {
            for (var i = 0; i < curScore.ntracks; i += 4) {
                if (cursor.segment.elementAt(i)) {
                    cursor.segment.elementAt(i).visible = false
                }
            }
        }
    }
}
