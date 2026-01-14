import QtQuick 2.15
import MuseScore 3.0

MuseScore {
    title: qsTr("Smart Slur")
    description: qsTr("Automatically adds slurs to the selected passage of music, stopping at rests.")

    onRun: {
        curScore.startCmd("Add slurs")
        var full = curScore.selection.elements.length < 2
        var startSeg = full ? curScore.firstSegment() : curScore.selection.startSegment
        var endSeg   = full ? false : curScore.selection.endSegment
        var startStaff = full ? 0 : curScore.selection.startStaff
        var endStaff   = full ? curScore.nstaves - 1 : curScore.selection.endStaff

        for (var i = startStaff * 4; i < (endStaff + 1) * 4; i++) {
            var cursor = curScore.newCursor()
            cursor.rewindToTick(startSeg.tick)
            cursor.track = i
            var prevElement1 = false
            var prevElement2 = false
            do {
                if (!cursor.element) {
                    continue
                }
                if (cursor.element.type == Element.CHORD) {
                    if (prevElement1) {
                        prevElement2 = cursor.element.notes[0]
                    } else {
                        prevElement1 = cursor.element.notes[0]
                    }
                } else { // rest or invalid
                    addSlur(prevElement1, prevElement2)
                    prevElement1 = false
                    prevElement2 = false
                }
            } while (cursor.next() && !cursor.segment.is(endSeg))
            addSlur(prevElement1, prevElement2)
        }
        curScore.selection.clear()
        curScore.endCmd()
    }

    function addSlur(prevElement1, prevElement2) {
        if (prevElement1 && prevElement2) {
            curScore.selection.select(prevElement1, false)
            curScore.selection.select(prevElement2, true)
            cmd("add-slur")
        }
    }
}