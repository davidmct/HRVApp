using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

// Setup global colours
function mapIndexToColours() {
		
	var mColours = Ui.loadResource(Rez.JsonData.jsonColourList); 
    
    $.mLabelColour = mColours[$.lblColSet];
    $.mValueColour = mColours[$.txtColSet];
	$.mBgColour = mColours[$.bgColSet];
	// This colour is dynamic
	//$.mHRColour = mColours[$.mSensor.mHRData.mHRMStatusCol];
	$.Label1Colour = mColours[$.Label1ColSet];		
	$.Label2Colour = mColours[$.Label2ColSet];
	$.Label3Colour = mColours[$.Label3ColSet];

	mColours = null;
	return;		
}

function mapColour(index) {
	var col;
	//if (index == null) { Sys.println("mapColour: Null index");}	
	
	var mColours = Ui.loadResource(Rez.JsonData.jsonColourList); 
       
	if (index < 0 || index > (mColours.size()-1) ) {
		//Sys.println("mapColour: index out of range");
		col = 0;
	} else {
		col = index;
	}
	//Sys.println("mapColour from " + index + " to " + col);
	return mColours[col];		
}

(:discard)
function MapSetColour( dc, fore, back) {
	// map colours to be used
	var fore_pick = mapColour(fore);
	var bkg_pick = mapColour(back);
	dc.setColor(fore_pick, bkg_pick);
	
}
	