import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Auto-Slur Melismas"
    description: qsTr("This plugin automatically add slurs to vocal melismas") + "\n" +
        qsTr("Compatible with MuseScore 3.3 and later.")
    version: "1.2"
    requiresScore: true

    property int maximumMelismaLength: 5
    //the plugin won't add slurs to melismas longer than the above value
    //measured in number of notes the melisma spans
    //0 = no limit

    Component.onCompleted: {
        if (mscoreMajorVersion >= 4) {
            title = qsTr("Auto-Slur Melismas")
            categoryCode = "notes-rests"
        } //if
    }//Component

    onRun: {
        if (!curScore.selection.elements.length) {
            cmd('select-all')
        }

        curScore.startCmd()
        var changeList = []
        var parsedLyrics = []
        for (var i in curScore.selection.elements) {
            var lyric = false;
            var e = curScore.selection.elements[i]
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
                    e = note.parent
                    // fall through
                case Element.CHORD:
                case Element.REST: {
                    for (var l in cursor.element.lyrics) {
                        for (var j in parsedLyrics) {
                            if (!parsedLyrics[j].is(e.lyrics[l])) {
                                lyric = e.lyrics[l]
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
                cursor.rewindToTick(lyric.parent.parent.tick)

                if (!cursor.element) {
                    continue
                }
                for (var l in cursor.element.lyrics) {
                    if (!cursor.element.lyrics[l].is(lyric)) {
                        continue
                    }
                    if (cursor.element.lyrics[l].lyricTicks.ticks >= cursor.element.duration.ticks) {
                        console.log("lyric has a melisma")
                        var startNote = noteOrRest(cursor.element)
                        var lengthCount = 0
                        var endTick = cursor.tick + cursor.element.lyrics[l].lyricTicks.ticks
                        var needToTie = false
                        while (cursor.tick < endTick) {
                            if (!needToTie) {
                                if (cursor.element.type == Element.REST) {
                                    needToTie = true;
                                } else {
                                    for (var m in cursor.element.notes) {
                                        if (!cursor.element.notes[m].tieForward) {
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
            cmd('add-slur')
        }
        curScore.selection.clear()
        curScore.endCmd(changeList.length == 0)
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
