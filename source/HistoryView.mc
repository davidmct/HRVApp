using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// Show the previous test results over time
class HistoryView extends Ui.View {
	
	hidden var mHistoryLayout;
	hidden var cGridWith;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	hidden var rightX;
	hidden var ceilY;
	hidden var floorY;
	
	hidden var floor;
	hidden var ceil;
	hidden var scaleY;

	function initialize() { View.initialize();}
	
	hidden function updateLayoutField(fieldId, fieldValue, fieldColour) {
	    var drawable = findDrawableById(fieldId);
	    if (drawable != null) {
	    	if (fieldColour != null) { drawable.setColor(fieldColour);}
	        if (fieldValue != null) {  drawable.setText(fieldValue); }
	    }
    }
	
	function onLayout(dc) {
		mHistoryLayout = Rez.Layouts.HistoryViewLayout(dc);
		//Sys.println("HistoryView: onLayout() called ");
		if ( mHistoryLayout != null ) {
			setLayout(mHistoryLayout);
		} else {
			Sys.println("History layout null");
		}
		var a = Ui.loadResource(Rez.Strings.HistoryGridWidth);
		cGridWith = a.toNumber();
		a = Ui.loadResource(Rez.Strings.HistoryGridHeight);
		chartHeight = a.toNumber();
		
		// chartHeight defines height of chart and sets scale
		// impacts all layout numbers!
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
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    function scale(num) {
		return (((num - floor) * scaleY) + 0.5).toNumber();
	}

    //! Update the view
    function onUpdate(dc) {

		var today = ($._mApp.timeToday() / 86400) % 30;	// Todays index
		var epoch = $._mApp.timeToday() - (86400 * 29);	// Index 29 days ago

		var dataCount = 0;
		var max = 0;
		var min = 1000;
		
		// draw the layout. remove if trying manual draw of layout elements
    	View.onUpdate(dc);
    	
    	var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);

		updateLayoutField("HistoryTitle", null, mLabelColour);
		updateLayoutField("rMSSDLbl", null,  mapColour($._mApp.RMSSDColSet));
		updateLayoutField("LnRMSSDLbl", null,  mapColour($._mApp.LnRMSSDColSet));
		updateLayoutField("avgPulseLbl", null,  mapColour($._mApp.avgPulseColSet));
		
		// TEST CODE DUMP RESULTS AS getting weird type
		//if (mDebuggingResults) {
		//	var dump = "";
		//	for(var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE; i++) {
		//		dump += $._mApp.results[i].toString() + ",";
		//	}
		//	Sys.println("History view DUMP of results : "+dump);
		//}
		
		// Find result limits
		// change this to step i to each time stamp then look at next three samples
		for(var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE; i += DATA_SET_SIZE) {
			// Only process if newer than epoch
			if(epoch <= $._mApp.results[i]) {
				// Get range of all three results ... may not be correlated range for each set
				for( var y = 1; y <= 3; y++) {
					var value = $._mApp.results[i+y].toNumber();
					if(min > value) {
						min = value;
					}
					if(max < value) {
						max = value;
					}
				}
				dataCount++;
			}
		}

		// If no results then set min & max to create a nice graph scale
		if(0 == dataCount){
			min = 0;
			max = 20;
		}

		// Create the range in blocks of 5
		ceil = (max + 5) - (max % 5);
		floor = min - (min % 5);
		
		// now expand to multiple of 10 as height = 120 
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			floor -= 5;
		} else if (test == 0) {
			ceil += 5;
			floor -= 5;
		}
		var range = ceil - floor;
		
		// chartHeight defines height of chart and sets scale
		scaleY = chartHeight / range.toFloat();
		
		// Draw the numbers on Y axis	
		var gap = (ceil-floor);	
		for (var i=0; i<7; i++) {
			var num = ceil - ((i * gap) / 6.0); // may need to be 7.0
			var str;
			//if(num != num.toNumber()) {
			//	str = format(" $1$ ",[num.format("%0.1f")] );				
			//}
			//else {
				// just use whole numbers
				str = format(" $1$ ",[num.format("%d")] );
			//}				
			updateLayoutField("yLabel"+i, str, null);
			
		}

		// Draw the data
		var drawDots = 0;
		
		for(var i = 0; i < 30; i++) {
			// Start 30 days ago and work forwards
 			var ii = ((today + 1 + i) % 30) * DATA_SET_SIZE;
			if(epoch < $._mApp.results[ii]) {
				var x1 = i * 6 + 3; // 3,9....177 width of chart = 180
	 			var mRMSSD1 = scale($._mApp.results[ii + 1]);
	 			var mLnRMSSD1 = scale($._mApp.results[ii + 2]);
	 			var avgPulse1 = scale($._mApp.results[ii + 3]);
	 			drawDots++;

	 			for(var iii = i + 1; iii < 30; iii++) {
					var iiii = ((today + 1 + iii) % 30) * DATA_SET_SIZE;
		 			if(epoch < $._mApp.results[iiii]) {
			 			var x2 = iii * 6 + 3; // 9, 15,... 177
			 			var mRMSSD2 = scale($._mApp.results[iiii + 1]);
			 			var mLnRMSSD2 = scale($._mApp.results[iiii + 2]);
			 			var avgPulse2 = scale($._mApp.results[iiii + 3]);

						dc.setPenWidth(2);
						MapSetColour(dc, $._mApp.avgPulseColSet, $._mApp.bgColSet);
						dc.drawLine(leftX + x1, floorY - avgPulse1, leftX + x2, floorY - avgPulse2);

						MapSetColour(dc, $._mApp.RMSSDColSet, $._mApp.bgColSet);
						dc.drawLine(leftX + x1, floorY - mRMSSD1, leftX + x2, floorY - mRMSSD2);

						dc.setPenWidth(3);
						MapSetColour(dc,$._mApp.LnRMSSDColSet, $._mApp.bgColSet);
						dc.drawLine(leftX + x1, floorY - mLnRMSSD1, leftX + x2, floorY - mLnRMSSD1);
						
						//Sys.println("LeftX, x1, floorY, mRMSSD1, mLnRMSSD1 "+leftX+","+x1+","+floorY+","+mRMSSD1+","+mLnRMSSD1);
						//Sys.println("x2, mRMSSD2, mLnRMSSD2 "+x2+","+mRMSSD2+","+mLnRMSSD2);
						// Change the value of i. So that it starts back at this point. Break loop
						i = iii - 1;
						iii = 30;
						drawDots++;
					}
				}
				// If only one reading then draw dots. There are no averages
				if(1 == drawDots) {
					MapSetColour(dc, $._mApp.avgPulseColSet, $._mApp.bgColSet);
					dc.fillCircle(leftX + x1, floorY - avgPulse1, 2);

					MapSetColour(dc,  $._mApp.RMSSDColSet, $._mApp.bgColSet);
					dc.fillCircle(leftX + x1, floorY - mRMSSD1, 2);
					
					MapSetColour(dc,  $._mApp.LnRMSSDColSet, $._mApp.bgColSet);
					dc.fillCircle(leftX + x1, floorY - mLnRMSSD1, 2);	
					
					//Sys.println("LeftX, x1, floorY, mRMSSD1, mLnRMSSD1 "+leftX+","+x1+","+floorY+","+mRMSSD1+","+mLnRMSSD1);					
				}
			}
		}

		// TEST CODE
		var str = System.getSystemStats().usedMemory.toString();
		Sys.println("Testview memory use "+str);

    }
}