using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Lang;
using Toybox.Application.Properties; // as Property;
using Toybox.Application.Storage as Storage;


function saveGResultsToStore() {
	//Sys.println("saveGResultsToStore() called");

	try {
		if (Toybox.Application has :Storage) {	
			Storage.setValue("GlanceSummary", glanceData);		
		}
	} catch (ex) {
		// storage error - most likely not written
		//Sys.println("saveGResultsToStore(): ERROR failed to save");
		return false;
	}
	finally {

	}
	//Sys.println("saveResultsToStore() done");
	return true;		
}

function loadGResultsFromStore() {
	//Sys.println("loadGResultsFromStore() called");	
	
	try {
		if (Toybox.Application has :Storage) {	
			glanceData = Storage.getValue("GlanceSummary");		
		}
	} catch (ex) {
		// storage error - most likely not written
		//Sys.println("ERROR loadGResultsFromStore");
		return false;
	}
	finally {
		if (glanceData == null) {
			// not been written yet
			return false;
		} else {
			// loaded target variable - glanceData
			return true;
		}
	}	

} 
    
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

function selectFont(dc, string, width, height, _fonts) {
    var testString = string; //Dummy string to test data width

    //testString = "a very long test string to see if we can get to a zero result or not";
    var fontIdx;
    var dimensions;

    //Search through fonts from biggest to smallest
    for (fontIdx = (_fonts.size() - 1); fontIdx > 0; fontIdx--) {
        dimensions = dc.getTextDimensions(testString, _fonts[fontIdx]);
        if ((dimensions[0] <= width) && (dimensions[1] <= height)) {
            //If this font fits, it is the biggest one that does
            break;
        }
        //Sys.print("Testing fontIdx = "+fontIdx);
        // does it ever go to zero! falls out of bottom with zero 
    }
	//Sys.println("Font Index = "+fontIdx);
	//fonts = null;
    return fontIdx;
}    

// This is the custom drawable we will use for backgrounds
class CustomBackground extends Ui.Drawable {

    function initialize(settings) {
        Drawable.initialize({});
    }

    // fill background
    function draw(dc) {
        dc.setColor(-1, $.mBgColour);
    	dc.clear();

    }
}
 
function f_drawText(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {

	var myTextArea;
	var mFont = Graphics.FONT_MEDIUM;
	var mFontID;
	//var vFonts = [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
	var vFonts = [Graphics.FONT_XTINY, Graphics.FONT_TINY, Graphics.FONT_SMALL, Graphics.FONT_MEDIUM, Graphics.FONT_LARGE];
			
    // now we need to pick font		
    // :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],

	//Sys.println("mDeviceType = "+$.mDeviceType);
	//Sys.println("width, height = "+width+", "+height);
	
	if (msgTxt.length() == 0) { return;}
	
    //if ($.mDeviceType == RES_240x240) {
    //	mFont = Graphics.FONT_SMALL;
    //} else if ( $.mDeviceType == RES_260x260 ) {
    //	mFont = Graphics.FONT_SMALL;
    //} else if ( $.mDeviceType == RES_280x280 ) {
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
    mFontID = selectFont(dc, msgTxt, width, height/2, vFonts); // was height /2
    var mTextWidth = dc.getTextWidthInPixels(msgTxt, vFonts[mFontID]);
	// tested whether a font is available that fits string so check within width 
	// font is possibly 0 the smallest so may not be ideal
	if (mTextWidth < width && mFontID != 0) {
			myTextArea = new Ui.Text({
	        :text=>msgTxt,
	        :color=>mValueColour,
	        :backgroundColor=>backColour,
	        :font=>vFonts[mFontID],
	        :locX=>LocX+width/2,
	        :locY=>LocY,
	        :width=>width,
	        :height=>height/2,
	        :justification=>Graphics.TEXT_JUSTIFY_CENTER //|Gfx.TEXT_JUSTIFY_VCENTER
	    });		    
	    myTextArea.draw(dc);
		
		return;
	}
    
    mFontID = selectFont(dc, msgTxt, width*2, height/2, vFonts);
    
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
 		mFontID = selectFont(dc, mString2, width, height/2, vFonts);   
    	//Sys.println("Space found @ "+mSpaceIdx+", String 1 and 2 = '"+mString1+"', '"+mString2+"'"); 		   
    }
    
    mFont = vFonts[mFontID];
		
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
    
    vFonts = null;
}
    

function f_drawTextArea(dc, msgTxt, mValueColour, backColour, LocX, LocY, width, height) {
		
	var myTextArea;	

	myTextArea = new Ui.TextArea({
        :text=>msgTxt,
        :color=>mValueColour,
        :backgroundColor=>backColour,
        :font=>[Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY],
        :locX=>LocX,
        :locY=>LocY,
        :width=>width,
        :height=>height,
        :justification=>Graphics.TEXT_JUSTIFY_CENTER
    });	
    myTextArea.draw(dc);    
}
 
 function plusView() {
	var _plusView = ($.viewNum + 1) % NUM_VIEWS;
	return getView(_plusView);
}

function lastView() { return getView($.lastViewNum); }

function subView() {
	var _subView = ($.viewNum + NUM_VIEWS - 1) % NUM_VIEWS;
	return getView(_subView);
}

function getView(newViewNum) {
	$.lastViewNum = $.viewNum;
	$.viewNum = newViewNum;
	
	//Sys.println("Last view: " + lastViewNum + " current: " + viewNum);
	if (STATS1_VIEW == $.viewNum) {
		return new StatsView(1);
	}
	else if (STATS2_VIEW == $.viewNum) {
		return new StatsView(2);
	}
	//0.4.4 - removing current view as no extra info and 
	else if (STATS3_VIEW == $.viewNum) {
		return new StatsView(3);
	}				
	else if (HISTORY_VIEW == $.viewNum) {
		return new HistoryView(0);
	}
	else if (TREND_VIEW == $.viewNum) {
		return new HistoryView(1);
	}
	else if (POINCARE_VIEW == $.viewNum) {
		return new PoincareView(1);
	}
	else if (POINCARE_VIEW2 == $.viewNum) {
		return new PoincareView(2);
	}	
	else if (BEATS_VIEW == $.viewNum) {
		//Sys.println("Beats view setup");
		return new BeatView();
	}	
	else if (INTERVAL_VIEW == $.viewNum) {
		//Sys.println("Interval view setup");
		return new IntervalView();
	}	
	else if (GLANCE_VIEW == $.viewNum) {
		//Sys.println("Glance view setup");
		return new HRVView(0);
	}								
	else {
		return new TestView();
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
