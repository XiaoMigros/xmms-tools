import QtQuick
import MuseScore

MuseScore {
    title:"Position ties correctly"
    categoryCode: "Engraving"
    version: "4.6"
    description: qsTr("Fixes tie engraving: Sets ties on the outside of chords to outside placement, and the rest to inside placement.")
    requiresScore: true

    onRun: {
        curScore.startCmd("Position ties correctly")
        curScore.style.setValue("tiePlacementSingleNote", TiePlacement.OUTSIDE)
        curScore.style.setValue("tiePlacementChord", TiePlacement.OUTSIDE)
        for (var seg = curScore.firstSegment(Segment.ChordRest); seg; seg = seg.next) {
            if (seg.segmentType == Segment.ChordRest) {
                for (var i = 0; i < curScore.ntracks; i++) {
                    if (seg.elementAt(i) && seg.elementAt(i).type == Element.CHORD) {
                        var chord = seg.elementAt(i)
                        for (var j in chord.notes) {
                            checkTies(chord.notes[j])
                        }
                        for (var j in chord.graceNotes) {
                            for (var k in chord.graceNotes[j].notes) {
                                checkTies(chord.graceNotes[j].notes[k])
                            }
                        }
                    }
                }
            }
        }
        curScore.endCmd()
    }

    function checkTies(note) {
        processTie(note.tieForward)
        processTie(note.tieBack)
    }

    function processTie(tie) {
        if (!tie) {
            return
        }
        if ((!tie.startNote || tie.startNote.parent.notes.length == 1) && (!tie.endNote || tie.endNote.parent.notes.length == 1)) {
            if (tie.isInside) {
                tie.tiePlacement = TiePlacement.AUTO
            }
            return;
        }
        tie.tiePlacement = (insideChord(tie, tie.startNote) || insideChord(tie, tie.endNote)) ? TiePlacement.INSIDE : TiePlacement.AUTO
    }

    function insideChord(tie, note) {
        if (!note) {
            return false
        }
        return tie.up ? !note.is(note.parent.upNote) : !note.is(note.parent.downNote)
    }
}
