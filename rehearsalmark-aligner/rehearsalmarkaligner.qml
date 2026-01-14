import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    title: qsTr("Align rehearsal marks")
    description: qsTr("Aligns rehearsal marks horizontally over barlines")
    version: "1.0"

    onRun: {
        curScore.startCmd("Align rehearsal marks over barlines")
        if (!curScore.selection.elements.length) {
            for (var seg = curScore.firstSegment(); seg; seg = seg.next) {
                for (var e of seg.annotations) {
                    if (e.type == Element.REHEARSAL_MARK) {
                        fixPos(e)
                    }
                }
            }
        } else {
            for (var e of curScore.selection.elements) {
                if (e.type == Element.REHEARSAL_MARK) {
                    fixPos(e)
                }
            }
        }
        curScore.endCmd()
    }

    function fixPos(rehearsalMark) {
        if (rehearsalMark.parent.fraction.equals(rehearsalMark.parent.parent.tick)) {
            let difference = rehearsalMark.pagePos.x - rehearsalMark.parent.parent.pagePos.x
            rehearsalMark.offsetX -= difference
        }
    }
}