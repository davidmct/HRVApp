using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Math;
using Toybox.Time.Gregorian;
using Toybox.Time;

using HRVStorageHandler as mStorage;
using GlanceGen as GG;

// Show the largest number of samples possible in width of HRV measurements used by glance processing

// this version no longer uses JSON for history
(:UseJson)
class HistoryView extends Ui.View {
	
	hidden var cGridWidth;
	hidden var chartHeight;
    hidden var ctrX;
	hidden var ctrY;
	hidden var leftX;
	hidden var floorY;
	hidden var scaleY;
	hidden var xStep;
	hidden var floor;
	hidden var range;
	hidden var ceil;
	hidden var dispH;
	hidden var dispW;
	hidden var _cWidth; // revised width of chart
	hidden var _lineStart; // start of grid in Y
	hidden var _lineEnd; // last line of Grid in Y
	
	hidden var _resT = new[5];
		
	hidden var mLabelFont = null; //Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	// original history = 0, long term history is 1
	hidden var mView = 0;
   
	function initialize( _mView) {
	 	if (_mView > 1) { mView = 0;} else { mView = _mView;}
		View.initialize();
	}
	
	function onLayout(dc) {

		var a = Ui.loadResource(Rez.Strings.HistoryGridWidth);
		cGridWidth = a.toNumber();
		a = Ui.loadResource(Rez.Strings.HistoryGridHeight);
		chartHeight = a.toNumber();
		a = null;

		// chartHeight defines height of chart and sets scale
		// impacts all layout numbers!
    	dispH = dc.getHeight();
    	dispW = dc.getWidth();
    	ctrX = dispW / 2;
		ctrY = dispH / 2;
		// define box about centre
		// leftX should be on left side of screen aligned with Y axis
		leftX = ctrX - cGridWidth/2; // mScr[32]+2; // 0.6.4 ctrX - cGridWidth/2;
		
		floorY = (dispH * 71) / 100;
		
		// in the trend view we want to use the maximum width of the screen ie the point at which all lines can be drawn
		// first part of code is common so think about new variables
		_lineStart = (dispH * 27) /100; //% of total height
		_lineEnd = floorY; //(dispH * 71) / 100;
		
		// find intersect on X axis of bounding circle
		var _farX1 = cGridWidth / 2 + Math.sqrt( Math.pow(dispW /2, 2) - Math.pow(ctrY - _lineStart, 2) );
		var _farX2 = cGridWidth / 2 + Math.sqrt( Math.pow(dispW /2, 2) - Math.pow(_lineEnd - ctrY, 2) );
		
		//Sys.println("_farX 1, 2:"+_farX1+", "+_farX2);
		
		// trend Width is smallest of two
		// this is the new width to wrote in for Trend graph. Starts at LeftX
		if ( mView == 0) {
			_cWidth = cGridWidth;
			// stepping used by History		
			xStep = (_cWidth / NUM_RESULT_ENTRIES).toNumber();
		} else { 
			_cWidth = ( _farX1 >= _farX2) ? _farX2.toNumber() : _farX1.toNumber();	
			// stepping for trends. Not setting to 3 then determines how many days we can show
			// alternatively we could work out how many days available and increase pitch 
			xStep = 4;		
		}
		//Sys.println("Start: "+_lineStart+", end: "+_lineEnd+" leftX is "+leftX+", _cWidth is: "+_cWidth);
				
		return true;
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    function scale(num) {
    	if (num == null) { return 0;}
    	if (num < floor) {return 0;} // will hit x axis and equals lowest value in range NOT necessarily actual scaled value
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
			_title = "Trends";
		}					
		// heading at 50% of X and 11% of Y
		dc.drawText( ctrX, (dispH * 11)/100, mTitleFont, _title, mJust);
		_title = null;
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);
	
		//var _lineStart = (dispH * 27) /100; //% of total height
		//var _lineEnd = floorY; //(dispH * 71) / 100;
		var yStep = ((_lineEnd - _lineStart) / 6.0).toNumber();
		var yInit = _lineStart;
		
		//Sys.println("yStep = "+yStep+", yInit = "+yInit);
		
		for (var i=0; i < 7; i++) {
			// 0.6.4 Draw rectangle using computed numbers
			dc.drawRectangle( leftX, yInit, _cWidth, 1);
			yInit += yStep;
			//dc.drawRectangle(mScr[32], mScr[24+i], mScr[31], 1);
			//Sys.println("Rect Coords: "+mScr[32]+", "+mScr[24+i]+", "+mScr[31]);
		}
		
		//Sys.println("rect draw final line coord: "+yInit+" with step:"+yStep);
		
		// Adjust floorY for rounding errors in stepping lines down
		// we have gone one step too far
		floorY = yInit - yStep;
		
		if ( mView == 0 ) {
			drawHistory(dc);
		} else {
			drawLongTerm(dc);
		}
		
	}

(:notdebugHist)
	function loadTest() {
	}
	
(:debugHist)	
	function loadTest( _baseUtc) {
	
		var testD;
		var testD2;
		
		Sys.println("loadTest utc base: "+_baseUtc);
		
		testD = [ 4150800,24,
			3985200,26,
			3988800,22,
			3996000,30,
			3895200,35,
			3812400,38,
			3726000,43,
			3639600,42,
			3553200,39,
			3466800,20,
			3380400,17,
			3294000,35,
			3207600,23,
			3121200,23,
			3034800,25,
			2948400,26,
			2862000,19,
			2775600,24,
			2689200,26,
			2602800,22,
			2516400,30,
			2430000,35,
			2343600,38,
			2257200,43,
			2170800,42,
			2170800,39,
			2170800,20,
			1911600,17,
			1825200,35,
			1738800,23,
			1652400,23,
			1566000,25,
			1479600,26,
			1393200,19,
			1306800,24,
			1220400,26,
			1134000,22,
			1047600,30,
			961200,35,
			874800,38,
			788400,43,
			702000,42,
			615600,39,
			529200,20,
			442800,17,
			442800,35		
			];	
			
		testD2 = [
			4586400,24,
			4500000,26,
			4413600,22,
			4327200,30,
			4240800,35,
			4154400,38,
			4064400,43,
			3985200,42,
			3988800,39,
			3996000,20,
			3895200,17,
			3812400,35,
			3726000,23,
			3639600,23,
			3553200,25,
			3466800,26,
			3380400,19,
			3294000,24,
			3207600,26,
			3121200,22,
			3034800,30,
			2948400,35,
			2862000,38,
			2775600,43,
			2689200,42,
			2602800,39,
			2516400,20,
			2430000,17,
			2343600,35,
			2257200,23,
			2170800,23,
			2170800,25,
			2170800,26,
			1911600,19,
			1825200,24,
			1738800,26,
			1652400,22,
			1566000,30,
			1479600,35,
			1393200,38,
			1306800,43,
			1220400,42,
			1134000,39,
			1047600,20,
			961200,17,
			874800,35,
			788400,23,
			702000,23,
			615600,25,
			529200,26,
			442800,19,
			442800,24,
			345600,26,
			259200,22,
			259200,30,
			172800,35 ];
		
		
		GG.resetResGLArray();
			
		// Write data into array as much as we have
		for(var i = 0; i < testD.size(); i = i+2) {
			GG.resGL[i] = (_baseUtc - testD[i]).toNumber();
			GG.resGL[i+1] = testD[i+1]; //HRV
			GG.resGLIndex++;
		}
		
		Sys.println("Created resGL:"+GG.resGL);
		
		// Save to storage
		GG.storeResGL();
		
		// discard memory to force load
		GG.resGL = null;	
		GG.resGLIndex = 0;
		testD = null;	
		testD2 = null;	
	}
	
	function drawLongTerm(dc) {
		   
	    dc.setColor( $.Label3Colour, Gfx.COLOR_TRANSPARENT);
	    var _EnT = false; // enable trend if enough data
	    var _x = ctrX;
        var _y = (dispH * 88 ) / 100;		
		dc.drawText( _x, _y, mLabelFont, "RMSSD", mJust);	
		
		// Need to load required data
		// can use existing function...		
		var _stats = [ 0, 0, 0, 0];
		var startMoment = Time.now();
		var utcStart = startMoment.value() + Sys.getClockTime().timeZoneOffset;
		
		loadTest( utcStart);

    	// loads up resGL;		
		// need to check whether we have loaded results already and have _res as available and array
		if (GG.resGL == null) {
			// load data for history				
			Sys.println("Loading Trend HRV results");
			
			// _resT is minD, MaxD, minHRV, maxHRV, count of tests
			// retrieve data, assume no new result and don't compare min/max to test values
			_resT = GG.retrieveResGL( utcStart, _stats, true);
			_stats = null;
			// returns true if have more than 2 real days
			_EnT = GG.calcTrends( utcStart, 0.0, _resT[0]);
			// want to see mTrendST, LT, MT values from this	
		}
		// Hopefully now mTrendXX setup
		
		// TEST CODE in TEST MODE
		if ( $.mTestMode) {
			if (GG.mTrendLT ==  null) {Sys.println("Null trend in History");}
			Sys.println("_res = "+_resT+"\n"+"resGL="+GG.resGL+"\n"+"LT="+GG.mTrendLT+"\n"+"MT="+GG.mTrendMT+"\n"+"ST="+GG.mTrendST);
		}
		// END TEST CODE
		
		// Determine range of data - already done in load of data
		// - count # samples, min/max, #days covered, date of latest sample = day N
		// - output Y scale factor for data		
		// probably should check we have a count! Also might want to check whether if a test wasn't done today that date measure works - might 
		// need to look at data for last test date
		// sets ceil, floor, range and scaleY then draws UY axis labels
		defineRange( dc, _resT[4], _resT[2], _resT[3]);
		
		// Number of days covered by data found in results
		var _minDate = (_resT[0] - _resT[0] % 86400); // Date format 
		var _str2 = ( _minDate / 86400); // as actual days
		var _maxDate = (_resT[1] - _resT[1] % 86400); 
		var _str3 = ( _maxDate / 86400);
		var days = _str3 - _str2 + 1;
		
		Sys.println("Days covered by tests ="+days);
		
		if (days <= 1) { return;}

		// this is number of total days we have in results
		var _listSize = GG.mSortedRes.size();
				
		// Work out X scale - limited by pixel number and dot size
		// - assume dot is 2x2 pixel and chartWidth = W. Min pitch = 3 pixels
		// - number of days to plot = min ( #days, W/3)
		// - pixel pitch = max ( W / 3 , W / #days)  
		// - dates in range of interest = date of youngest sample - #days to plot TO date of youngest sample
		
		// X-SCALE imp
		// Fixed pitch at 3 as xStep
		// We can then work out maximum number of days to plot
		var numDaysMax = _cWidth / xStep;
		
		// plot of day values starts at this position
		var _index; // = _listSize - days - 1; // plot point at x=0 so get additional point				
		var sDay; //this day is the day we must be greater than or equal to for plotting
		
		if (_listSize <= numDaysMax) {
			// we have fewer days than we can display so start at start of day list
			_index = 0;
			// our search of results can start at _minDate
			sDay = _minDate; // not x needs to start from 0

		} else {
			// we need to start from a point part way along day list
			_index = _listSize - numDaysMax;
			sDay = _minDate + _index * 86400; // move date along to align with day average plot
		}

		//if ( _listSize > numDaysMax) { 
		//	days = numDaysMax; // number of days so not DATE format
		//	_index = _listSize - days - 1;
			// now need to work out first day in data. 
			// - every day has an entry in ordered days and may contain zero entries
			// - resGL list may not have entry on this day as only results days
		//	sDay = _maxDate - numDaysMax * 86400; // in time format			
		//} else {
			// days has number of entries and we know it will fit on chart
		//	sDay = _minDate; // start at earliest
		//	_index = 0;
		//}
		
		Sys.println("_index ="+_index+", listsize="+_listSize);		
		Sys.println("Date info: sDay="+sDay+", _minDate:"+_minDate+", _maxDate:"+_maxDate+", days covered plot:"+days+", max days in chart W:"+numDaysMax);
		
		// Plot X data
		// - Run through whole results array looking for dates in range of interest
		// - Scatter plot using scaled HRV data on Y axis, X axis = pitch * day number
		// Need to check how range matches actual values
		// Note: day calc OK as we are not worried about timing within day

		// ------ do scatter plot ----------
		// points in white		
		var yCoord;
		var xDate;
		dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		
		Sys.println("_minDate as day ="+_minDate/86400+" sDay as days="+sDay/86400);
		
		// x value of plot needs to start at zero to align with days plot
		for (var d=0; d < RESGL_ARRAY_SIZE; d+=2) {	
		 	var _date =	GG.resGL[d];	
			// is date in range
			if (_date >= sDay) {
				xDate = (_date - sDay) / 86400;
				yCoord = scale( GG.resGL[d+1]);
				Sys.println("xDate: "+xDate+" yCoord: "+yCoord+" scaled from "+GG.resGL[d+1]);
				xDate = xDate.toNumber() * xStep;
				dc.fillRectangle(leftX+xDate, floorY-yCoord, 3, 3);			
			}		
		}
		
		// need to TEST FOR not enough entries for a line
		if (_listSize < 2) { return;}	
				
		// Use regression data from test just completed 
		// - will need to only draw lines over date range drawn on screen using pitch
		// - #days determines which or ST, MT, LT gets drawn suitably scaled. Could have all to none drawn
		// - Use same day thresholds as in regression calc
		// Regression starts at a nominal day 1
		if (_EnT ) {
			// Plot regression lines as should have some! Check each one for 0 entries
			// pick colours for each
			
			// #days in array: 45, 28, 3 are thresholds for regression to be calculated in glanceGen			
			var _sX; // start X
			var _sY; // start Y
			var _eX;
			var _eY;
			
			// check data exists. ie more than 45 days of data
			if (GG.mTrendLT !=  null && GG.mTrendLT[0] != 0 && _listSize > 45) {
				// we know that trend would not be created unless we had this much data
				_sX = 0; // starts at earliest day
				_eX = _listSize * xStep;
				_sY = scale( GG.mTrendLT[1] * 1 + GG.mTrendLT[0]);
				_eY = scale( GG.mTrendLT[1] * _listSize + GG.mTrendLT[0]); 
				dc.setPenWidth(2);	
				dc.setColor( Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
				dc.drawLine(leftX + _sX, floorY - _sY, leftX + _eX, floorY - _eY);
			}
			
			// now do monthly
			
			
			// now do weekly
			
			
		
		}
		
		
		// Could plot line through averages as data should be in glance array
		// Need to again check how day numbers are calculated and use same - array was ordered in time ie [0] is oldest
		
		// mSortedRes contains daily averages
		//Sys.println("ordered days: "+GG.mSortedRes);
		
		// draw the data 
		dc.setPenWidth(2);	
		dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);

		var _ind = _index; // don't corrupt index just in case
		var x1 = 0;
		var y1 = scale( GG.mSortedRes[_ind]);
		
		Sys.println("Results per day Size:"+GG.mSortedRes.size()+" data:"+GG.mSortedRes);
		
		_ind++; // move past initial point
		var x2 = 0;
		var y2;
		//for ( var i=_index; i < _listSize; i++) { // need to test ranges used
		while (_ind < _listSize)  { 
			x2 += xStep;		
			var _pt = GG.mSortedRes[_ind];
			if ( _pt != 0) {
				y2 = scale( _pt);
				Sys.println("y2:"+y2+" from "+_pt);
				// have a data point so update
				dc.drawLine(leftX + x1, floorY - y1, leftX + x2, floorY - y2);
				y1 = y2;
				x1 = x2;
			}
			Sys.println("_ind="+_ind);
			_ind++;
		} 
	
	}
	
	
	// Work out data range for Y axis then draw labels assuming 7 lines ie 6 gaps
	// _dataCnt : number of points we have. Check we have some otherwise default range
	// _min/_max : min and max of dataset
	function defineRange( dc, _dataCnt, _min, _max) { 
		// If no results then set min & max to create a nice graph scale
		var min = (_min+0.5).toNumber();
		var max = (_max+0.5).toNumber();
		
		if ( 0 == _dataCnt){
			min = 0;
			max = 30;
		}

		// Create the range in blocks of 5
		ceil = (max + 5) - (max % 5);		
		floor = min - (min % 5);
		//if (floor < 0 ) { floor = 0;}
		
		// now expand to multiple of 10 as height also multiple of 10. 
		// Ensure floor doesn't go negative  
		var test = (ceil - floor) % 10;
		if (test == 5) { 
			ceil += 5;
		} 
		range = ceil - floor;
		
		// chartHeight defines height of chart and sets scale
		scaleY = chartHeight / range.toFloat();
		
		//var _lineStart = (dispH * 27) /100; //% of total height
		//var _lineEnd = (dispH * 71) / 100;
		var yStep = ((_lineEnd - _lineStart) / 6.0).toNumber();
		var yInit = _lineStart;
		// 11% across
		var xPos = ( dc.getWidth() * 11) / 100;
		
		// Draw the numbers on Y axis	
		// NOTE COULD DRAW ONLY HALF OF THESE ON SMALL SCREENS ie 240x240 use the mDeviceType value
		// Built new font instead
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		var gap = (ceil-floor);	
		for (var i=0; i<7; i++) {
			var num = ceil - ((i * gap) / 6.0); // may need to be 7.0
			// just use whole numbers
			var str = format(" $1$ ",[num.format("%d")] );	
			dc.drawText( xPos, yInit, mLabelFont, str, mJust);
			yInit += yStep;
		}
		
	}

	function drawHistory(dc) {		
				
		var dataCount = 0;
		var max = 0;
		var min = 1000;
	
		var labelList = new [MAX_DISPLAY_VAR];
		var resultsIndexList = new [MAX_DISPLAY_VAR];
		
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
        var _x = (dispW * 30 ) / 100;
        var _y = (dispH * 79 ) / 100;
        dc.setColor( $.Label1Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( _x, _y, mLabelFont, labelList[0], mJust);	
		
		_x = (dispW * 64 ) / 100;		
        dc.setColor( $.Label2Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( _x, _y, mLabelFont, labelList[1], mJust);	
		
		_x = ctrX;
        _y = (dispH * 88 ) / 100;
		dc.setColor( $.Label3Colour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( _x, _y, mLabelFont, labelList[2], mJust);	
		
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

		// sets ceil, floor, range and scaleY
		// draws Y axis
		defineRange( dc, dataCount, min, max);
		
		// draw final title
		_x = (dispW * 70 ) / 100;
        _y = (dispH * 23 ) / 100;
		dc.drawText( _x, _y, mLabelFont, "newer->", mJust);	
		
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
				
				//Sys.println("LeftX: "+leftX+", x1: "+x1+", x2: "+x2+" floorY: "+floorY+" l1v1: "+mLabel1Val1+" l1v2: "+mLabel1Val2+
				//	" l2v1: "+mLabel2Val1+" l2v2: "+mLabel2Val2+
				//	" l3v1: "+mLabel3Val1+" l3v2: "+mLabel3Val2
				//);

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
    	Sys.println("History view:"+mView+" hide");
    	// free up all the arrays - NO as maybe switches without a new ...
    	mLabelFont = null;
    	//GG.resGL = null;
    	GG.purgeMemG();
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