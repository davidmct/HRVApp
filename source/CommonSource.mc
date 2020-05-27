using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Lang;


var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE];

function selectFont(dc, string, width, height) {
    var testString = string; //Dummy string to test data width
    var fontIdx;
    var dimensions;

    //Search through fonts from biggest to smallest
    for (fontIdx = (fonts.size() - 1); fontIdx > 0; fontIdx--) {
        dimensions = dc.getTextDimensions(testString, fonts[fontIdx]);
        if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
            //If this font fits, it is the biggest one that does
            break;
        }
    }

    return fontIdx;
}    

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
	var mFont = Graphics.FONT_MEDIUM;
	var mFontID;
			
    // now we need to pick font		
    // :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],

	Sys.println("mDeviceType = "+$._mApp.mDeviceType);
	Sys.println("width, height = "+width+", "+height);
	
    //if ($._mApp.mDeviceType == RES_240x240) {
    //	mFont = Graphics.FONT_SMALL;
    //} else if ( $._mApp.mDeviceType == RES_260x260 ) {
    //	mFont = Graphics.FONT_SMALL;
    //} else if ( $._mApp.mDeviceType == RES_280x280 ) {
    //	mFont = Graphics.FONT_SMALL;
    //}
    
    // now have to split text over two lines
    // Algo...
    // what font fits in twice width available _ call font select function (doesn't fail gracefully if no fit)
    // Find middle of text then search for a space in either direction
    // trim text into two strings and check longer by redoing font search on longer (could just check size is ok as well 
    // but would potentially have to do another search
    
    // what font fits whole string in half height and twice width
    mFontID = selectFont(dc, msgTxt, width*2, height/2);
    
    var mMidCharIdx = msgTxt.length()/2;
    var mSpaceIdx = null;
    for (var i=mMidCharIdx; i >= 0; i--) {
    	var subStr = msgTxt.substring(i, i);
    	if (subStr.equals(" ") ) { mSpaceIdx = i; break;}
    }
    
    var mString1;
    var mString2;
    
    if ( mSpaceIdx == null) {
    	// no space char found so split string anyway
    	mString2 = msgTxt.substring(msgTxt.length()/2, msgTxt.length()-1);
    	mString1 = msgTxt.substring(0, msgTxt.length()/2-1);
    } else {
 		// check longer string fits still
     	mString2 = msgTxt.substring(mSpaceIdx+1, msgTxt.length()-mSpaceIdx-1-1);
    	mString1 = msgTxt.substring(0, mSpaceIdx);		
 		mFontID = selectFont(dc, mString2, width, height/2);      
    }
    
    mFont = font[mFontID];
		
	myTextArea = new Ui.Text({
        :text=>mString1,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>mFont,
        :locX=>LocX+width/2,
        :locY=>LocY,
        :width=>width,
        :height=>height/2,
        :justification=>Graphics.TEXT_JUSTIFY_CENTER //|Gfx.TEXT_JUSTIFY_VCENTER
    });		    
    myTextArea.draw(dc);
    
	myTextArea = new Ui.Text({
        :text=>mString2,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>mFont,
        :locX=>LocX+width/2,
        :locY=>LocY+height/2-5,
        :width=>width,
        :height=>height/2,
        :justification=>Graphics.TEXT_JUSTIFY_CENTER//|Gfx.TEXT_JUSTIFY_VCENTER
    });		    
    myTextArea.draw(dc);    
}
    

function f_drawTextArea(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {
		
	var myTextArea;	

	myTextArea = new Ui.TextArea({
        :text=>msgTxt,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>[Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY],
        :locX=>LocX,
        :locY=>LocY,
        :width=>width,
        :height=>height,
        :justification=>Graphics.TEXT_JUSTIFY_CENTER
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
