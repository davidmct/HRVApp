using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

//0.4.7 
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
//		Plot delta of current II compared to average of last 5 samples - on ectopic beat then avg does not include ecoptic beat ie needs to be 5 preceeding these events. 
//			Plot % difference. 0% is mid-point of scale
//		avg line should be scaled for min/max of current set of data ie set of averages for all points to be displayed then make centre mid point
//			Two approaches here
//			1. avg line scale is min/max of plotted data set. Shows changing average magnified. Possible issue if not changing much as would give exaggerated scale - need to test
//				and expand range
//			2. scale is based on 1st average and current min/max II delta as upper and lower limts. Then can plot labels. Maybe too compressed scale
// NOTE. Only actual II value is stored and not delta. min/max gloabl variables are delta based not II 

// RunningAverage( start, length) - function in sample processing
// Data needed
// Threshold average from last 5 accepted as OK points
// Need to have scale for Y axis based on average range ? Needs to be entire II range as per Poincare.
// Point status as per sample processing



class BeatView extends Ui.View {

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
	hidden var mTitleLabels = ["Beats"];
		
	hidden var mLabelFont = null; //Gfx.FONT_XTINY;
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
		
		//if ($._mApp.mDeviceType == RES_240x240) {		
		//	customFont = Ui.loadResource(Rez.Fonts.smallFont);
		//}
		
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
			if (mLabelFont == null) {
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
				
		dc.setColor( Gfx.COLOR_TRANSPARENT, $._mApp.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
    	// X Range determined by sum of previous N samples 
    	var max;
    	var min;
    	
    	// y range needed for AVG plot
    	var Ymin = 2000;
    	var Ymax = 0;
    	
    	// average values
    	var a = new[2];
   	
		// if no sample processing then exit 
    	if ($._mApp.mSampleProc == null ) { return true;}
    	
    	// reduce entries by 1 as points to next free slot    	
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples();
		// how many points to plot
    	var mSampleNum = 0;
    	
     	// check we have enough samples   	   			
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
		
		// work out Y range   	
    	for (var i=0; i < mSampleNum; i++) {   	
    		var a = $._mApp.mSampleProc.aAvgStore[i];
			// check we have this number of entries - shouldn't happen once code complete
			if ((a == null) || (a == 0.0)) {
				// ignore
			} else {
    	    	if (a < Ymin) { Ymin = a;}
    			if (Ymax < a) { Ymax = a;}
    		}
    	}
    	
    	// expand Y but make sure +ve
    	Ymin = (Ymin-50 >= 0? Ymin-50: Ymin); 
    	Ymax += 50;
 
		// Y scale could be very narrow if all values the same so add 50 to top and bottom
		var scaleY = chartHeight / (Ymax - Ymin).toFloat();
		scaleY = scaleY / 1.5; // compress scale as don't want to overflow pulse rectangle area
		
		Sys.println("Beatview: Ymin:Ymax = "+Ymin+" : "+Ymax);
		Sys.println("BeatView: chartHeight: "+chartHeight+" scale factor X: "+scaleX+" scale Y = "+scaleY);

		// now draw graph
		var sample;
		var incSum = min;
		
		// where to start HR line from on X axis. 	
		var StartX_unscaled = 0;
		var xBase = ((StartX_unscaled-floor) * scaleX).toNumber();
		var mXcoord = 0;
		
		// beat width
		var mPulseWidth = 4;
		
		// index from 0 to determine state of particular beat
		var mFlagOffset = mSampleNum-1;
		
		// -1 on end test as showing one more than neede
		
		// Going to plot labels as another loop to make logic easier as averages need to skill excoptic beats!
		var mXdata = new [mSampleNum];
		// market as ectopic so use sample processing average
		var mIgnoreSample = new [mSampleNum];
		var mXDataIndex = 0; // could have done using mFlagOffset and reverse but more complex
		var mSampleStartIndex = mNumberEntries-1-mSampleNum;
		
		// Setup Y structure of bar plots and text
		// 10% top and bottom
		var cBorder = ((chartHeight * 20) / 100).toNumber();
		var mColStart = ceilY+cBorder;
		var mColHeight = chartHeight - 2 * cBorder;
		
		for( var i = mSampleStartIndex; i < mNumberEntries-1; i++ ){		
			sample = $._mApp.mIntervalSampleBuffer[i];
			
			// default line colour is red		
			dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
			
			//Spike colour is dependent on the status
			// 1. Colour pulses
			//	    Lower threshold exceeded = Pink
			//	    Upper threshold exceeded = Purple
			//	    Add text showing % delta from average
			// vLongFlag - assume that bit 0 equals current sample
			// vShortFlag;
			// i starts at mNumberEntries-1-mSampleNum which is earliest pulse

						
			mXcoord = ((sample - floor) * scaleX).toNumber();
						
			var mLowerTrue = (1 << mFlagOffset) & $._mApp.mSampleProc.vShortFlag;
			var mUpperTrue = (1 << mFlagOffset) & $._mApp.mSampleProc.vLongFlag;	
			//Sys.println("Values of flag -Upper/Lower : "+mUpperTrue+"/"+mLowerTrue);
			
			mIgnoreSample[mXDataIndex] = true;
							 
			if ((mLowerTrue != 0) && (mUpperTrue == 0)) {
				dc.setColor( Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
				Sys.println("PINK index i = "+i+" mFlagOffset  = "+mFlagOffset );	
				mPulseWidth = 6;	
			} else if ((mUpperTrue != 0) && (mLowerTrue == 0)) {
				dc.setColor( Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
				Sys.println("PURPLE index i = "+i+" mFlagOffset  = "+mFlagOffset );	
				mPulseWidth = 6;			
			} else {
				// default is sample is OK
				mIgnoreSample[mXDataIndex] = false;	
			}
			
			// save X co-coord for avg plot and labels
			mXdata[mXDataIndex] = leftX+mXcoord+xBase;
			mXDataIndex++;

			// draw spike from Y base to top of chart x, y, w, h
			dc.fillRectangle(leftX+mXcoord+xBase, mColStart, mPulseWidth, mColHeight);			
			
			// move base
			xBase += mXcoord;
						
			// move to next flag
			mFlagOffset--;
						
		} // end sample loop
				
		//Label and avg plot code
		
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);
		
		// now we have averages and X location so can plot text
		var mStr;
		var mDeltaPc;
		var mTxtSize = dc.getTextDimensions("000", mLabelFont);
		var yPos;
		var xPos;
		var y2 = 0; 
		// We want to centre avg on graph about ctrY
		var mAvgOffset = ((Ymax-Ymin)/2)+Ymin;
		// Actual difference between avg value and mid-point of range
		var mDeltaAvg = 0;
		var y1 = ctrY;		

		dc.setPenWidth(1);
				
		// label avg axis
		dc.drawText( leftX+5, mColStart, mLabelFont, format("$1$",[Ymax.format("%d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );
		dc.drawText( leftX, ctrY, mLabelFont, format("$1$",[mAvgOffset.format("%d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );
		dc.drawText( leftX+5, mColHeight+mColStart, mLabelFont, format("$1$",[Ymin.format("%d")]), Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER );		
		dc.drawLine( leftX+5, ctrY, rightX, ctrY);
		
		dc.setPenWidth(3);
				
		for ( var i = 0; i < mSampleNum; i++) {
			// mXdata[] has x value
			// text needs to be above bar (may need to alternate top/bottom)
			// cOffset should be top of bar as they are drawn downwards to larger y
			var a0 = $._mApp.mSampleProc.aAvgStore[mSampleNum-i-1];
			var a1 = $._mApp.mSampleProc.aIIValue[mSampleNum-i-1];
			// a[0] can be used to plot avg line but need to scale across all of them
			// a[1] is II sample
			
			Sys.println("Beatgraph plot samples: "+a0+" ,"+a1);
			
			// check we have this number of entries - shouldn't happen once code complete
			// force average for line to sensible value
			if ((a0 == null) || (a1 == null) || (a0 == 0.0)) {
				mDeltaPc = 0;
				mDeltaAvg = 0;
				y1 = ctrY;
				y2 = y1;
			} else {
				mDeltaPc = 100 * (( a1.toFloat() - a0) / a0);
				// bigger II means higher on screen = negative offset
				// correct Y for widening YMin value eearlier on min/max search
				mDeltaAvg = a0 - mAvgOffset;
				y2 = (ctrY - scaleY * mDeltaAvg).toNumber(); //(floorY - scaleY * (a0 - Ymin.toFloat())).toNumber()+20;
			}
			
			//Sys.println("mDelatPc = "+ mDeltaPc+", ctrY: "+ctrY+", a0 "+a0+", y1:y2= ["+y1+","+y2+"]");
			
			// no % symbol as not in custom font yet
			mStr = format("$1$",[mDeltaPc.format("%d")]);

			// move text half width
			xPos = mXdata[i] + mTxtSize[0]/4;
			
			if ((i % 2) == 0) {
				yPos = mColStart-10;
			} else {
				yPos = mColStart+mColHeight+10;
			}
			
			dc.drawText( xPos, yPos, mLabelFont, mStr, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER );
			// Draw average line in same colour. Line starts from previous sample to next
			if (i != 0) {
				dc.drawLine(mXdata[i-1], y1, mXdata[i], y2 );
			}
			y1 = y2;					
		}
			
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
	
		mLabelFont = null;   
    
    }
}