using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.UserProfile;

//0.4.9
//This file draws a graph of a Interval against sample number
//Add in future ecoptic status etc
// We need value on Y axis of range which maybe dynamic (based on datastream or fixed)

// NOTE: The interval plot is the inverse of the BPM plot. the top of the graph is the slowest/longest beat

// what to increment X by on point plot AND also defines number of points to plot
// always power of 2
const X_INC_VALUE = 4;

class IntervalView extends Ui.View {
	// INTERVAL PLOT
	const FAST_II = 430; // 140 bpm 
	const SLOW_II = 1800; // 33bpm - move to one based on resting HR

	hidden var startTimeP;
	hidden var mProcessingTime;
	
	//hidden var customFont = null;

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
		
	hidden var mLabelFont = null;
	hidden var mValueFont = Gfx.FONT_XTINY;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_BLUE;
	hidden var mBeatColour = Gfx.COLOR_RED;
		
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;
	
	// points to plot
	hidden var cNumPoints = null;
	hidden var gg;
	
	hidden var mRestingHR_II;
	hidden var mZone1TopHR_II;

	function initialize() { 
		gg = $._mApp;
		View.initialize();
	}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
	
	function onLayout(dc) {
		
		var a = Ui.loadResource(Rez.Strings.PoincareGridWidth);
		cGridWith = a.toNumber();
		a = null;
		
		// chartHeight defines height of chart and sets scale
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
		
		// Decide how many samples to plot across
		cNumPoints = chartHeight / X_INC_VALUE;
		
		// get resting heart rate
		var restingHR = UserProfile.getProfile().restingHeartRate;
		var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
		
		// average resting is 3.2.0 feature so remove
		//Sys.println("Resting HR = "+profile.restingHeartRate+", avg ="+profile.averageRestingHeartRate);
		
		// set floor on fixed scaling for II - provide a little headroom of 5bpm as mine varies below watch value 5%
		
		// RANGE CHECK restingHeart rate and zone 1 to make sure sensible		
		//mRestingHR_II = ( profile.restingHeartRate == null ? SLOW_II : (60000 / (profile.restingHeartRate * 0.95)).toNumber());
		mRestingHR_II = ( restingHR == null ? SLOW_II : (60000 / (restingHR * 0.95)).toNumber());
		if (zones != null && zones[1] != null) {
			mZone1TopHR_II = (60000 / (zones[1] * 1.05)).toNumber();
		} else {		
			mZone1TopHR_II = FAST_II;
		}
		
		//profile = null;
		restingHR = null;
		zones = null;
				
		Sys.println("Floor HR ms = "+mRestingHR_II+" BPM: "+60000/mRestingHR_II);
		Sys.println("Top HR ms = "+mZone1TopHR_II+" BPM: "+60000/mZone1TopHR_II);
										
		return true;
	}
	
    //! Update the view
    function onUpdate(dc) {
    	// performance check
    	startTimeP = Sys.getTimer();
		
		if (gg.mDeviceType == RES_240x240) {
			if (mLabelFont == null) {
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, gg.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( gg.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
		// X range is unscaled and just point number out of range
    	  	
    	// y range needed for plot
    	var Ymin = 2500;
    	var Ymax = 0;
   	
		// if no sample processing then exit 
    	if (gg.mSampleProc == null ) { return true;}
    	
    	// reduce entries by 1 as points to next free slot    	
		var mNumberEntries = gg.mSampleProc.getNumberOfSamples();
		// how many points to plot
    	var mSampleNum = 0;
    	
     	// check we have enough samples   	   			
		// need two entries before we start!
		if ( mNumberEntries < 2) { return true;}
    	
    	// where to read buffer from
    	var mStartIndex = null;
    	// use <= to avoid Index=-1 when equal to each other
    	if ( mNumberEntries <= cNumPoints) {
    		mSampleNum = mNumberEntries-1;
    		mStartIndex = 0; // start of buffer
    	} else {
    		mSampleNum = cNumPoints;
    		mStartIndex = mNumberEntries - mSampleNum - 1;
    	}
    	
    	//Sys.println("IntervalPlot: Ploting: "+mSampleNum+" samples starting from "+mStartIndex+" Entries ="+mNumberEntries+" and allowed pts ="+cNumPoints);
    	
    	//Sys.println("IntervalPlot: mBoolScaleII = "+gg.mBoolScaleII);
    			
		// True if auto scaling on 
		if (!gg.mBoolScaleII) {
			Ymax = mRestingHR_II;
			Ymin = mZone1TopHR_II;
		} else {
	    	// scan array to be plotted looking for min and max
	    	// Could reduce to viewed portion
	    	var value;
	    	for( var i = mStartIndex; i < mNumberEntries-1; i++ ){	
				// first iteration this is end point	
				value = gg.mIntervalSampleBuffer[i] & 0x0FFF;
				if(Ymin > value) {
					Ymin = value;
				}
				if(Ymax < value) {
					Ymax = value;
				}
			}
			value = null;				
		}
    	
    	// Create the range in blocks of 5
		var ceil = (Ymax + 5) - (Ymax % 5);
		var floor = Ymin - (Ymin % 5);
		if (floor < 0 ) { floor = 0;}
		
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		
		Ymin = null;
		Ymax = null;
		test = null;
		
		var scaleY = chartHeight / (ceil - floor).toFloat();

		//var scaleY = chartHeight / (Ymax - Ymin).toFloat();		
		
		// now draw graph
		var sample = gg.mIntervalSampleBuffer[mStartIndex] & 0x0FFF;
		var mIIState = 0;
		var mY0 = floorY - ((sample-floor) * scaleY).toNumber();
		var mX0 = leftX;
		var mY1;
		
		// we go from mStartIndex until used all mSampleNum		
		for( var i = mStartIndex+1; i < mNumberEntries-1; i++ ){	
			// first iteration this is end point				
			sample = gg.mIntervalSampleBuffer[i];
			mIIState = (sample >> 12) & 0x000F;
			sample = sample & 0x0FFF;
			
			dc.setPenWidth(2);
			
			if (mIIState == SAMP_L) {
				// LONG BEAT FOUND
				dc.setColor( Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
				//Sys.println("PURPLE index i = "+i );	
				dc.setPenWidth(4);
			} 
			else if (mIIState == SAMP_S) {
				// SHORT BEAT FOUND
				dc.setColor( Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
				//Sys.println("PINK index i = "+i);
				dc.setPenWidth(4);
			}
			else if ( mIIState == SAMP_LS|| mIIState == SAMP_SL) {
				//case 6: Long and ECTOPIC BEAT FOUND				
				// case 9: SHORT and ECTOPIC BEAT FOUND
				dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
				//Sys.println("YELLOW index i = "+i );
				dc.setPenWidth(4);	
			} else {
				// default line colour is red		
				dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
			}	// end colour choice	
						
			mY1 = floorY - ((sample-floor) * scaleY).toNumber();
			
			dc.drawLine(mX0, mY0, mX0+X_INC_VALUE, mY1);
			//Sys.println("IntervalPlot: sample, "+sample+" line from : mX0, mY0 "+mX0+", "+mY0+" to "+mX0+"+1, "+mY1);
			
			mX0 = mX0+ X_INC_VALUE;
			mY0 = mY1;
						
		} // end sample loop
		
		dc.setColor( gg.mLabelColour, Gfx.COLOR_TRANSPARENT);
				
		// label avg axis
		//var mXoffset = ( gg.mDeviceType == RES_240x240 ? leftX+25 : leftX+20);
		dc.drawText( ( gg.mDeviceType == RES_240x240 ? leftX+25 : leftX+22), ceilY, mLabelFont, format("$1$",[ceil.format("%4d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );
		dc.drawText( ctrX, floorY+10, mLabelFont, format("$1$",[floor.format("%4d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );		
		//dc.drawLine( leftX+5, ctrY, rightX, ctrY);
			
		// performance check only on real devices
		mProcessingTime = Sys.getTimer()-startTimeP;

   		return true;
    }
        
    function onHide() {
 		// performance check only on real devices
		//var currentTime = Sys.getTimer();
		Sys.println("IntervalPlot executes in "+mProcessingTime+"ms for "+gg.mSampleProc.getNumberOfSamples()+" dots");			
		//Sys.println("IntervalPlot memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	 
		mLabelFont = null;  
    
    }
}