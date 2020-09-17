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

// Code to add
// 1. Colour pulses
//	    Lower threshold exceeded = Pink
//	    Upper threshold exceeded = Purple
//	    Add text showing % delta from average
// 2. Average line
//		Blue line showing average at each point (use point X value to plot?). May need to recalc as not stored. Also watch for fewer samples than # beats to plot

// Data needed
// Threshold average from last 5 accepted as OK points
// Need to have scale for Y axis based on average range ? Needs to be entire II range as per Poincare.
// Point status as per sample processing



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
    	
    	var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		if ($._mApp.mDeviceType == RES_240x240) {	
			mLabelFont = customFont;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, mapColour($._mApp.bgColSet));
		dc.clear();
		
		// draw lines
		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
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
    	// smallest value is 0 as timing from previous beat
    	min = 0;
    	max = sumII;
    			
		//Sys.println("Beatview: max, min "+max+" , "+min);

		// Create the range in blocks of 5
		var ceil = (max + 5) - (max % 5);
		var floor = min - (min % 5);
		if (floor < 0 ) { floor = 0;}
		
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		
		//Sys.println("BeatView: Ceil, floor "+ceil+" , "+floor);
				
		//var range = ceil - floor;
		var scaleX = chartHeight / (ceil - floor).toFloat();
		
		//Sys.println("BeatView scale factor X: "+scaleX);
		
		dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
		// now draw graph
		var sample;
		var incSum = min;
		
		// how far up Y axis to start line in pixels
		var yBase = ((floor+200) * scaleX).toNumber();
		// where to start HR line from on X axis. Min is half 1st sample
		
		var StartX_unscaled = $._mApp.mIntervalSampleBuffer[mNumberEntries-1-mSampleNum] / 2;
		var xBase = ((StartX_unscaled-floor) * scaleX).toNumber();
		
		// need a line to first pulse - should be on same Y point
		var mYBaseline = floorY-yBase;
				
		var firstPass = true;
		var mXcoord = 0;
		var cHeight = ((mYBaseline-ceilY) *2 ) /3; 
		var cOffset = mYBaseline-cHeight;
		
		// -1 on end test as showing one more than needed
		for( var i = mNumberEntries-1-mSampleNum; i < mNumberEntries-1; i++ ){		
			sample = $._mApp.mIntervalSampleBuffer[i];
			
			if (firstPass ==true) {
				// offset half of pulse
				dc.drawLine( leftX, mYBaseline, leftX+xBase, mYBaseline);					
				firstPass = false;
				mXcoord = 0;
			} else {	
				mXcoord = ((sample - floor) * scaleX).toNumber();
				// draw line from previous sample or Y axis to sample point
				dc.drawLine( leftX+xBase, mYBaseline, leftX+mXcoord+xBase, mYBaseline);
			}
			
			//var a = leftX+mXcoord+xBase;
			//var b = cHeight;
			//Sys.println("BestView: Sample: "+sample+" Rect x="+a+" rect Y="+mYBaseline+" rect H="+b);
			
			// draw spike from Y base to top of chart x, y, w, h		
			dc.fillRectangle(leftX+mXcoord+xBase, cOffset, 3, cHeight);			
			
			// move base
			xBase += mXcoord;
						
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