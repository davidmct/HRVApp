using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// look at sensor example for line graph

// This file draws a Poincare plot of the HRV values
// Ploy y = RR(i+1), x = RR(i) (or i and i-1)

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
		var chartHeight = 120;
		var scaleY = chartHeight / range.toFloat();

		floorVar = floor;
		scaleVar = scaleY;

		var font = Gfx.FONT_XTINY; //0
		var just = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER; //5
		var ctrX = dc.getWidth() / 2;
		var ctrY = dc.getHeight() / 2;
		// define box about centre
		var leftX = ctrX - 90;
		var rightX = ctrX + 90;
		// 45 *2 is height of chart
		var ceilY = ctrY - chartHeight/2;
		var floorY = ctrY + chartHeight/2;
		var mLabelOffsetCeil = ceilY - 15;
		var mLabelOffsetFloor = floorY + 20;		
		var textX = leftX - 20; // was +
		var gap = (ceil - floor) / 3;

		// Prepare the screen
		MapSetColour(dc, TRANSPARENT, $._mApp.bgColSet);
		
		// Draw the lines
		MapSetColour(dc,DK_GRAY, $._mApp.bgColSet);
		for(var i = 0; i < 7; i++) {
			var y = ceilY + i * chartHeight/6;
			dc.drawLine(leftX, y, rightX, y);
		}

		// NEED TO CHANGE TITLE COLOUR	
        var drawable = findDrawableById("PoincareTitle");
        if (drawable != null) {
            drawable.setColor(mapColour( $._mApp.lblColSet));
		}

		// Draw the numbers
		MapSetColour(dc, DK_GRAY, $._mApp.bgColSet);
		for(var i = 1; i < 6; i += 2) {

			var y = ceilY + (((i * gap) * scaleY) / 2);
			var num = ceil - ((i * gap) / 2.0);
			if(num != num.toNumber()) {
				// may need to stagger on smaller screens
				//dc.drawText(textX + 35, y, font, format(" $1$ ",[num.format("%0.1f")]), just);
				dc.drawText(textX, y, font, format(" $1$ ",[num.format("%0.1f")]), just);				
			}
			else {
				//dc.drawText(textX + 35, y, font, format(" $1$ ",[num.format("%d")]), just);
				dc.drawText(textX, y, font, format(" $1$ ",[num.format("%d")]), just);
			}
		}

		for(var i = 0; i < 7; i += 2) {
			var y = ceilY + (((i * gap) * scaleY) / 2);
			var str = format(" $1$ ",[(ceil - ((i * gap)/2)).format("%d")]);
			dc.drawText(textX, y, font, str, just);
		}

		// Draw the data
		var drawDots = 0;

		dc.setPenWidth(2);
		MapSetColour(dc, DK_RED, $._mApp.bgColSet);
		//dc.drawLine(leftX + index1, floorY - avgPulse1, leftX + index2, floorY - avgPulse2);
		drawDots++;

		// If only one reading then draw dots. There are no averages
		if(1 == drawDots) {
			MapSetColour(dc, ORANGE, $._mApp.bgColSet);
		//	dc.fillCircle(leftX + index1, floorY - pulse1, 2);

		//	MapSetColour(dc, BLUE, $._mApp.bgColSet);
		//	dc.fillCircle(leftX + index1, floorY - hrv1, 2);
		}

		// Draw the labels
		dc.setPenWidth(1);

		MapSetColour(dc, DK_RED, $._mApp.bgColSet);
		dc.drawText(ctrX, mLabelOffsetFloor, font, " AVG PULSE", 6);

		MapSetColour(dc, BLUE, $._mApp.bgColSet);
		dc.drawText(ctrX, mLabelOffsetCeil, font, "HRV ", 4);
    		
		//If using layout then calling onUpdate() works. If drawing explicitly then overwrites screen
		// Possibly needs to be at start! 
   		//View.onUpdate(dc);
   		return true;
    }
}