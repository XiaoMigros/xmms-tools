import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    title: qsTr("Add repeats around selection")
    description: qsTr("Saves 3 clicks by adding a simple repeat around the selection")
    version: "4.6"

    onRun: {
        if (curScore.selection.isRange) {
            if (curScore.selection.endSegment) {
                addRepeats(curScore.selection.startSegment.parent, curScore.tick2measure(curScore.selection.endSegment.fraction.minus(fraction(1, 4 * division))))
            } else {
                addRepeats(curScore.selection.startSegment.parent, curScore.lastMeasure)
            }
        } else if (curScore.selection.elements.length) {
            var startTick = curScore.lastMeasure.tick.plus(curScore.lastMeasure.ticks)
            var endTick = fraction(0, 1)
            for (var e of curScore.selection.elements) {
                if (e.fraction.lessThan(startTick)) {
                    startTick = e.fraction
                }
                if (e.fraction.greaterThan(endTick)) {
                    /// @todo endTick for CRs, tick2 for spanners, then subtract eps
                    endTick = e.fraction
                }
            }
            addRepeats(curScore.tick2measure(startTick), curScore.tick2measure(endTick))
        }
    }

    function addRepeats(startM, endM) {
        if (startM && endM) {
            curScore.startCmd("Add repeats around selection")
            var remove = startM.repeatStart && endM.repeatEnd
            for (var m = startM; m && m != endM; m = m.next) {
                m.repeatStart = false
                m.repeatEnd = false
            }
            startM.repeatStart = !remove
            endM.repeatEnd = !remove
            curScore.endCmd()
        }
    }
}
