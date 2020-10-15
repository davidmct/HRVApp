using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

//0.4.9
//This file draws a graph of a Interval against sample number
//Add in future ecoptic status etc
// We need value on Y axis of range which maybe dynamic (based on datastream or fixed)

class IntervalView extends Ui.View {

	hidden var startTimeP;
	hidden var mProcessingTime;
	
	hidden var customFont = null;

	hidden var cGridWith;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	hidden var rightX;
	hidden var ceilY;
	hidden var floorY;
    
    hidden var mTitleLoc = [50,11]; // %
	hidden var mTitleLocS = [0, 0];	
	hidden var mTitleLabels = ["II Plot"];
		
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_XTINY;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_BLUE;
	hidden var mBeatColour = Gfx.COLOR_RED;
		
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;

	function initialize() { 
		View.initialize();
	}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
	
	function onLayout(dc) {
		
		var a = Ui.loadResource(Rez.Strings.PoincareGridWidth);
		cGridWith = a.toNumber();
		
		if ($._mApp.mDeviceType == RES_240x240) {		
			customFont = Ui.loadResource(Rez.Fonts.smallFont);
		}
		
		// chartHeight defines height of chart and sets scale
		// needs to divide by 6 for horizontal lines
		// impacts all layout numbers!
		chartHeight = cGridWith;
    	ctrX = dc.getWidth() / 2;
		ctrY = dc.getHeight() / 2;
		// define box about centre
		leftX = ctrX - cGridWith/2;
		rightX = ctrX + cGridWith/2;
		// 45 *2 is height of chart
		ceilY = ctrY - chartHeight/2;
		floorY = ctrY + chartHeight/2;
		
		mScaleY = dc.getHeight();
		mScaleX = dc.getWidth();
		
		// convert % to numbers based on screen size
		mTitleLocS = [ (mTitleLoc[0]*mScaleX)/100, (mTitleLoc[1]*mScaleY)/100];	
										
		return true;
	}
	
    //! Update the view
    function onUpdate(dc) {
    	// performance check
    	startTimeP = Sys.getTimer();
		
		if ($._mApp.mDeviceType == RES_240x240) {	
			mLabelFont = customFont;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $._mApp.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
		// X range is unscaled and just point number out of range
    	  	
    	// y range needed for plot
    	// FIXED IN FIRST IMPLEMENTATION
    	var Ymin = 2000;
    	var Ymax = 400;
   	
		// if no sample processing then exit 
    	if ($._mApp.mSampleProc == null ) { return true;}
    	
    	// reduce entries by 1 as points to next free slot    	
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples();
		// how many points to plot
    	var mSampleNum = 0;
    	
     	// check we have enough samples   	   			
		// need two entries before we start!
		if ( mNumberEntries < 2) { return true;}
    	
    	// where to read buffer from
    	var mStartIndex = null;
    	if ( mNumberEntries < chartHeight) {
    		mSampleNum = mNumberEntries-1;
    		mStartIndex = 0; // start of buffer
    	} else {
    		mSampleNum = chartHeight;
    		mStartIndex = mNumberEntries - mSampleNum - 1;
    	}
    	
    	Sys.println("IntervalPlot: Ploting: "+mSampleNum+" samples starting from "+mStartIndex);

		var scaleY = chartHeight / (Ymax - Ymin).toFloat();		
		// now draw graph
		var sample = $._mApp.mIntervalSampleBuffer[mStartIndex];
		var mY0 = floorY - ((sample-Ymax) * scaleY).toNumber();
		var mX0 = leftX;
		var mY1;
		
		dc.setPenWidth(2);
		
		// we go from mStartIndex until used all mSampleNum		
		for( var i = mStartIndex+1; i < mNumberEntries-1; i++ ){	
			// first iteration this is end point	
			sample = $._mApp.mIntervalSampleBuffer[i];
			mY1 = floorY - ((sample-Ymax) * scaleY).toNumber();
			
			// default line colour is red		
			dc.setColor( Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
			dc.drawLine(mY0, mX0, mY1, mX0+1);
			
			mX0++;
			mY0 = mY1;
						
		} // end sample loop
		
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);
				
		// label avg axis
		dc.drawText( leftX+5, ceilY, mLabelFont, format("$1$",[Ymax.format("%d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );
		dc.drawText( leftX+5, floorY, mLabelFont, format("$1$",[Ymin.format("%d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );		
		dc.drawLine( leftX+5, ctrY, rightX, ctrY);
			
		// performance check only on real devices
		mProcessingTime = Sys.getTimer()-startTimeP;

   		return true;
    }
        
    function onHide() {
 		// performance check only on real devices
		//var currentTime = Sys.getTimer();
		Sys.println("IntervalPlot executes in "+mProcessingTime+"ms for "+$._mApp.mSampleProc.getNumberOfSamples()+" dots");			
		Sys.println("IntervalPlot memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	   
    
    }
}