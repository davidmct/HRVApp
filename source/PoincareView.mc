using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// look at sensor example for line graph

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
// 	dc.drawPoint(x, y)
//	Could draw circle/rectangle but execution time much higher
//	Every single value would need scaling in both x and y though x becomes y of next sample
//Scaling
//	Will need to run through all data finding min and max .. or capture as data comes in!!! Scaling same in x and y as same data

class PoincareView extends Ui.View {

	hidden var floorVar;
	hidden var scaleVar;
	
	hidden var mPoincareLayout;

	function initialize() { View.initialize();}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }
	
	function onLayout(dc) {
		mPoincareLayout = Rez.Layouts.PoincareViewLayout(dc);
		Sys.println("PoincareView: onLayout() called ");
		if ( mPoincareLayout != null ) {
			setLayout(mPoincareLayout);
		} else {
			Sys.println("layout null");
		}
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

    function scale(num) {
		return (((num - floorVar) * scaleVar) + 0.5).toNumber();
	}

    //! Update the view
    function onUpdate(dc) {
    
    	// use exclude in jungle for different screen formats ??? or layouts
		// Largest square on a circular screen is 
		// mRadius = dc.getwidth/2;
		// height = width = mRadius / sqrt(2);
		// top_left = (mRadius - width, mRadius - height);
		// top_right = (mRadius + width, mRadius - height);
		// bottom_left = (mRadius - width, mRadius + height);
		// bottom_right = (mRadius + width, mRadius + height);	
		
		// will need to work out range on X which is same as Y
		// draw overall box
		// draw grid lines on both dimensions at say N_GRID_LINES (odd number), goes beyond axis lines left and bottom
		// Make centre grid marker bolder or longer
		// put median variation at this point and label
		// need left and right range labels eg
		// Lowest value - a bit, median, Highest plus a bit : might be very small!
		// draw the layout
    	View.onUpdate(dc);
    	
    	var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		updateLayoutField("PoincareTitle", null, mLabelColour);
		updateLayoutField("IntervalLbl", null, mLabelColour);
		
    	// range saved in sampleprocessing already
		var max = $._mApp.mSampleProc.maxIntervalFound;
		var min = $._mApp.mSampleProc.minIntervalFound;

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
		var range = ceil - floor;
		
		// chartHeight defines height of chart and sets scale
		// needs to divide by 6 for horizontal lines
		// impacts all layout numbers!
		var chartHeight = 180;
		var scaleY = chartHeight / range.toFloat();
		// for moment we have a square layout and hence same scaling!!
		var scaleX = scaleY;
		
		Sys.println("Poincare scale factors X Y :"+scaleX+" "+scaleY);

		var ctrX = dc.getWidth() / 2;
		var ctrY = dc.getHeight() / 2;
		// define box about centre
		var leftX = ctrX - 90;
		var rightX = ctrX + 90;
		// 45 *2 is height of chart
		var ceilY = ctrY - chartHeight/2;
		var floorY = ctrY + chartHeight/2;

		// Prepare the screen
		MapSetColour(dc, TRANSPARENT, $._mApp.bgColSet);
		
		// calc numbers on axis and update label
		var mid = (ceil - floor) / 2;
		updateLayoutField("TopValY", format(" $1$ ",[ceil.format("%d")]), mLabelColour);
		updateLayoutField("MidValY", format(" $1$ ",[mid.format("%d")]), mLabelColour);
		updateLayoutField("LowerValY", format(" $1$ ",[floor.format("%d")]), mLabelColour);
		updateLayoutField("TopValX", format(" $1$ ",[ceil.format("%d")]), mLabelColour);
		updateLayoutField("MidValX", format(" $1$ ",[mid.format("%d")]), mLabelColour);
		updateLayoutField("LowerValX", format(" $1$ ",[floor.format("%d")]), mLabelColour);			
			
		//var num = ceil - ((i * gap) / 2.0);
		//if(num != num.toNumber()) {
			// may need to stagger on smaller screens
			//dc.drawText(textX + 35, y, font, format(" $1$ ",[num.format("%0.1f")]), just);
		//	dc.drawText(textX, y, font, format(" $1$ ",[num.format("%0.1f")]), just);				
		//	}
		//	else {
		//		//dc.drawText(textX + 35, y, font, format(" $1$ ",[num.format("%d")]), just);
		//		dc.drawText(textX, y, font, format(" $1$ ",[num.format("%d")]), just);
		//	}
		//}

		// Draw the data
		var drawDots = 0;
		MapSetColour(dc, ORANGE, $._mApp.bgColSet);
		// reduce entries by 1 as points to next free slot
		var mNumberEntries = $._mApp.mSampleProc.getNumberOfSamples()-1;
		
		Sys.println("Poincare plotting # :"+mNumberEntries);

		var mBufferptr = 0; // does setting up a variable and equal array copy whole array???
		
		// iterate through available data drawing rectangles as less expensive than circles
		// reduce number of array accesses
		var previousSample = $._mApp.mIntervalSampleBuffer[1];
		// can't do same with x value as maybe different scale factors
		
		for( var i=2; i < mNumberEntries; i++ ){
			// Plot y = RR(i+1), x = RR(i) (or i and i-1)
			// should use getSample() in case of circular buffer implemented
			//var sampleN = $._mApp.mIntervalSampleBuffer[i]; // x axis value to plot
			var sampleN1 = $._mApp.mIntervalSampleBuffer[i]; // y axis value to plot
			// work out x and y from numbers and scales
			var x = (previousSample * scaleX).toNumber();
			var y = (sampleN1 * scaleY).toNumber(); 
			dc.drawRectangle(leftX+x, floorY-y, 2, 2);			
			//dc.fillCircle(leftX + x, floorY - y, 2);
			previousSample = sampleN1;
		}
		
   		return true;
    }
}