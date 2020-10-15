using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

// Setup global colours
function mapIndexToColours() {
		
	var mColours = Ui.loadResource(Rez.JsonData.jsonColourList); 
    
    $._mApp.mLabelColour = mColours[$._mApp.lblColSet];
    $._mApp.mValueColour = mColours[$._mApp.txtColSet];
	$._mApp.mBgColour = mColours[$._mApp.bgColSet];
	// This colour is dynamic
	//$._mApp.mHRColour = mColours[$._mApp.mSensor.mHRData.mHRMStatusCol];
	$._mApp.Label1Colour = mColours[$._mApp.Label1ColSet];		
	$._mApp.Label2Colour = mColours[$._mApp.Label2ColSet];
	$._mApp.Label3Colour = mColours[$._mApp.Label3ColSet];

	mColours = null;
	return;		
}

function mapColour(index) {
	var col;
	//if (index == null) { Sys.println("mapColour: Null index");}	
	
	var mColours = Ui.loadResource(Rez.JsonData.jsonColourList); 
       
	if (index < 0 || index > (mColours.size()-1) ) {
		Sys.println("mapColour: index out of range");
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
	