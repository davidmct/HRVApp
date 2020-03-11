using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

// could implement device specific colour maps here eg to 64 or fenix 3 case using tags

// index with enum for colours
var colours =[Graphics.COLOR_WHITE, Graphics.COLOR_LT_GRAY,Graphics.COLOR_DK_GRAY,Graphics.COLOR_BLACK,
				Graphics.COLOR_RED, Graphics.COLOR_DK_RED, Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW,
				Graphics.COLOR_GREEN, Graphics.COLOR_DK_GREEN,Graphics.COLOR_BLUE,Graphics.COLOR_DK_BLUE,
				Graphics.COLOR_PURPLE, //Purple. Not valid on fenix 3 or D2 Bravo. Use 0x5500AA instead.
				Graphics.COLOR_PINK, Graphics.COLOR_TRANSPARENT];
	
var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE,
             Graphics.FONT_NUMBER_MILD,Graphics.FONT_NUMBER_MEDIUM,Graphics.FONT_NUMBER_HOT,Graphics.FONT_NUMBER_THAI_HOT];
			
enum {
	// Colors index. Arrays start at zero
	WHITE = 0,
	LT_GRAY = 1,
	DK_GRAY = 2,
	BLACK = 3,
	RED = 4,
	DK_RED = 5,
	ORANGE = 6,
	YELLOW = 7,
	GREEN = 8,
	DK_GREEN = 9,
	BLUE = 10,
	DK_BLUE = 11,
	PURPLE = 12,
	PINK = 13,
	TRANSPARENT = 14
}

	function mapColour(index) {
		var col;
		if (index < 0 || index > (colours.size()-1) ) {
			Sys.println("mapColour: index out of range");
			col = 0;
		} else {
			col = index;
		}
		//Sys.println("mapColour from " + index + " to " + col);
		return colours[col];
		
	}
	
	function MapSetColour( dc, fore, back) {
		// map colours to be used
		var fore_pick = mapColour(fore);
		var bkg_pick = mapColour(back);
		dc.setColor(fore_pick, bkg_pick);
		
	}
	