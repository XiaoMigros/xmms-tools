import QtQuick 2.15
import MuseScore 3.0

MuseScore {
	title: qsTr("Smart Slur")
	description: qsTr("Automatically adds slurs to the selected passage of music, stopping at rests.")
	
	onRun: {
		if (curScore.selection.elements.length < 2) {
			cmd("select-all")
		}
		curScore.startCmd()
	    var startSeg = curScore.selection.startSegment
	    var endSeg   = curScore.selection.endSegment
		var startStaff = curScore.selection.startStaff
		var endStaff   = curScore.selection.endStaff

		var cursor = curScore.newCursor()
        cursor.rewind(Cursor.SCORE_START)

        for (var i = 0; i < curScore.nstaves; i++) {
		    cursor.staffIdx = i
			if (cursor.element.staff == startStaff) startStaff = cursor.staffIdx
			if (cursor.element.staff == endStaff) endStaff = cursor.staffIdx
		}
		
		for (var i = 0; i < (endStaff - startStaff + 1) * 4; i++) {
		    cursor.rewindToTick(startSeg.tick)
			cursor.track = startStaff * 4 + i
			var prevElement1 = false;
			var prevElement2 = false;
			var j = 0;
			do {
				j++
			    if (cursor.element.type == Element.CHORD) {
					if (prevElement1) {
						prevElement2 = cursor.element.notes[0]
					} else {
						prevElement1 = cursor.element.notes[0]
					}
				} else { // rest or invalid
				    if (prevElement1 && prevElement2) {
						curScore.selection.select(prevElement1, false)
						curScore.selection.select(prevElement2, true)
						cmd("add-slur")
					}
					prevElement1 = false
					prevElement2 = false
				} 
			} while (cursor.next() && cursor.segment != endSeg)
			if (prevElement1 && prevElement2) {
				curScore.selection.select(prevElement1, false)
				curScore.selection.select(prevElement2, true)
				cmd("add-slur")
			}
		}
		removeElement(curScore.lastMeasure)
		curScore.endCmd()
	}
}