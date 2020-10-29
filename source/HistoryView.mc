using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// Show the previous test results over time
class HistoryView extends Ui.View {
	
	hidden var cGridWidth;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	hidden var rightX;
	hidden var ceilY;
	hidden var floorY;
	hidden var scaleY;
	hidden var xStep;
	hidden var floor;
	
	//hidden var customFont = null;
	
	//0.4.3
	//hidden var numResultsToDisplay = 0;
	
	hidden var labelList = new [MAX_DISPLAY_VAR];
	hidden var resultsIndexList = new [MAX_DISPLAY_VAR];
    
    hidden var mTitleLoc = [50, 11]; // %
	hidden var mTitleLocS = [0,0];	
	hidden var mTitleLabels = ["History"];
	
	// coordinates of set of labels as %
	// split to 1D array to save memory
	// Labelx1,2,3, ylabel0...6, xAxisLabel
	hidden var mLabelValueLocX = [ 30, 64, 50, 11, 11, 11, 11, 11, 11, 11, 70];
	hidden var mLabelValueLocY = [ 79, 79, 88, 27, 36, 43, 50, 57, 64, 71, 23];
		
	// x%, y%, width/height. 
	hidden var mRectHorizWH = 64;
	hidden var mRectHorizX = 18;
	hidden var mRectHorizY = [ 28, 36, 43, 50, 57, 64, 71 ];
	
	// scaled variables
	hidden var mLabelValueLocXS = new [ mLabelValueLocX.size() ];
	hidden var mLabelValueLocYS = new [ mLabelValueLocY.size() ];

	
	hidden var mRectHorizWHS = 0;
	hidden var mRectHorizXS = 0;
	hidden var mRectHorizYS = new [mRectHorizY.size() ];
		
	hidden var mLabelFont = null; //Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;
	var gg;
   
	function initialize() { 
		gg = $._mApp;
		View.initialize();
	}
	
	function onLayout(dc) {
		
		// variables already set
		if (mLabelValueLocX == null) {return true;}

		var a = Ui.loadResource(Rez.Strings.HistoryGridWidth);
		cGridWidth = a.toNumber();
		a = Ui.loadResource(Rez.Strings.HistoryGridHeight);
		chartHeight = a.toNumber();
		a = null;
		
		// chartHeight defines height of chart and sets scale
		// impacts all layout numbers!
    	ctrX = dc.getWidth() / 2;
		ctrY = dc.getHeight() / 2;
		// define box about centre
		leftX = ctrX - cGridWidth/2;
		rightX = ctrX + cGridWidth/2;
		// 45 *2 is height of chart
		ceilY = ctrY - chartHeight/2;
		floorY = ctrY + chartHeight/2;
		
		xStep = (cGridWidth / NUM_RESULT_ENTRIES).toNumber();
		
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
		
		mLabelValueLocX = null;
		mLabelValueLocY = null;
		mTitleLoc = null;	
		mRectHorizY = null;
			
		return true;
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    function scale(num) {
    	if (num == null) { return 0;}
		return (((num - floor) * scaleY) + 0.5).toNumber();
	}

	// return labels into dictionary of results offsets
(:HistoryViaDictionary)
	function findResultLabels(keys) {		
		// init arrays
		for ( var i=0; i < labelList.size(); i++) { labelList[i] = "";}
		for ( var i=0; i < resultsIndexList.size(); i++) { resultsIndexList[i] = null;}
		
		// scan through flags looking for true and then get label
		// find first N out of set
		var j = 0; // number found
		for(var search = 0; search < $.mHistorySelect.size(); search++) {
			var possible = keys[search].toString();
			var bitPosition = $.mHistorySelect.get(possible);
			
			// now check if corresponding bit position-1 is set 
			if (gg.mHistorySelectFlags & (1 << (bitPosition-1))) {
				// found set bit, capture index in to dictionary
				labelList[j] = possible;
				resultsIndexList[j] = bitPosition;
				numResultsToDisplay++;
				j++;
				if (j >= MAX_DISPLAY_VAR) {
					// break loop
					search = $.mHistorySelect.size();
				}
			} // end flag found
		} // end search
		return;
	}
	
(:oldResults)
	// dummy function to allow most of onUpdate to stay same
	function prepResults() {}
	
(:newResults)
	function prepResults() {
	
		//Sys.println("prepResults()");
		
		gg.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		
		// if retrieve returns null i eno storage then we will have all 0's
		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			gg.results[i] = 0;
		}
		// this will be overridden if we load results
		gg.resultsIndex = 0;
		
		gg.mStorage.retrieveResults();
		
		//Sys.println("Retrieved results ="+gg.results);
	}
	
(:oldResults)
	function freeResults() {}
	
(:newResults)
	function freeResults() {gg.results = null;}


    //! Update the view
    function onUpdate(dc) {
		
		var mHistoryLabelList = Ui.loadResource(Rez.JsonData.jsonHistoryLabelList); 
		
		if (gg.mDeviceType == RES_240x240) {
			//Sys.println("device is 240x240");
			if (mLabelFont == null) {	
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
				//Sys.println("smallFont loaded");
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		prepResults();
		
		//Sys.println("DeviceType = "+gg.mDeviceType+", sel font: "+mLabelFont+" xtiny is "+Gfx.FONT_XTINY);
		
		//Sys.println("Results = "+gg.results);
		
		// get pointer to next empty slot in results array .. should be oldest data		
		var indexDay = gg.resultsIndex;
		var today = (gg.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
		 
		var dataCount = 0;
		var max = 0;
		var min = 1000;

		// draw the layout. remove if trying manual draw of layout elements
    	//View.onUpdate(dc);

		dc.setColor( Gfx.COLOR_TRANSPARENT, gg.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 1);
		}

		dc.setColor( gg.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);

		//Sys.println("HistoryView: indexDay, today, HistoryFlags, $.resultsIndex :"+
		//	indexDay+", "+today+", "+gg.mHistorySelectFlags+", "+gg.resultsIndex);
		
		// OLD 0.4.2 code
		//if (gg.mHistorySelectFlags == 0) {
		//	// no data fields set to dsiplay so go home
		//	return;
		//}
		
		//// now find labels and index for data		
		//var mKeys = $.mHistorySelect.keys(); // keys to dictionary
		//numResultsToDisplay = 0;
		
		//// index into dictionary of results offsets (need +1 to make results index)
		//findResultLabels(mKeys);
		
		// CHECK OUTCOME
		//Sys.println("HistoryView(): numResults, labelList, resultsIndexList :"
		//	+numResultsToDisplay+","+labelList+","+resultsIndexList);
		
		//0.4.3 - Now have list available to match label and colour!
		// resultsIndexList to null if no data to display
		if ( gg.mHistoryLabel1 == 0 && gg.mHistoryLabel2 == 0 && gg.mHistoryLabel3 == 0) {
			mHistoryLabelList = null;
			return;
		}	
		 
		labelList[0] = mHistoryLabelList[gg.mHistoryLabel1];
        resultsIndexList[0] = ( gg.mHistoryLabel1 == 0 ? null : gg.mHistoryLabel1);
		labelList[1] = mHistoryLabelList[gg.mHistoryLabel2];
        resultsIndexList[1] = ( gg.mHistoryLabel2 == 0 ? null : gg.mHistoryLabel2);
		labelList[2] = mHistoryLabelList[gg.mHistoryLabel3];
        resultsIndexList[2] = ( gg.mHistoryLabel3 == 0 ? null : gg.mHistoryLabel3);   
        
        mHistoryLabelList = null;
                        	
        // hard to tie menu on selection order to this list-> fixed 0.4.3
        // draw the data being drawn labels
        dc.setColor( gg.Label1Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mLabelFont, labelList[0], mJust);			
        dc.setColor( gg.Label2Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mLabelFont, labelList[1], mJust);	
		dc.setColor( gg.Label3Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mLabelFont, labelList[2], mJust);	
		
		//Sys.println("labelList = "+labelList+" resultsIndexList = "+resultsIndexList);
		
		// TEST CODE..
		// set results up to end point...
		//for (var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE ; i++) { gg.results[i] = 0;}
		//for (var i = 0; i < NUM_RESULT_ENTRIES; i++) { 
			// force index day
		//	gg.resultsIndex = 0;
		//	indexDay = gg.resultsIndex;
		//	today = (gg.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
			
		//	var loc = i * DATA_SET_SIZE;
		//	gg.results[loc] = i+1; // set none zero time
		//	gg.results[loc + AVG_PULSE_INDEX] = i; // ramp up values		
		//}
		
		// TEST CODE DUMP RESULTS AS getting weird type
		if (mDebuggingResults) {
			var dump = "";
			for(var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE; i++) {
				dump += gg.results[i].toString() + ",";
			}
			Sys.println("History view DUMP of results : "+dump);
		}
		
		// Find result limits
		// ASSUME THAT HISTORY IS LAST 30 samples on different days NOT that they have to be contiguous days!!!		
		// only do min/max on variables of interest
		var day = indexDay; // start at furthest past
		var index = day * DATA_SET_SIZE;
		do {
			if (gg.results[index] != 0) { // we have an entry that has been created	
				// get values and check max/min
				var cnt = 0;
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];					
					if (j != null) {
						var value = gg.results[index+j].toNumber();
						cnt++;
						//Sys.println("index = "+j+", value : "+value);
						// do min max
						if(min > value) {
							min = value;
						}
						if(max < value) {
							max = value;
						}
					} // j != null
				} // for each display value
					
				// hope one of the three isn't null!
				if (cnt > 0) { dataCount++;}
			}	
			
			index = (index + DATA_SET_SIZE) % gg.results.size();
			day = (day + 1) % NUM_RESULT_ENTRIES; // wrap round end of buffer
		} 
		// iterate until back to start
		while ( day != indexDay);
		
		//Sys.println(" dataCount, min, max: "+dataCount+", "+min+", "+max);

		// If no results then set min & max to create a nice graph scale
		if(0 == dataCount){
			min = 0;
			max = 30;
		}

		// Create the range in blocks of 5
		var ceil = (max + 5) - (max % 5);
		floor = min - (min % 5);
		//if (floor < 0 ) { floor = 0;}
		
		// now expand to multiple of 10 as height also multiple of 10. 
		// Ensure floor doesn't go negative  
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		var range = ceil - floor;
		
		// chartHeight defines height of chart and sets scale
		scaleY = chartHeight / range.toFloat();
		
		// Draw the numbers on Y axis	
		// NOTE COULD DRAW ONLY HALF OF THESE ON SMALL SCREENS ie 240x240 use the mDeviceType value
		// Built new font instead
		dc.setColor( gg.mLabelColour, Gfx.COLOR_TRANSPARENT);
		var gap = (ceil-floor);	
		for (var i=0; i<7; i++) {
			var num = ceil - ((i * gap) / 6.0); // may need to be 7.0
			// just use whole numbers
			var str = format(" $1$ ",[num.format("%d")] );	
			// using custom font so not needed
			//if ((gg.mDeviceType == RES_240x240) && ( i % 2 == 1 )) {
			//	dc.drawText( mLabelValueLocXS[3+i], mLabelValueLocYS[3+i], mLabelFont, "", mJust);				
			//} else { 		
				dc.drawText( mLabelValueLocXS[3+i], mLabelValueLocYS[3+i], mLabelFont, str, mJust);
			//}
		}
		
		// draw final title
		dc.drawText( mLabelValueLocXS[10], mLabelValueLocYS[10], mLabelFont, "newer->", mJust);	
		
		var firstData = new [MAX_DISPLAY_VAR];
		
		// if only one data point we must be at start of time and zero entry!
		if (dataCount == 1) {
			// load values
			for (var i=0; i < MAX_DISPLAY_VAR; i++) {
				var j = resultsIndexList[i];	
				// up to MAX_DISPLAY_VAR to show - check valid entry			
				if (j != null) {
					firstData[i] = gg.results[j].toNumber();
				} // j != null
			} // for each display value
			// scale can return null which need to check on draw
 			var mLabel1Val1 = scale(firstData[0]);
 			var mLabel2Val1 = scale(firstData[1]);
 			var mLabel3Val1 = scale(firstData[2]);				
			
			//Sys.println("HistoryView() single data point");
			
			// now we should have a continuous set of points having found a non-zero entry
			dc.setColor(gg.Label1Colour, gg.mBgColour);
			if (resultsIndexList[0] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel1Val1, 2);}
			dc.setColor(gg.Label2Colour, gg.mBgColour);
			if (resultsIndexList[1] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel2Val1, 2);}					
			dc.setColor(gg.Label3Colour, gg.mBgColour);
			if (resultsIndexList[2] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel3Val1, 2);}	
			
			// TEST CODE		
			//Sys.println("History view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			//", "+System.getSystemStats().freeMemory.toString()+
			//", "+System.getSystemStats().totalMemory.toString()			
			//);							
			return;
		}
				
		// draw the data 
		dc.setPenWidth(2);	
					
		day = indexDay; // start at furthest past
		index = day * DATA_SET_SIZE;
		var pointNumber = 0;
		do {
			if (gg.results[index] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = gg.results[index+j].toNumber();
					} // j != null
				} // for each display value
				var x1 = pointNumber * xStep + 3; // 3,9....177 width of chart = 180
				// scale can return null which need to check on draw
	 			var mLabel1Val1 = scale(firstData[0]);
	 			var mLabel2Val1 = scale(firstData[1]);
	 			var mLabel3Val1 = scale(firstData[2]);				
				
				//Sys.println("firstData and points, index, day, today :"+firstData+", #"+pointNumber+","+index+","+day+","+today);
				
				// now we should have a continuous set of points having found a non-zero entry
				// must be another data point
				var x2 = (pointNumber+1) * xStep + 3;
				
				// look one day ahead
				var secondIndex = ((day + 1) % NUM_RESULT_ENTRIES)*DATA_SET_SIZE;
				
				// we have more than one entry so OK to not test for no data
				//if (gg.results[secondIndex] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = gg.results[secondIndex+j].toNumber();
					} // j != null
				} // for each display value

				// scale can return null which need to check on draw
	 			var mLabel1Val2 = scale(firstData[0]);
	 			var mLabel2Val2 = scale(firstData[1]);
	 			var mLabel3Val2 = scale(firstData[2]);	
	 			
	 			//Sys.println("#2 firstData, resultsIndexList and #points, secondIndex :"+firstData+", "+resultsIndexList+", #"+pointNumber+","+secondIndex);			

				dc.setColor(gg.Label1Colour, gg.mBgColour);
				if (resultsIndexList[0] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel1Val1, leftX + x2, floorY - mLabel1Val2);}
				dc.setColor(gg.Label2Colour, gg.mBgColour);
				if (resultsIndexList[1] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel2Val1, leftX + x2, floorY - mLabel2Val2);}
				dc.setColor(gg.Label3Colour, gg.mBgColour);
				if (resultsIndexList[2] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel3Val1, leftX + x2, floorY - mLabel3Val2);}

				pointNumber++;	
			} // found entry	
			
			// update pointers
			day = (day + 1) % NUM_RESULT_ENTRIES; // wrap round end of buffer
			index = (day * DATA_SET_SIZE) % gg.results.size();
		} 
		while ( day != today);
		
		// TEST CODE		
		//Sys.println("History view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);
		
    }
    
    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	// free up all the arrays - NO as maybe switches without a new ...
    	mLabelFont = null;
  		//remove buffer
		freeResults();  	
    }
}