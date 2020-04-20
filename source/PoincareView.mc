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

class PoincareView extends Ui.View {

	// maybe updating every second is a little much
	const UPDATE_VIEW_SECONDS = 5;
	hidden var mShowCount;
	
	hidden var mPoincareLayout;
	hidden var cGridWith;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	hidden var rightX;
	hidden var ceilY;
	hidden var floorY;

	function initialize() { View.initialize();}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
	
	function onLayout(dc) {
		mPoincareLayout = Rez.Layouts.PoincareViewLayout(dc);
		//Sys.println("PoincareView: onLayout() called ");
		if ( mPoincareLayout != null ) {
			setLayout(mPoincareLayout);
		} else {
			Sys.println("Poincare layout null");
		}
		
		mShowCount = 0;
		var a = Ui.loadResource(Rez.Strings.PoincareGridWidth);
		cGridWith = a.toNumber();
		
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
		
		return true;
	}
	
	hidden function updateLayoutField(fieldId, fieldValue, fieldColour) {
        var drawable = findDrawableById(fieldId);
        if (drawable != null) {
            drawable.setColor(fieldColour);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
    }

    //function scale(num) {
	//	return (((num - floorVar) * scaleVar) + 0.5).toNumber();
	//}

    //! Update the view
    function onUpdate(dc) {
    	// performance check
    	var startTime = Sys.getTimer();
    	
    	// if we need a local copy of data... this saves 8x time to access variables trading duplicate buffer
    	// var intervals = [ $._mApp.mSampleProc.getNumberOfSamples()];
    	// for(i=0; i < intervals.size(); i++) {
    	//	intervals[i] = $._mApp.mIntervalSampleBuffer[i];
    	// }
    	// HOWEVER we should only need to add new data NOT all the old samplesBUT this would only work on variables maintained
    	// between calls ie globals!! However some variables do seem to survice so ..
    	// in init would need to create buffer and initial pointer
    	// mLocalIntervalSampleBuffer = new [MAX_BPM * MAX_TIME];
    	
    	// shame simple assignment can't make access local ie
    	//var intervals = $._mApp.mIntervalSampleBuffer;
    	
    	mShowCount++;
    	   	
    	// draw the layout. remove if trying manual draw of layout elements
    	View.onUpdate(dc);
    	
    	// This should draw layout but doesn't. fails on draw(dc)
    	//for (var i = 0; i < mLayout.size(); ++i) {
		//	mLayout.draw(dc);
		//	Sys.println(i);
		//}
    	
    	// we could update less frequently if necessary
    	//var mRem = mShowCount % UPDATE_VIEW_SECONDS;
		//if ( mRem != 0) {
		//	var text = "Updating in "+(UPDATE_VIEW_SECONDS-mRem)+"secs";
		//	dc.drawText(ctrX, ctrY, Gfx.FONT_MEDIUM, text, Gfx.TEXT_JUSTIFY_VCENTER|Gfx.TEXT_JUSTIFY_CENTER);	
		//	return true;
		//}
    	
    	var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);

		updateLayoutField("PoincareTitle", null, mLabelColour);
		updateLayoutField("IntervalLbl", null, mLabelColour);
		
    	// range saved in sampleprocessing already
		var max = $._mApp.mSampleProc.maxIntervalFound;
		var min = $._mApp.mSampleProc.minIntervalFound;
		
		//Sys.println("Poincare: max, min "+max+" , "+min);

		// Create the range in blocks of 5
		var ceil = (max + 5) - (max % 5);
		var floor = min - (min % 5);
		
		var test = (ceil - floor) % 15;
		if (test == 5) { 
			floor -= 5;
		} else if (test == 10) {
			ceil += 5;
			floor -= 5;
		}

		//Sys.println("Poincare: Ceil, floor "+ceil+" , "+floor);
				
		//var range = ceil - floor;
		var scaleY = chartHeight / (ceil - floor).toFloat();
		// for moment we have a square layout and hence same scaling!!
		// New main plot loop assumes this!!
		var scaleX = scaleY;
		
		//Sys.println("Poincare scale factors X Y :"+scaleX+" "+scaleY);

		// Prepare the screen
		//MapSetColour(dc, TRANSPARENT, $._mApp.bgColSet);
		
		// calc numbers on axis and update label
		var mid = floor + (ceil - floor) / 2;
		// as display area is tight on Y axis ONLY draw mid value
		//updateLayoutField("TopValY", format(" $1$ ",[ceil.format("%d")]), mLabelColour);
		updateLayoutField("MidValY", format(" $1$ ",[mid.format("%d")]), mLabelColour);
		//updateLayoutField("LowerValY", format(" $1$ ",[floor.format("%d")]), mLabelColour);
		updateLayoutField("TopValX", format(" $1$ ",[ceil.format("%d")]), mLabelColour);
		updateLayoutField("MidValX", format(" $1$ ",[mid.format("%d")]), mLabelColour);
		updateLayoutField("LowerValX", format(" $1$ ",[floor.format("%d")]), mLabelColour);			
			
		// Draw the data
		var drawDots = 0;
		
		// set colour of rectangles. can't see white on white :-)
		if ($._mApp.bgColSet == BLACK) {
			MapSetColour(dc, WHITE, $._mApp.bgColSet);
		} else {
			MapSetColour(dc, BLACK, $._mApp.bgColSet);	
		}
		
		// reduce entries by 1 as points to next free slot
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples();
		
		Sys.println("Poincare # dots :"+mNumberEntries);
		
		// need two entries before we start!
		if ( mNumberEntries < 2) { return true;}
		
		// iterate through available data drawing rectangles as less expensive than circles
		// reduce number of array accesses
		var previousSample = $._mApp.mIntervalSampleBuffer[0];
		// can't do same with x value as maybe different scale factors
		
		// global access is up to 8x slower than local. Could potentially copy in as temp. but we only read each sample once!
		//var debugPlot = "x, y: ";
		// assume scaleX and ScaleY are the SAME
		var mPrevY = ((previousSample - floor) * scaleX).toNumber();
		
		// try integer algo
		//var intScale = (scaleX * 64).toNumber();
		
		// DEBUG
		//var a = (1000 * intScale) >> 6;
		//var error = 1000*scaleX - a.toFloat();
		//Sys.println("a, IntScale, error = "+a+","+intScale+","+error);
		
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
			//	Sys.println("whoops y below floor: y, floorY, floor "+y+","+floorY+","+floor);
			//}
			// avoid floating point numbers
			//var y = ((sampleN1 - floor) * intScale) >> 5;
			// 2x2 rectangle too small on real screen
			dc.fillRectangle(leftX+x, floorY-y, 4, 4);
			//debugPlot += "("+(leftX+x).toString()+","+(floorY-y).toString()+"), ";			
			mPrevY = y;  //previousSample = sampleN1;
		}
		
		//Sys.println(debugPlot);
		
		// perfromance check only on real devices
		var currentTime = Sys.getTimer();
		Sys.println("Poincare executes in "+ (currentTime-startTime)+"ms");			
		Sys.println("Poincare memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	
   		return true;
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
