using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// This file draws a Poincare plot of the HRV values
// Plot y = RR(i+1), x = RR(i) (or i and i-1)

// Simple method:
// 	scan through every sample, work out range and plot in x-y scatter
//	number of points could be ~300-1000 as have 5 minutes of roughly 50-150 samples (BPM). Worse case 200 BPM

// Grouping
//	We could scan data and find unique values and only plot these
//	Consumes lots of memory as need a flag per entry and order(N) reads of data ie N+(N-1)+(N-2) as we scan and mark used
//	Could do this scan every time value is added ie per second or so in which case plot reads once
//	Major issue is that it is a difference plot from previous which is important => would have to compare ajacent triplets

// Sampling
//	Only do every Nth/Nth-1 sample .. could potentially miss outliers which will be infrequent

//Drawing
//	Simplistically we would plot a point at each entry. This shows clustering if some variation but at scale of chart TBD
// could sample dataset

//Scaling
//	Min/max found as data captured. Scaling same in x and y as same data
//	Every single value would need scaling in both x and y though x becomes y of next sample
    
// use exclude in jungle for different screen formats ??? or layouts
// Largest square on a circular screen is 
// mRadius = dc.getwidth/2;
// height = width = mRadius / sqrt(2);
// top_left = (mRadius - width, mRadius - height);
// top_right = (mRadius + width, mRadius - height);
// bottom_left = (mRadius - width, mRadius + height);
// bottom_right = (mRadius + width, mRadius + height);	

// version 0.4.1
// Added another view version that shows full range of plot for all values of interval
// axis range is 30 BPM 2000ms to 220 BPM 273ms .. however should be resting so HRM should be max say 120 BPM or 500ms


class PoincareView extends Ui.View {

	// maybe updating every second is a little much
	const UPDATE_VIEW_SECONDS = 5;
	hidden var mShowCount;
	hidden var startTimeP;
	hidden var mProcessingTime;
	
	hidden var viewToShow;
	
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
    
    hidden var mTitleLoc = [50, 11]; // %
	hidden var mTitleLocS = [0,0];	
	hidden var mTitleLabels = ["Poincare", "Full range"];
	
	// coordinates of set of labels as %
	// split to 1D array to save memory
	// RR ms, TopValY, MidValY, LowerValY, TopValX, MidValX, LowerValX, 
	hidden var mLabelValueLocX = [ 50, 11, 11, 11, 75, 50, 29];
	hidden var mLabelValueLocY = [ 95, 82, 50, 18, 86, 86, 86];
	hidden var mLabelInterval = "RR ms";
		
	// x%, y%, width/height. 
	hidden var mRectHorizWH = 65;//64
	hidden var mRectHorizX = 17; // 18
	hidden var mRectHorizY = [ 17, 50, 82];//[ 18, 50, 82]

	hidden var mRectVertWH = 65; //64
	hidden var mRectVertY = 17; //18
	hidden var mRectVertX = [ 17, 50, 82 ];//[ 18, 50, 82]
	
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
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;

	// >0.4.1 add alternate view 
	function initialize(viewNum) { 
		viewToShow = viewNum;
		View.initialize();
	}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
	
	function onLayout(dc) {
		
		mShowCount = 0;
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
    	
    	mShowCount++;
		
		if ($._mApp.mDeviceType == RES_240x240) {	
			mLabelFont = customFont;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $._mApp.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}
		for (var i=0; i < mRectVertXS.size(); i++) {
			dc.drawRectangle(mRectVertXS[i], mRectVertYS, 2, mRectVertWHS);
		}
		
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[viewToShow-1], mJust);
		// draw "RR ms"
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mLabelFont, mLabelInterval, mJust);
		
    	// range saved in sampleprocessing already
    	var max;
    	var min;
    	if ( viewToShow == 1) {
			max = $._mApp.mSampleProc.maxIntervalFound;
			min = $._mApp.mSampleProc.minIntervalFound;
		} else {
			max = 60000/MIN_BPM; // 35 BPM in ms
			min = 60000/MAX_BPM; // 150 BPM
		}
		
		//Sys.println("Poincare: max, min "+max+" , "+min);

		// Create the range in blocks of 5
		var ceil = (max + 5) - (max % 5);
		var floor = min - (min % 5);
		if (floor < 0 ) { floor = 0;}
		
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		
		//Sys.println("Poincare: Ceil, floor "+ceil+" , "+floor);
				
		//var range = ceil - floor;
		var scaleY = chartHeight / (ceil - floor).toFloat();
		// for moment we have a square layout and hence same scaling!!
		// New main plot loop assumes this!!
		var scaleX = scaleY;
		
		//Sys.println("Poincare scale factors X Y :"+scaleX+" "+scaleY);
		
		// calc numbers on axis and update label
		var mid = floor + (ceil - floor) / 2;
		// as display area is tight on Y axis ONLY draw mid value
		
		dc.setColor( $._mApp.mLabelColour, Gfx.COLOR_TRANSPARENT);			
		//dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mLabelFont, format(" $1$ ",[ceil.format("%d")]), mJust);
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mLabelFont, format(" $1$ ",[mid.format("%d")]), mJust);	
		//dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mLabelFont, format(" $1$ ",[floor.format("%d")]), mJust);		
		dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mLabelFont, format(" $1$ ",[ceil.format("%d")]), mJust);
		dc.drawText( mLabelValueLocXS[5], mLabelValueLocYS[5], mLabelFont, format(" $1$ ",[mid.format("%d")]), mJust);	
		dc.drawText( mLabelValueLocXS[6], mLabelValueLocYS[6], mLabelFont, format(" $1$ ",[floor.format("%d")]), mJust);
			
		// Draw the data
		
		// set colour of rectangles. can't see white on white :-)
		if ($._mApp.bgColSet == 3) { // BLACK
			dc.setColor(Gfx.COLOR_WHITE, $._mApp.mBgColour);
		} else {
			dc.setColor(Gfx.COLOR_BLACK, $._mApp.mBgColour);
		}
		
		// reduce entries by 1 as points to next free slot
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples();
		
		// need two entries before we start!
		if ( mNumberEntries < 2) { return true;}
		
		// iterate through available data drawing rectangles as less expensive than circles
		// reduce number of array accesses
		var previousSample = $._mApp.mIntervalSampleBuffer[0];
		// can't do same with x value as maybe different scale factors
		
		// global access is up to 8x slower than local. Could potentially copy in as temp. but we only read each sample once!
		// assume scaleX and ScaleY are the SAME
		var mPrevY = ((previousSample - floor) * scaleX).toNumber();
		
		// try integer algo
		//var intScale = (scaleX * 64).toNumber();
		
		// DEBUG
		//var a = (1000 * intScale) >> 6;
		//var error = 1000*scaleX - a.toFloat();
		//Sys.println("a, IntScale, error = "+a+","+intScale+","+error);
		
		//var debugPlot = "x, y: ";

		// buffer starts from zero
		for( var i=1; i < mNumberEntries; i++ ){
			// Plot y = RR(i+1), x = RR(i) (or i and i-1)
			// should use getSample() in case of circular buffer implemented
			var sampleN1 = $._mApp.mIntervalSampleBuffer[i]; // y axis value to plot
			// work out x and y from numbers and scales
			var x = mPrevY; //((previousSample - floor) * scaleX).toNumber();
			var y = ((sampleN1 - floor) * scaleY).toNumber(); 
			
			// Ranging issue as rectangles drawn downwards and hence go over axis
			//if ( y <= 0) {
			//	Sys.println("whoops y below floor: SampleN1, y, floorY, floor "+sampleN1+", "+y+", "+floorY+", "+floor);
			//}
			// avoid floating point numbers
			//var y = ((sampleN1 - floor) * intScale) >> 5;
			// 2x2 rectangle too small on real screen
			dc.fillRectangle(leftX+x, floorY-y, 4, 4);
			//debugPlot += "("+(leftX+x).toString()+","+(floorY-y).toString()+"), ";
			//debugPlot += "("+(x).toString()+","+(y).toString()+"), ";			
			mPrevY = y;  //previousSample = sampleN1;
		}
		
		//Sys.println(debugPlot);
		
		// performance check only on real devices
		mProcessingTime = Sys.getTimer()-startTimeP;

   		return true;
    }
    
    function onHide() {
 		// performance check only on real devices
		//var currentTime = Sys.getTimer();
		Sys.println("Poincare executes in "+mProcessingTime+"ms for "+$._mApp.mSampleProc.getNumberOfSamples()+" dots");			
		Sys.println("Poincare memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	   
    
    }
}

// old code for asymmetric scales

		//var mBufferptr = 0; // does setting up a variable and equal array copy whole array???
		
		// iterate through available data drawing rectangles as less expensive than circles
		// reduce number of array accesses
		//var previousSample = $._mApp.mIntervalSampleBuffer[1];
		// can't do same with x value as maybe different scale factors
		

		// global access is up to 8x slower than local. Could potentially copy in as temp. but we only read each sample once!
		//var debugPlot = "x, y: ";
		//for( var i=2; i < mNumberEntries; i++ ){
			// Plot y = RR(i+1), x = RR(i) (or i and i-1)
			// should use getSample() in case of circular buffer implemented
			//var sampleN = $._mApp.mIntervalSampleBuffer[i]; // x axis value to plot
			//var sampleN1 = $._mApp.mIntervalSampleBuffer[i]; // y axis value to plot
			// work out x and y from numbers and scales
			//var x = ((previousSample - floor) * scaleX).toNumber();
			//var y = ((sampleN1 - floor) * scaleY).toNumber(); 
			//dc.fillRectangle(leftX+x, floorY-y, 3, 3);
			//debugPlot += "("+(leftX+x).toString()+","+(floorY-y).toString()+"), ";			
			//previousSample = sampleN1;
