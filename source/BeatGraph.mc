using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

//0.4.6 
//This file draws a graph of a number of beats scaled to fix axis

//Algo
// Find sum of beats in range
// Scale factor for X axis based on rounded version of this
// Need to plot
//		Line to point of beat x (II interval scaled and offset from origin
//		Vertical rectangle at point X width 2(?)
//		repeat for all beats
// IF we had double/skipped indicator could draw in different colour!!


class BeatView extends Ui.View {

	hidden var startTimeP;
	hidden var mProcessingTime;
	
	hidden var customFont = null;
		
	//hidden var mPoincareLayout;
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
	hidden var mTitleLabels = ["Beats"];
	
	// coordinates of set of labels as %
	// split to 1D array to save memory
	// RR ms, TopValY, MidValY, LowerValY, TopValX, MidValX, LowerValX, 
	hidden var mLabelValueLocX = [ 50, 11, 11, 11, 75, 50, 29];
	hidden var mLabelValueLocY = [ 95, 82, 50, 18, 86, 86, 86];
	hidden var mLabelInterval = "RR ms";
		
	// x%, y%, width/height. 
	hidden var mRectHorizWH = 65;//64
	hidden var mRectHorizX = 17; // 18
	hidden var mRectHorizY = [ 82];//[ 17, 50, 82]

	hidden var mRectVertWH = 65; //64
	hidden var mRectVertY = 17; //18
	hidden var mRectVertX = [ 17];//[ 17, 50, 82]
	
	// scaled variables
	hidden var mLabelValueLocXS = new [ mLabelValueLocX.size() ];
	hidden var mLabelValueLocYS = new [ mLabelValueLocY.size() ];
	
	hidden var mRectHorizWHS = 0;
	hidden var mRectHorizXS = 0;
	hidden var mRectHorizYS = new [mRectHorizY.size() ];
	
	hidden var mRectVertWHS = 0;
	hidden var mRectVertYS = 0;
	hidden var mRectVertXS = new [mRectVertX.size() ];
		
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
				
		for( var i=0; i < mLabelValueLocXS.size(); i++) {
			mLabelValueLocXS[i] = (mLabelValueLocX[i] * mScaleX)/100;	
			mLabelValueLocYS[i] = (mLabelValueLocY[i] * mScaleY)/100;
		}	
								
		for( var i=0; i < mRectHorizYS.size(); i++) {
			mRectHorizYS[i] = (mRectHorizY[i] * mScaleY)/100;		
		}	
		mRectHorizWHS = (mRectHorizWH * mScaleX)/100;
		mRectHorizXS = (mRectHorizX * mScaleX)/100;
		
		for( var i=0; i < mRectVertXS.size(); i++) {
			mRectVertXS[i] = (mRectVertX[i] * mScaleY)/100;		
		}	
		mRectVertWHS = (mRectVertWH * mScaleX)/100;
		mRectVertYS = (mRectVertY * mScaleX)/100;
						
		return true;
	}
	
    //! Update the view
    function onUpdate(dc) {
    	// performance check
    	startTimeP = Sys.getTimer();
    	
    	var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		if ($._mApp.mDeviceType == RES_240x240) {	
			mLabelFont = customFont;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, mapColour($._mApp.bgColSet));
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}
		for (var i=0; i < mRectVertXS.size(); i++) {
			dc.drawRectangle(mRectVertXS[i], mRectVertYS, 2, mRectVertWHS);
		}
		
	
		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		// draw "RR ms"
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mLabelFont, mLabelInterval, mJust);
		
    	// Range determined by sum of previous N samples 
    	var max;
    	var min;
  	
    	// check we have enough samples
    	
    	// reduce entries by 1 as points to next free slot
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples();
		// how many points to plot
    	var mSampleNum = 0;
    	   			
		// need two entries before we start!
		if ( mNumberEntries < 2) { return true;}
    	
    	if ( mNumberEntries <= $._mApp.mNumberBeatsGraph) {
    		mSampleNum = mNumberEntries-1;
    	} else {
    		mSampleNum = $._mApp.mNumberBeatsGraph;
    	}
    	
    	Sys.println("BeatView: mNumberEntries, mSampleNum: "+mNumberEntries+" "+mSampleNum);
    	
    	// work out X range covered
    	var sumII = 0;
    	for (var i=0; i < mSampleNum; i++) {
    		//var temp;
    		//temp = mNumberEntries-i;
    		//var value = $._mApp.mIntervalSampleBuffer[mNumberEntries-i-1];
    		//Sys.println("BeatView: temp, value: "+temp+" "+value);
    		sumII += $._mApp.mIntervalSampleBuffer[mNumberEntries-i-1];
    	}
    	
    	// We'll offset the x-axis by half the first sample so we can see final one
    	// We'll have a running sum of position on axis which is scaled
    	// leave numbering axis for now
    	
    	// Assume last sample of previous batch starts at zero. Move half way to next sample
    	min = $._mApp.mIntervalSampleBuffer[mNumberEntries-1-mSampleNum] / 2;
    	max = sumII + min;
    			
		Sys.println("Poincare: max, min "+max+" , "+min);

		// Create the range in blocks of 5
		var ceil = (max + 5) - (max % 5);
		var floor = min - (min % 5);
		if (floor < 0 ) { floor = 0;}
		
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		
		Sys.println("BeatView: Ceil, floor "+ceil+" , "+floor);
				
		//var range = ceil - floor;
		var scaleX = chartHeight / (ceil - floor).toFloat();
		
		Sys.println("BeatView scale factor X: "+scaleX);
		
		
		// calc numbers on axis and update label
		//var mid = floor + (ceil - floor) / 2;
		//// as display area is tight on Y axis ONLY draw mid value
		
		//dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);			
		////dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mLabelFont, format(" $1$ ",[ceil.format("%d")]), mJust);
		//dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mLabelFont, format(" $1$ ",[mid.format("%d")]), mJust);	
		////dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mLabelFont, format(" $1$ ",[floor.format("%d")]), mJust);		
		//dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mLabelFont, format(" $1$ ",[ceil.format("%d")]), mJust);
		//dc.drawText( mLabelValueLocXS[5], mLabelValueLocYS[5], mLabelFont, format(" $1$ ",[mid.format("%d")]), mJust);	
		//dc.drawText( mLabelValueLocXS[6], mLabelValueLocYS[6], mLabelFont, format(" $1$ ",[floor.format("%d")]), mJust);
			
		// Draw the data
		
		// set colour of rectangles. can't see white on white :-)
		if ($._mApp.bgColSet == BLACK) {
			MapSetColour(dc, WHITE, $._mApp.bgColSet);
		} else {
			// SHOULDn'T this be BLACK, WHITE??
			MapSetColour(dc, BLACK, $._mApp.bgColSet);	
		}
		
		
		// now draw graph
		var sample;
		var incSum = min;
		
		// how far up Y axis to start line in pixels
		var yBase = ((floor+10) * scaleX).toNumber();
		// where to start HR line from on X axis. Min is half 1st sample
		var xBase = ((min-floor) * scaleX).toNumber();
		
		// need a line to first pulse
		dc.drawLine( leftX, floorY-yBase, leftX+xBase, floorY);		
		
		for( var i = mNumberEntries-1-mSampleNum; i < mNumberEntries; i++ ){		
			sample = $._mApp.mIntervalSampleBuffer[i];
			
			var mXcoord = ((sample - floor) * scaleX).toNumber();
			
			var a = leftX+mXcoord+xBase;
			var b = floorY-yBase;
			Sys.println("BestView: mXcoord, xBase, leftX+mXcoord+xBase, floorY-yBase, ceilY "+mXcoord+" "+a+" ", floorY-yBase, ceilY
			
			// draw spike from Y base to top of chart x, y, w, h		
			dc.fillRectangle(leftX+mXcoord+xBase, floorY-yBase, 4, ceilY);			
			
			// move base
			xBase += mXcoord;
						
			// draw line from previous sample or Y axis to sample point
			dc.drawLine( leftX+xBase, floorY-yBase, 4, floorY-yBase);
						
		} // end sample loop
		
		// performance check only on real devices
		mProcessingTime = Sys.getTimer()-startTimeP;

   		return true;
    }
    
    function onHide() {
 		// performance check only on real devices
		//var currentTime = Sys.getTimer();
		Sys.println("BeatGraph executes in "+mProcessingTime+"ms for "+$._mApp.mSampleProc.getNumberOfSamples()+" dots");			
		Sys.println("BeatGraph memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	   
    
    }
}