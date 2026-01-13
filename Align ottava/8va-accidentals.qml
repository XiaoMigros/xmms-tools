import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    title: qsTr("Align 8va over accidentals and grace notes")
    categoryCode: "Engraving"
    version: "1.0"
    description: qsTr("Horizontally aligns the text of 8va markings.")
    requiresScore: true

    readonly property bool adjustForAccidentals: true
    readonly property bool adjustForGraceNotes: true

    onRun: {
        var selectedOttavas = []
        if (curScore.selection.elements.length > 0) {
            for (var element of curScore.selection.elements) {
                if (element.type == Element.OTTAVA_SEGMENT) {
                    selectedOttavas.push(element.spanner)
                } else if (element.type == Element.OTTAVA) {
                    selectedOttavas.push(element)
                }
            }
        } else if (mscoreMinorVersion >= 7 || mscoreMajorVersion > 4) {
            for (var spanner of curScore.spanners) {
                if (spanner.type == Element.OTTAVA) {
                    selectedOttavas.push(spanner)
                }
            }
        }
        if (selectedOttavas.length == 0) {
            return
        }
        curScore.startCmd("Align 8va over accidentals and grace notes")
        for (var ottava of selectedOttavas) {
            fixOttava(ottava)
        }
        curScore.doLayout(fraction(0, 1), fraction(-1, 1))
        for (var ottava of selectedOttavas) {
            var frontSegment = ottava.spannerSegments[0]
            frontSegment.minDistance = undefined
        }
        curScore.endCmd()
        quit()
    }

    function fixOttava(ottava) {
        var frontSegment = ottava.spannerSegments[0]
        var segment = curScore.findSegmentAtTick(Segment.ChordRest, ottava.fraction)
        if (!segment || !frontSegment) {
            return
        }
        var leftPagePos = frontSegment.pagePos.x
        for (var i = frontSegment.staffIdx * 4; i < (frontSegment.staffIdx + 1) * 4; i++) {
            var e = segment.elementAt(i)
            if (e && e.type == Element.CHORD) {
                if (adjustForAccidentals) {
                    for (var note of e.notes) {
                        if (note.accidental && note.accidental.autoplace && note.accidental.visible) {
                            leftPagePos = Math.min(leftPagePos, note.accidental.pagePos.x + note.accidental.bbox.x)
                        }
                    }
                }
                if (adjustForGraceNotes) {
                    for (var gc of e.graceNotes) {
                        leftPagePos = Math.min(leftPagePos, gc.pagePos.x + gc.bbox.x)
                        if (adjustForAccidentals) {
                            for (var note of gc.notes) {
                                if (note.accidental && note.accidental.autoplace && note.accidental.visible) {
                                    leftPagePos = Math.min(leftPagePos, note.accidental.pagePos.x + note.accidental.bbox.x)
                                }
                            }
                        }
                    }
                }
            }
        }
        var difference = leftPagePos - frontSegment.pagePos.x
        frontSegment.offset.x += difference
        frontSegment.userOff2.x -= difference
    }
}
