using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;



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

function MapSetColour( dc, fore, back) {
	// map colours to be used
	var fore_pick = mapColour(fore);
	var bkg_pick = mapColour(back);
	dc.setColor(fore_pick, bkg_pick);
	
}
	