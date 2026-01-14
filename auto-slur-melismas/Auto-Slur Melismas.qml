import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    title: "Auto-Slur Melismas"
    description: qsTr("This plugin automatically add slurs to vocal melismas")
    categoryCode: "notes-rests"
    version: "4.6"
    requiresScore: true

    property int maximumMelismaLength: 5
    //the plugin won't add slurs to melismas longer than the above value
    //measured in number of notes the melisma spans
    //0 = no limit

    onRun: {
        curScore.startCmd("Auto-slur melismas")

        if (!curScore.selection.elements.length) {
            cmd('select-all')
        }

        var changeList = []
        var parsedLyrics = []
        for (var e of curScore.selection.elements) {
            var lyric = false;
            switch (e.type) {
                case Element.LYRICS: {
                    var isNew = true
                    for (var j in parsedLyrics) {
                        if (parsedLyrics[j].is(e)) {
                            isNew = false
                            break
                        }
                    }
                    if (isNew) {
                        lyric = e
                    }
                }
                break
                case Element.NOTE:
                    e = e.parent
                    // fall through
                case Element.CHORD:
                case Element.REST: {
                    for (var l of e.lyrics) {
                        for (var j of parsedLyrics) {
                            if (!j.is(l)) {
                                lyric = l
                                break
                            }
                        }
                        if (lyric) {
                            break
                        }
                    }
                }
                break
                default: break
            }

            if (!lyric) {
                continue
            }
            console.log("lyric found")
            parsedLyrics.push(lyric)
            var cursor = curScore.newCursor()
            for (var j = 0; j < curScore.ntracks; j++) {
                cursor.track = j
                cursor.rewindToFraction(lyric.fraction)

                if (!cursor.element) {
                    continue
                }
                for (var l of cursor.element.lyrics) {
                    if (!l.is(lyric)) {
                        continue
                    }
                    if (l.lyricTicks.ticks >= cursor.element.duration.ticks) {
                        console.log("lyric has a melisma")
                        var startNote = noteOrRest(cursor.element)
                        var lengthCount = 0
                        var endTick = cursor.tick + l.lyricTicks.ticks
                        var needToTie = false
                        while (cursor.tick < endTick) {
                            if (!needToTie) {
                                if (cursor.element.type == Element.REST) {
                                    needToTie = true;
                                } else {
                                    for (var m of cursor.element.notes) {
                                        if (!m.tieForward) {
                                            needToTie = true
                                        }
                                    }
                                }
                            }
                            cursor.next()
                            lengthCount++
                        }
                        if (needToTie && (lengthCount < maximumMelismaLength || maximumMelismaLength == 0)) {
                            console.log("adding slur over " + lengthCount + " notes")
                            changeList.push([startNote, noteOrRest(cursor.element)])
                        } else {
                            console.log(needToTie ? "The melisma exceeds the maximum length for adding slurs." : "All notes are tied. No need to add a slur")
                        }
                    }
                }
            }
        }

        curScore.selection.clear()
        for (var i in changeList) {
            curScore.selection.select(changeList[i][0], false)
            curScore.selection.select(changeList[i][1], true)
            cmd("add-slur")
        }
        curScore.selection.clear()
        curScore.endCmd()
        smartQuit()
    }//onRun

    function noteOrRest(element) {
        return (element.type == Element.REST) ? element : element.notes[0]
    }

    function smartQuit() {
        if (mscoreMajorVersion < 4) {
            Qt.quit()
        } else {
            quit()
        }
    }//smartQuit
}//MuseScore
