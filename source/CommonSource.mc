using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Lang;


var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE];

//0.4.4 - in memory debug
var mDebugString ="";
const MAX_DEBUG_STRING = 1000;

(:MemDebug)
function DebugMsg( flag, Msg) {
	// do we have space? Just Flush every second then should be fine
	//if ( Msg.length() + Msg.length() > MAX_DEBUG_STRING) {FlushMsg();}
	
	if (flag) { mDebugString = mDebugString + Msg + ", ";}
}

function FlushMsg() {
	if (mDebugString.length() != 0) {
		Sys.println(mDebugString);
		mDebugString = "";
	}
}

(:ConsoleDebug)
function DebugMsg( flag, Msg) {
	if (flag) { Sys.println("Msg");}
}

function selectFont(dc, string, width, height) {
    var testString = string; //Dummy string to test data width
    //testString = "a very long test string to see if we can get to a zero result or not";
    var fontIdx;
    var dimensions;

    //Search through fonts from biggest to smallest
    for (fontIdx = (fonts.size() - 1); fontIdx > 0; fontIdx--) {
        dimensions = dc.getTextDimensions(testString, fonts[fontIdx]);
        if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
            //If this font fits, it is the biggest one that does
            break;
        }
        //Sys.print("Testing fontIdx = "+fontIdx);
        // does it ever go to zero! falls out of bottom with zero 
    }
	//Sys.println("Font Index = "+fontIdx);
    return fontIdx;
}    

// This is the custom drawable we will use for backgrounds
class CustomBackground extends Ui.Drawable {

    function initialize(settings) {
        Drawable.initialize({});
    }

    // fill background
    function draw(dc) {
        dc.setColor(-1, $._mApp.mBgColour);
    	dc.clear();

    }
}
 
function f_drawText(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {

	var myTextArea;
	var mFont = Graphics.FONT_MEDIUM;
	var mFontID;
			
    // now we need to pick font		
    // :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],

	//Sys.println("mDeviceType = "+$._mApp.mDeviceType);
	//Sys.println("width, height = "+width+", "+height);
	
	if (msgTxt.length() == 0) { return;}
	
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
    
    // need to check if string fits in width then ok
    
    // Does text fit in first line?
    mFontID = selectFont(dc, msgTxt, width, height/2);
    var mTextWidth = dc.getTextWidthInPixels(msgTxt, fonts[mFontID]);
	// tested whether a font is available that fits string so check within width 
	// font is possibly 0 the smallest so may not be ideal
	if (mTextWidth < width && mFontID != 0) {
			myTextArea = new Ui.Text({
	        :text=>msgTxt,
	        :color=>mValueColour,
	        :backgroundColor=>backColour,
	        :font=>fonts[mFontID],
	        :locX=>LocX+width/2,
	        :locY=>LocY,
	        :width=>width,
	        :height=>height/2,
	        :justification=>Graphics.TEXT_JUSTIFY_CENTER //|Gfx.TEXT_JUSTIFY_VCENTER
	    });		    
	    myTextArea.draw(dc);
		
		return;
	}
    
    mFontID = selectFont(dc, msgTxt, width*2, height/2);
    
    var mMidCharIdx = msgTxt.length()/2;
    var mSpaceIdx = null;
    for (var i=mMidCharIdx; i >= 0; i--) {
    	var subStr = msgTxt.substring(i, i+1);
    	//Sys.println("char = :"+subStr);
    	if (subStr.equals(" ") ) { mSpaceIdx = i; break;}
    }
    
    var mString1;
    var mString2;
    
    //Sys.println("Message text is: '"+msgTxt+"' of length "+msgTxt.length()+" with mid "+mMidCharIdx);
    
    
    if ( mSpaceIdx == null) {
    	// no space char found so split string anyway
    	mString2 = msgTxt.substring(msgTxt.length()/2, msgTxt.length());
    	mString1 = msgTxt.substring(0, msgTxt.length()/2);
    	//Sys.println("no space found. String 1 and 2 = "+mString1+", "+mString2);
    } else {
 		// check longer string fits still
     	mString2 = msgTxt.substring(mSpaceIdx+1, msgTxt.length());
    	mString1 = msgTxt.substring(0, mSpaceIdx);		
 		mFontID = selectFont(dc, mString2, width, height/2);   
    	//Sys.println("Space found @ "+mSpaceIdx+", String 1 and 2 = '"+mString1+"', '"+mString2+"'"); 		   
    }
    
    mFont = fonts[mFontID];
		
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
    
    if (mDebugging) {
    	// show text box around area
    	dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
    	dc.drawRectangle( LocX, LocY, width, height);
    }
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
