//Score Duration

import QtQuick 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.5
import Qt.labs.settings 1.0
import MuseScore 3.0

// Changelog:
// 1.2.1: visual improvements, bug fixes
// 1.2.0: MuseScore 4 compatibility, tag preview, massive code simplifications
// 1.1.2: Fixed a bug which meant settings only saved on 60s =< scores < 3600s
//        Fixed a bug where a score of eg. 61 seconds could be saved as 1:1 (preferred: 1:01)
//        Text in the pop-up window doesn't automatically add plurals to all units.
//        Text in the pop-up window won't display empty quotes if no score title was found.
//        Various code simplifications
// 1.1.1: The plugin now saves selected options to settings.
// 1.1.0: The plugin can now write the duration to Score Properties, in a variety of formats.
// 1.0.1: Initial functional release

MuseScore {
    menuPath: qsTr("Plugins.Score Duration")
    description: qsTr("Outputs a score's duration in hours, minutes, and seconds.")
    version: "1.2.1"
    requiresScore: true
    id: sd
	
    Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            sd.title = qsTr("Score Duration")
            sd.thumbnailName = "logo.png"
            sd.categoryCode = "analysis"
        } //if
    } //oncompleted
    
	//different time formats
    property var savetext1: ""
    property var savetext2: ""
    property var savetext3: ""
    property var savetext4: ""
	
	property var savetext: units.checked ? (seconds.checked ? savetext3 : savetext1) : (seconds.checked ? savetext4 : savetext2)
	
	property var score:	curScore
	property var dur:	score.duration
      
	onRun: {
		console.log("Running Plugin: Score Duration")
		
		//time calculation
		var dursec	= dur % 60
		var durmin	= (dur - dursec) / 60
		var durmin2	=  durmin % 60
		var durh	= (durmin-durmin2) / 60
		
		//text format for window
		var titleformat	= (score.title == "") ? ("Your score is ") : ("Your score '" + score.title + "' is ")
		var hourtext	= ""
		var hourtype	= ""
		var hourpunct	= ""
		var mintext		= ""
		var mintype		= ""
		var minpunct	= ""
		var sectext		= ""
		var sectype		= ""
		var abssec		= (durmin == 0) ? (" long.") : (" long (" + dur + " seconds).")
		var puncttype	= 0;
		
		if (durh > 0) {
			puncttype += 1;
			hourtext = durh;
			hourtype = (durh == 1) ? " hour" : " hours"
		}//if durh
		
		//we want to display durmin2 rather than durmin, as durmin2 will always be < 60
		if (durmin2 > 0) {
			puncttype += 2;
			mintext = durmin2;
			mintype = (durmin2 == 1) ? " minute" : " minutes"
		}//if durmin2
		
		//account for cases where dursec is displayed and also where the score duration is 0
		if (dursec > 0 || dur == 0) {
			puncttype += 4;
			sectext = dursec;
			sectype = (dursec == 1) ? " second" : " seconds"
		}//if dursec
		
		switch (puncttype) {
			//determines how to write the list depending on score length
			case 3: {hourpunct = " and "; break;}
			
			case 5: {hourpunct = " and "; break;}
			
			case 6: {minpunct = " and "; break;}
			
			case 7: {hourpunct = ", "; minpunct = ", and "; break;}
			
			default: {break;}
		}//switch
		
		ddtext.text = (titleformat + hourtext + hourtype + hourpunct + mintext + mintype + minpunct + sectext + sectype + abssec);
		console.log(ddtext.text);
		
		//save format for scores >= 3600s
		if (durmin >= 60) {
			savetext1 = (durh + " h, " + durmin2 + " min, " + dursec + " s");
			savetext2 = (durmin2 >= 10) ? ((dursec >= 10) ? (durh + ":" + durmin2 + ":" + dursec) : (durh + ":" + durmin2 + ":0" + dursec))
						: ((dursec >= 10) ? (durh + ":0" + durmin2 + ":" + dursec) : (durh + ":0" + durmin2 + ":0" + dursec))
		} else 
		
		//save format for scores < 60s 
		if (durmin == 0) {            
			savetext1 = (dursec + " s");
			//to avoid an 8 second score to result in 0:8 (preferred: 0:08)
			savetext2 = (dursec >= 10) ? ("0:" + dursec) : ("0:0" + dursec);
		} else
		
		//save format for 60s =< scores < 3600s
		{
			savetext1 = (durmin + " min, " + dursec + " s");
			savetext2 = (dursec >= 10) ? (durmin + ":" + dursec) : (durmin + ":0" + dursec);
		}//else
		
		//these are the same regardless of score length
		savetext3 = (dur + " s");
		savetext4 = dur;
		
		durationDialog.open() //open window
		
	} //onRun
	
	//executed on button click or return key from text field
	function saveToTag() {
		//checks for save to score properties
		if (saveprop.checked) {
			var actTagName = tagname.placeholderText
			//checks for alternate tag name
			if (tagname.text != "") {
				actTagName = tagname.text;
			}
			console.log("Writing '" + savetext  + "' to tag '" + actTagName + "'.");
			score.setMetaTag(actTagName, savetext);   
		} else {
			//wanted if we dont save to score properties
			console.log("Not saving to Score Properties.")
		}
		
		console.log("Closing...")
		durationDialog.close();
	} //function
	
	//Window shown to end user
	Dialog {
		id: durationDialog
		title: qsTr("Score Duration");
		
		standardButtons: StandardButton.Ok
		onAccepted: {saveToTag()}
		
		Label {id: ddtext} //Label type for improved automatic styling
		
		GridLayout {
			anchors.top: ddtext.bottom
			anchors.left: mainLayout.right
			anchors.margins: 10
			anchors.leftMargin: 20
			columns: 2
			visible: saveprop.checked
				
			Label {text: qsTr("Preview:")}//Label
			
			TextField {
				enabled: false
				text: savetext
			}//TextField
			
			Label {text: qsTr("Tag Name:")} //Label
			
			TextField {
				id: tagname
				placeholderText: qsTr("duration")
				Keys.onReturnPressed: {saveToTag()}
			} //Textfield 
			
		}//ColumnLayout
		
		ColumnLayout {
			id: mainLayout
			anchors.margins: 10
			anchors.top: ddtext.bottom
			anchors.topMargin: 10
			
			CheckBox {
				id: saveprop
				text: qsTr("Save to Score Properties")
			} //CheckBox
			
			RowLayout {
				spacing: 20;
				visible: saveprop.checked;
				 
				CheckBox {
					id: units;
					checked: false;
					text: qsTr("Save Units");
				} //CheckBox
						
				CheckBox {
					id: seconds;
					checked: false;
					text: qsTr("Seconds only");
				} //CheckBox
				
			} //RowLayout
			
		}//ColumnLayout
		
	} //Dialog
	
	Settings {
		id: settings
		category: "ScoreDurationPlugin"
		property alias saveprop:	saveprop.checked
		property alias units:		units.checked
		property alias seconds:		seconds.checked
		property alias tagname:		tagname.text
	} //Settings
	
} //MuseScore