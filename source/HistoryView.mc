using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

using HRVStorageHandler as mStorage;

// Show the largest number of samples possible in width of HRV measurements used by glance processing

		// Title - X, Y : 0, 1
		// [mLabelValueLox X, Y] x 11: 2, 3; 4, 5; 6, 7; 8, 9; 10, 11; 12,13; 14,15; 16,17; 18, 19; 20, 21;	22,23
		// mRectHorizY[7] : 24-30
		// mRectHorizWHS , HorizXS : 31, 32

(:UseJson)
class HistoryView extends Ui.View {
	
	hidden var cGridWidth;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	//hidden var rightX;
	//hidden var ceilY;
	hidden var floorY;
	hidden var scaleY;
	hidden var xStep;
	hidden var floor;
	hidden var dispH;
	
	//hidden var customFont = null;
	
	//0.4.3
	//hidden var numResultsToDisplay = 0;
	
	hidden var labelList = new [MAX_DISPLAY_VAR];
	hidden var resultsIndexList = new [MAX_DISPLAY_VAR];
    
    //hidden var mTitleLoc = [50, 11]; // %
	//hidden var mTitleLocS = [0,0];	
	//hidden var mTitleLabels = ["History"];
	
	// coordinates of set of labels as %
	// split to 1D array to save memory
	// Labelx1,2,3, ylabel0...6, xAxisLabel
	//hidden var mLabelValueLocX = [ 30, 64, 50, 11, 11, 11, 11, 11, 11, 11, 70];
	//hidden var mLabelValueLocY = [ 79, 79, 88, 27, 36, 43, 50, 57, 64, 71, 23];
		
	// x%, y%, width/height. 
	//hidden var mRectHorizWH = 64;
	//hidden var mRectHorizX = 18;
	//hidden var mRectHorizY = [ 28, 36, 43, 50, 57, 64, 71 ];
	
	// scaled variables
	//hidden var mLabelValueLocXS = new [ mLabelValueLocX.size() ];
	//hidden var mLabelValueLocYS = new [ mLabelValueLocY.size() ];
	
	//hidden var mRectHorizWHS = 0;
	//hidden var mRectHorizXS = 0;
	//hidden var mRectHorizYS = new [mRectHorizY.size() ];
		
	hidden var mLabelFont = null; //Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	//hidden var mScaleY;
	//hidden var mScaleX;
	
	// layout of screen
	hidden var mScr;
	// original history = 0, long term history is 1
	hidden var mView = 0;
   
	function initialize( _mView) {
	 	if (_mView > 1) { mView = 0;} else { mView = _mView;}
		View.initialize();
	}
	
	function onLayout(dc) {
		
		// variables already set
		//if (mLabelValueLocX == null) {return true;}

		var a = Ui.loadResource(Rez.Strings.HistoryGridWidth);
		cGridWidth = a.toNumber();
		a = Ui.loadResource(Rez.Strings.HistoryGridHeight);
		chartHeight = a.toNumber();
		a = null;
		
		// load JSON
		mScr = Ui.loadResource(Rez.JsonData.jsonStatsHist);
		
		// chartHeight defines height of chart and sets scale
		// impacts all layout numbers!
    	ctrX = dc.getWidth() / 2;
    	dispH = dc.getHeight();
		ctrY = dispH / 2;
		// define box about centre
		// leftX should be on left side of screen aligned with Y axis
		leftX = mScr[32]+2; // 0.6.4 ctrX - cGridWidth/2;
		//rightX = ctrX + cGridWidth/2;
		// 45 *2 is height of chart
		//ceilY = ctrY - chartHeight/2;
		floorY = ctrY + chartHeight/2;
		
		xStep = (cGridWidth / NUM_RESULT_ENTRIES).toNumber();
				
		return true;
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    function scale(num) {
    	if (num == null) { return 0;}
		return (((num - floor) * scaleY) + 0.5).toNumber();
	}
	
(:oldResults)
	// dummy function to allow most of onUpdate to stay same
	function prepResults() {}
	
(:newResults)
	function prepResults() {
	
		//Sys.println("prepResults()");
		
		$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		
		// if retrieve returns null i eno storage then we will have all 0's
		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$.results[i] = 0;
		}
		// this will be overridden if we load results
		$.resultsIndex = 0;
		
		mStorage.retrieveResults();
		
		//Sys.println("Retrieved results ="+$.results);
	}
	
(:oldResults)
	function freeResults() {}
	
(:newResults)
	function freeResults() {$.results = null;}

    //! Update the view
    function onUpdate(dc) {
    
    	if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
		
		if ($.mDeviceType == RES_240x240) {
			//Sys.println("device is 240x240");
			if (mLabelFont == null) {	
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
				//Sys.println("smallFont loaded");
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
				
		// original history view
		var _title = "";
		if (mView == 0 ) {
			_title = "History";
		} else {
			_title = "Test hist";
		}					
		// heading at 50% of X and 11% of Y
		dc.drawText( ctrX, (dispH * 11)/100, mTitleFont, _title, mJust);
		_title = null;
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);
	
		var _lineStart = (dispH * 27) /100; //% of total height
		var _lineEnd = (dispH * 71) / 100;
		var yStep = ((_lineEnd - _lineStart) / 6.0).toNumber();
		var yInit = _lineStart;
		
		Sys.println("yStep = "+yStep+", yInit = "+yInit);
		
		for (var i=0; i < 7; i++) {
			// 0.6.4 Draw rectangle using computed numbers
			dc.drawRectangle(mScr[32], yInit, mScr[31], 1);
			yInit += yStep;
			//dc.drawRectangle(mScr[32], mScr[24+i], mScr[31], 1);
			//Sys.println("Rect Coords: "+mScr[32]+", "+mScr[24+i]+", "+mScr[31]);
		}
		
		if ( mView == 0 ) {
			drawHistory(dc);
		} else {
			drawLongTerm(dc);
		}
		
	}
	
	function drawLongTerm(dc) {
	    dc.setColor( $.Label2Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mScr[4], mScr[5], mLabelFont, "HRV", mJust);
	
	}

	function drawHistory(dc) {		
				
		var dataCount = 0;
		var max = 0;
		var min = 1000;
		
		if ( $.results == null) {
			prepResults();
		}
		
		var mHistoryLabelList = Ui.loadResource(Rez.JsonData.jsonHistoryLabelList); 
		
		//0.4.3 - Now have list available to match label and colour!
		// resultsIndexList to null if no data to display
		if ( $.mHistoryLabel1 == 0 && $.mHistoryLabel2 == 0 && $.mHistoryLabel3 == 0) {
			mHistoryLabelList = null;
			return;
		}	
		 
		labelList[0] = mHistoryLabelList[$.mHistoryLabel1];
        resultsIndexList[0] = ( $.mHistoryLabel1 == 0 ? null : $.mHistoryLabel1);
		labelList[1] = mHistoryLabelList[$.mHistoryLabel2];
        resultsIndexList[1] = ( $.mHistoryLabel2 == 0 ? null : $.mHistoryLabel2);
		labelList[2] = mHistoryLabelList[$.mHistoryLabel3];
        resultsIndexList[2] = ( $.mHistoryLabel3 == 0 ? null : $.mHistoryLabel3);   
        
        mHistoryLabelList = null;
                        	
        // hard to tie menu on selection order to this list-> fixed 0.4.3
        // draw the data being drawn labels
        dc.setColor( $.Label1Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mScr[2], mScr[3], mLabelFont, labelList[0], mJust);			
        dc.setColor( $.Label2Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mScr[4], mScr[5], mLabelFont, labelList[1], mJust);	
		dc.setColor( $.Label3Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mScr[6], mScr[7], mLabelFont, labelList[2], mJust);	
		
		//Sys.println("labelList = "+labelList+" resultsIndexList = "+resultsIndexList);
		
		//0.6.3 we could still have no array on first run
		if ($.results == null) {
			//dc.drawText(dc.getWidth()/2,dc.getHeight()/2,Gfx.FONT_SMALL,"No history", mJust);
			return;
		}
		
		//Sys.println("DeviceType = "+$.mDeviceType+", sel font: "+mLabelFont+" xtiny is "+Gfx.FONT_XTINY);		
		//Sys.println("Results = "+$.results);
		
		// get pointer to next empty slot in results array .. should be oldest data		
		var indexDay = $.resultsIndex;
		var today = ($.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;		
				
		// Find result limits
		// ASSUME THAT HISTORY IS LAST 30 samples on different days NOT that they have to be contiguous days!!!		
		// only do min/max on variables of interest
		var day = indexDay; // start at furthest past
		var index = day * DATA_SET_SIZE;
		do {
			if ($.results[index] != 0) { // we have an entry that has been created	
				// get values and check max/min
				var cnt = 0;
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];					
					if (j != null) {
						var value = $.results[index+j].toNumber();
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
			
			index = (index + DATA_SET_SIZE) % $.results.size();
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
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		var gap = (ceil-floor);	
		for (var i=0; i<7; i++) {
			var num = ceil - ((i * gap) / 6.0); // may need to be 7.0
			// just use whole numbers
			var str = format(" $1$ ",[num.format("%d")] );	
			// using custom font so not needed
			//if (($.mDeviceType == RES_240x240) && ( i % 2 == 1 )) {
			//	dc.drawText( mLabelValueLocXS[3+i], mLabelValueLocYS[3+i], mLabelFont, "", mJust);				
			//} else {
			var _ind = i*2+8; 		
			dc.drawText( mScr[_ind], mScr[_ind+1], mLabelFont, str, mJust);
			//}
		}
		
		// draw final title
		dc.drawText( mScr[22], mScr[23], mLabelFont, "newer->", mJust);	
		
		var firstData = new [MAX_DISPLAY_VAR];
		
		// if only one data point we must be at start of time and zero entry!
		if (dataCount == 1) {
			// load values
			for (var i=0; i < MAX_DISPLAY_VAR; i++) {
				var j = resultsIndexList[i];	
				// up to MAX_DISPLAY_VAR to show - check valid entry			
				if (j != null) {
					firstData[i] = $.results[j].toNumber();
				} // j != null
			} // for each display value
			// scale can return null which need to check on draw
 			var mLabel1Val1 = scale(firstData[0]);
 			var mLabel2Val1 = scale(firstData[1]);
 			var mLabel3Val1 = scale(firstData[2]);				
			
			//Sys.println("HistoryView() single data point");
			
			// now we should have a continuous set of points having found a non-zero entry
			dc.setColor($.Label1Colour, $.mBgColour);
			if (resultsIndexList[0] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel1Val1, 2);}
			dc.setColor($.Label2Colour, $.mBgColour);
			if (resultsIndexList[1] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel2Val1, 2);}					
			dc.setColor($.Label3Colour, $.mBgColour);
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
			if ($.results[index] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = $.results[index+j].toNumber();
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
				//if ($.results[secondIndex] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = $.results[secondIndex+j].toNumber();
					} // j != null
				} // for each display value

				// scale can return null which need to check on draw
	 			var mLabel1Val2 = scale(firstData[0]);
	 			var mLabel2Val2 = scale(firstData[1]);
	 			var mLabel3Val2 = scale(firstData[2]);	
	 			
	 			//Sys.println("#2 firstData, resultsIndexList and #points, secondIndex :"+firstData+", "+resultsIndexList+", #"+pointNumber+","+secondIndex);			

				dc.setColor($.Label1Colour, $.mBgColour);
				if (resultsIndexList[0] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel1Val1, leftX + x2, floorY - mLabel1Val2);}
				dc.setColor($.Label2Colour, $.mBgColour);
				if (resultsIndexList[1] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel2Val1, leftX + x2, floorY - mLabel2Val2);}
				dc.setColor($.Label3Colour, $.mBgColour);
				if (resultsIndexList[2] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel3Val1, leftX + x2, floorY - mLabel3Val2);}
				
				Sys.println("LeftX: "+leftX+", x1: "+x1+", x2: "+x2+" floorY: "+floorY+" l1v1: "+mLabel1Val1+" l1v2: "+mLabel1Val2+
					" l2v1: "+mLabel2Val1+" l2v2: "+mLabel2Val2+
					" l3v1: "+mLabel3Val1+" l3v2: "+mLabel3Val2
				);

				pointNumber++;	
			} // found entry	
			
			// update pointers
			day = (day + 1) % NUM_RESULT_ENTRIES; // wrap round end of buffer
			index = (day * DATA_SET_SIZE) % $.results.size();
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
		
(:notUseJson)
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
	//var gg;
   
	function initialize() { 
		//gg = $._m$.	
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
			
		fBuildJson();
				
		return true;
	}
		
	(:release)
	function fBuildJson() {}
	(:debug)
	function fBuildJson() {
		
		// build JSON string
		var mStr = "<jsonData id="+"jsonStatsHist"+mScaleY+">[";
		
		// concatenate
		mStr = mStr + mTitleLocS[0].toString()+","+mTitleLocS[1].toString()+",";

		for( var i=0; i < mLabelValueLocXS.size(); i++) {
			mStr = mStr + mLabelValueLocXS[i].toString() +","+mLabelValueLocYS[i].toString()+",";	
		}
				
		for( var i=0; i < mRectHorizYS.size(); i++) {
			mStr = mStr + mRectHorizYS[i].toString()+",";	
		}					
				
		mStr = mStr+ mRectHorizWHS.toString()+"," + mRectHorizXS.toString();											
	
		// end string
		mStr = mStr+"]</jsonData>";
		
		Sys.println( mStr);		
		
		// Title - X, Y : 0, 1
		// [mLabelValueLox X, Y] x 11: 2, 3; 4, 5; 6, 7; 8, 9; 10, 11; 12,13; 14,15; 16,17; 18, 19; 20, 21;	22,23
		// mRectHorizY[7] : 24-30
		// mRectHorizWHS , HorizXS : 31, 32
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
			if ($.mHistorySelectFlags & (1 << (bitPosition-1))) {
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
		
		$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		
		// if retrieve returns null i eno storage then we will have all 0's
		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$.results[i] = 0;
		}
		// this will be overridden if we load results
		$.resultsIndex = 0;
		
		mStorage.retrieveResults();
		
		//Sys.println("Retrieved results ="+$.results);
	}
	
(:oldResults)
	function freeResults() {}
	
(:newResults)
	function freeResults() {$.results = null;}


    //! Update the view
    function onUpdate(dc) {
		
		var mHistoryLabelList = Ui.loadResource(Rez.JsonData.jsonHistoryLabelList); 
		
		if ($.mDeviceType == RES_240x240) {
			//Sys.println("device is 240x240");
			if (mLabelFont == null) {	
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
				//Sys.println("smallFont loaded");
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
				
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);
		
		if ( $.results == null) {
			prepResults();
		}
		
		var dataCount = 0;
		var max = 0;
		var min = 1000;

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 1);
		}

		//Sys.println("HistoryView: indexDay, today, HistoryFlags, $.resultsIndex :"+
		//	indexDay+", "+today+", "+$.mHistorySelectFlags+", "+$.resultsIndex);
		
		// OLD 0.4.2 code
		//if ($.mHistorySelectFlags == 0) {
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
		if ( $.mHistoryLabel1 == 0 && $.mHistoryLabel2 == 0 && $.mHistoryLabel3 == 0) {
			mHistoryLabelList = null;
			return;
		}	
		 
		labelList[0] = mHistoryLabelList[$.mHistoryLabel1];
        resultsIndexList[0] = ( $.mHistoryLabel1 == 0 ? null : $.mHistoryLabel1);
		labelList[1] = mHistoryLabelList[$.mHistoryLabel2];
        resultsIndexList[1] = ( $.mHistoryLabel2 == 0 ? null : $.mHistoryLabel2);
		labelList[2] = mHistoryLabelList[$.mHistoryLabel3];
        resultsIndexList[2] = ( $.mHistoryLabel3 == 0 ? null : $.mHistoryLabel3);   
        
        mHistoryLabelList = null;
                        	
        // hard to tie menu on selection order to this list-> fixed 0.4.3
        // draw the data being drawn labels
        dc.setColor( $.Label1Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mLabelFont, labelList[0], mJust);			
        dc.setColor( $.Label2Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mLabelFont, labelList[1], mJust);	
		dc.setColor( $.Label3Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mLabelFont, labelList[2], mJust);	
		
		//Sys.println("labelList = "+labelList+" resultsIndexList = "+resultsIndexList);
		
		// TEST CODE..
		// set results up to end point...
		//for (var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE ; i++) { $.results[i] = 0;}
		//for (var i = 0; i < NUM_RESULT_ENTRIES; i++) { 
			// force index day
		//	$.resultsIndex = 0;
		//	indexDay = $.resultsIndex;
		//	today = ($.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
			
		//	var loc = i * DATA_SET_SIZE;
		//	$.results[loc] = i+1; // set none zero time
		//	$.results[loc + AVG_PULSE_INDEX] = i; // ramp up values		
		//}
		
		//0.6.3 we could still have no array on first run
		if ($.results == null) {
			//dc.drawText(dc.getWidth()/2,dc.getHeight()/2,Gfx.FONT_SMALL,"No history", mJust);
			return;
		}
		
		//Sys.println("DeviceType = "+$.mDeviceType+", sel font: "+mLabelFont+" xtiny is "+Gfx.FONT_XTINY);		
		//Sys.println("Results = "+$.results);
		
		// get pointer to next empty slot in results array .. should be oldest data		
		var indexDay = $.resultsIndex;
		var today = ($.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;		
		
		// TEST CODE DUMP RESULTS AS getting weird type
		if (mDebuggingResults) {
			var dump = "";
			for(var i = 0; i < NUM_RESULT_ENTRIES * DATA_SET_SIZE; i++) {
				dump += $.results[i].toString() + ",";
			}
			Sys.println("History DUMP results : "+dump);
		}
		
		// Find result limits
		// ASSUME THAT HISTORY IS LAST 30 samples on different days NOT that they have to be contiguous days!!!		
		// only do min/max on variables of interest
		var day = indexDay; // start at furthest past
		var index = day * DATA_SET_SIZE;
		do {
			if ($.results[index] != 0) { // we have an entry that has been created	
				// get values and check max/min
				var cnt = 0;
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];					
					if (j != null) {
						var value = $.results[index+j].toNumber();
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
			
			index = (index + DATA_SET_SIZE) % $.results.size();
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
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		var gap = (ceil-floor);	
		for (var i=0; i<7; i++) {
			var num = ceil - ((i * gap) / 6.0); // may need to be 7.0
			// just use whole numbers
			var str = format(" $1$ ",[num.format("%d")] );	
			// using custom font so not needed
			//if (($.mDeviceType == RES_240x240) && ( i % 2 == 1 )) {
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
					firstData[i] = $.results[j].toNumber();
				} // j != null
			} // for each display value
			// scale can return null which need to check on draw
 			var mLabel1Val1 = scale(firstData[0]);
 			var mLabel2Val1 = scale(firstData[1]);
 			var mLabel3Val1 = scale(firstData[2]);				
			
			//Sys.println("HistoryView() single data point");
			
			// now we should have a continuous set of points having found a non-zero entry
			dc.setColor($.Label1Colour, $.mBgColour);
			if (resultsIndexList[0] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel1Val1, 2);}
			dc.setColor($.Label2Colour, $.mBgColour);
			if (resultsIndexList[1] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel2Val1, 2);}					
			dc.setColor($.Label3Colour, $.mBgColour);
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
			if ($.results[index] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = $.results[index+j].toNumber();
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
				//if ($.results[secondIndex] != 0) { // we have an entry that has been created	
				// load values
				for (var i=0; i < MAX_DISPLAY_VAR; i++) {
					var j = resultsIndexList[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = $.results[secondIndex+j].toNumber();
					} // j != null
				} // for each display value

				// scale can return null which need to check on draw
	 			var mLabel1Val2 = scale(firstData[0]);
	 			var mLabel2Val2 = scale(firstData[1]);
	 			var mLabel3Val2 = scale(firstData[2]);	
	 			
	 			//Sys.println("#2 firstData, resultsIndexList and #points, secondIndex :"+firstData+", "+resultsIndexList+", #"+pointNumber+","+secondIndex);			

				dc.setColor($.Label1Colour, $.mBgColour);
				if (resultsIndexList[0] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel1Val1, leftX + x2, floorY - mLabel1Val2);}
				dc.setColor($.Label2Colour, $.mBgColour);
				if (resultsIndexList[1] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel2Val1, leftX + x2, floorY - mLabel2Val2);}
				dc.setColor($.Label3Colour, $.mBgColour);
				if (resultsIndexList[2] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel3Val1, leftX + x2, floorY - mLabel3Val2);}

				pointNumber++;	
			} // found entry	
			
			// update pointers
			day = (day + 1) % NUM_RESULT_ENTRIES; // wrap round end of buffer
			index = (day * DATA_SET_SIZE) % $.results.size();
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