using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Lang;

// This is the custom drawable we will use for backgrounds
class CustomBackground extends Ui.Drawable {

    function initialize(settings) {
        Drawable.initialize({});
        //mColour = mapColour( $._mApp.bgColSet);
    }

    // fill background
    function draw(dc) {
    	// could draw a rectangle
    	var fore = mapColour( TRANSPARENT);
    	var back = mapColour($._mApp.bgColSet);
        dc.setColor(back, back);
    	dc.clear();

    }
}
 
function f_drawText(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {

	var myTextArea;
	var mFont = Gfx.FONT_MEDIUM;
			
    // now we need to pick font		
    // :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],

	Sys.println("mDeviceType = "+$._mApp.mDeviceType);
	Sys.println("width, height = "+width+", "+height);
	
    if ($._mApp.mDeviceType == RES_240x240) {
    	mFont = Gfx.FONT_SMALL;
    } else if ( $._mApp.mDeviceType == RES_260x260 ) {
    	mFont = Gfx.FONT_SMALL;
    } else if ( $._mApp.mDeviceType == RES_280x280 ) {
    	mFont = Gfx.FONT_SMALL;
    }
    
    // now have to split text over two lines
    var textSize = new [2];
    textSize = dc.getTextDimensions(msgTxt, mFont);
    // look for spaces from end backwards and see if first part fits.
    // if no spaces then just one string
    // need to split height into two and draw two text area
		
	myTextArea = new Ui.Text({
        :text=>"line 1", // msgTxt,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>mFont,
        :locX=>LocX+width/2,
        :locY=>LocY,
        :width=>width,
        :height=>height/2,
        :justification=>Gfx.TEXT_JUSTIFY_CENTER //|Gfx.TEXT_JUSTIFY_VCENTER
    });		    
    myTextArea.draw(dc);
    
	myTextArea = new Ui.Text({
        :text=>"line 2", //msgTxt,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>mFont,
        :locX=>LocX+width/2,
        :locY=>LocY+textSize[1]+5,
        :width=>width,
        :height=>height/2,
        :justification=>Gfx.TEXT_JUSTIFY_CENTER//|Gfx.TEXT_JUSTIFY_VCENTER
    });		    
    myTextArea.draw(dc);    
}
    

function f_drawTextArea(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {
		
	var myTextArea;	

	myTextArea = new Ui.TextArea({
        :text=>msgTxt,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],
        :locX=>LocX,
        :locY=>LocY,
        :width=>width,
        :height=>height,
        :justification=>Gfx.TEXT_JUSTIFY_CENTER
    });	
    myTextArea.draw(dc);	
}
    
function timerFormat(time) {
	var hour = time / 3600;
	var min = (time / 60) % 60;
	var sec = time % 60;
	if(0 < hour) {
		return Lang.format("$1$:$2$:$3$",[hour.format("%01d"),min.format("%02d"),sec.format("%02d")]);
	}
	else {
		return Lang.format("$1$:$2$",[min.format("%01d"),sec.format("%02d")]);
	}
}


function timeNow() {
	return (Time.now().value() + Sys.getClockTime().timeZoneOffset);
}

function timeToday() {
	return (timeNow() - (timeNow() % 86400));
}
