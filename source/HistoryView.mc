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
//(:UseJson)
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
	//hidden var range;
	hidden var ce_ceil;
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
	
	// X-SCALE imp
	// Fixed pitch at 4 as xStep
	// We can then work out maximum number of days to plot
	hidden var numDaysMax;
	
	// plot of day values starts at this position
	hidden var _index; // = _listSize - days - 1; // plot point at x=0 so get additional point				
	hidden var sDay; //this day is the day we must be greater than or equal to for plotting
	hidden var _eX; // how far do we draw regression lines for
	hidden var _listSize;
	hidden var noDaysToTrend = true; // needs to be false to draw trend data no days found
   
	function initialize( _mView) {
	 	if (_mView > 1) { mView = 0;} else { mView = _mView;}
		View.initialize();
	}
	
	function onLayout(dc) {

		var a = Ui.loadResource(Rez.Strings.HistoryGridWidth);
		cGridWidth = a.toNumber();
		
		// chartHeight now a calculated value in 0.6.6
		//a = Ui.loadResource(Rez.Strings.HistoryGridHeight);
		//chartHeight = a.toNumber();
		//a = null;

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
		
		// 0.6.6 lets see if chartHeight can come from actual display 
		chartHeight = _lineEnd - _lineStart;
		
		//Sys.println("_lineStart="+_lineStart+", _lineEnd="+_lineEnd+" means height ="+chartHeight);
		
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
			Sys.println("Trend display width = "+_cWidth);
			xStep = 4;		
		}
		//Sys.println("Start: "+_lineStart+", end: "+_lineEnd+" leftX is "+leftX+", _cWidth is: "+_cWidth);
				
		return true;
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    	//0.6.6 move out of update the resource intensive parts
    	
    	if (mView == 0) { return; } // conventional view
    	
    	// build arrays for trend view
    	Sys.println("History onShow()");
    	noDaysToTrend = initTrends();    
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
	function loadTest( _baseUtc) {
	}
	
(:debugHist)	
	function loadTest( _baseUtc) {
	
		var testD;
		var testD2;
		var testD3;
		var testD4;
		
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
			
		testD3 = [
		4586400,48.85738026,
		4500000,69.53196572,
		4413600,58.45802115,
		4327200,25.81688012,
		4240800,1.618657153,
		4154400,8.111086854,
		4064400,39.3250593,
		3985200,66.56259217,
		3988800,66.56259217,
		3996000,66.56259217,
		3895200,64.78162336,
		3812400,35.61956738,
		3726000,5.887884008,
		3639600,2.921745823,
		3553200,29.44820659,
		3466800,61.07896062,
		3380400,68.73283852,
		3294000,45.37290025,
		3207600,12.47616533,
		3121200,0.287740129,
		3034800,20.01360657,
		2948400,53.51789401,
		2862000,69.9969151,
		2775600,54.29993384,
		2689200,20.85868241,
		2602800,0.418893157,
		2516400,11.77281405,
		2430000,44.48170259,
		2343600,68.47315749,
		2257200,61.68954577,
		2170800,30.36768875,
		2170800,30.36768875,
		2170800,30.36768875,
		1911600,34.69020417,
		1825200,64.28294735,
		1738800,66.95308378,
		1652400,40.24570234,
		1566000,8.715446363,
		1479600,1.351087784,
		1393200,24.92338392,
		1306800,57.76007441,
		1220400,69.67125745,
		1134000,49.70584629,
		1047600,16.21994787,
		961200,0.000342771,
		874800,15.95926112,
		788400,49.42414698,
		702000,69.62753863,
		615600,57.99453096,
		529200,25.22045756,
		442800,1.437650387,
		442800,1.437650387,
		345600,8.511912664,
		259200,39.93920028,
		259200,39.93920028,
		172800,66.82540994,
		97200,64.45148447
		];
		
		testD4 = [
			1821600,64.28294735,
			1735200,66.95308378,
			1648800,40.24570234,
			1389600,24.92338392,
			1220400,69.67125745,
			1137600,49.70584629,
			957600,0.000342771,
			874800,15.95926112,
			788400,49.42414698,
			702000,69.62753863,
			615600,57.99453096,
			356400,8.511912664,
			270000,39.93920028,
			183600,66.82540994,
			97200,64.45148447	
		];
		
		
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
		testD3 = null;
		testD4 = null;
	}
	
	function initTrends() {
		
		// Need to load required data
		// can use existing function...		
		var _stats = [ 0, 0, 0, 0];
		var startMoment = Time.now();
		var utcStart = startMoment.value() + Sys.getClockTime().timeZoneOffset;
		startMoment = null;
				
		// stub if annotation disables test data load 
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
			// returns true if have more than 2 real days for ST test
			GG.calcTrends( utcStart, 0.0, _resT[0]);
			utcStart = null;
			// want to see mTrendST, LT, MT values from this	
		}
	
		// Hopefully now mTrendXX setup
		
		// TEST CODE in TEST MODE
		//Sys.println("_res = "+_resT+"\n"+"resGL="+GG.resGL+"\n"+"LT="+GG.mTrendLT+"\n"+"MT="+GG.mTrendMT+"\n"+"ST="+GG.mTrendST);		
		// END TEST CODE
		
		// Number of days covered by data found in results
		var _minDate = (_resT[0] - _resT[0] % 86400); // Date format 
		//var _str2 = ( _minDate / 86400); // as actual days
		var _maxDate = (_resT[1] - _resT[1] % 86400); 
		//var _str3 = ( _maxDate / 86400);
		//var days = _str3 - _str2 + 1;
		
		//Sys.println("Days covered by tests = "+days);
		
		//if (days <= 1) { return;}
		if ( _maxDate / 86400 -  _minDate / 86400 + 1 <= 1) { return true;} // no days found
		//days = null;
		//_str2 = null;
		//_str3 = null;

		// this is number of total days we have in results
		_listSize = GG.mSortedRes.size();
		
		if ($.mTestMode) {
			Sys.println("Days array="+GG.mSortedRes);
		}
				
		// Work out X scale - limited by pixel number and dot size
		// - assume dot is 2x2 pixel and chartWidth = W. Min pitch = 3 pixels
		// - number of days to plot = min ( #days, W/3)
		// - pixel pitch = max ( W / 3 , W / #days)  
		// - dates in range of interest = date of youngest sample - #days to plot TO date of youngest sample
		
		// X-SCALE imp
		// Fixed pitch at 4 as xStep
		// We can then work out maximum number of days to plot
		numDaysMax = _cWidth / xStep;
		
		// plot of day values starts at this position
		//var _index; // = _listSize - days - 1; // plot point at x=0 so get additional point				
		//var sDay; //this day is the day we must be greater than or equal to for plotting
		//var _eX; // how far do we draw regression lines for
		
		if (_listSize <= numDaysMax) {
			// we have fewer days than we can display so start at start of day list
			_index = 0;
			// our search of results can start at _minDate
			sDay = _minDate; // not x needs to start from 0
			_eX = _listSize * xStep;
		} else {
			// we need to start from a point part way along day list
			_index = _listSize - numDaysMax;
			sDay = _minDate + _index * 86400; // move date along to align with day average plot
			_eX = numDaysMax * xStep;
		}
		
		Sys.println("_index ="+_index+", listsize="+_listSize+
				", Date info: sDay="+sDay+", _minDate:"+_minDate+", _maxDate:"+_maxDate+", max days in chart W:"+numDaysMax+				
				", _minDate as day="+_minDate/86400+" sDay as days="+sDay/86400);
				
		return false;
	
	}
	
	// check Y in range of chart and return coord for plot
	function checknScale( inY) {
		var _outY;
			
		// cap _eY at top of chart and _sY at bottom	
		// take off 1 to cater for rounding
		if ( inY < floor) {
			_outY = scale (floor);
		} else if ( inY > ce_ceil) {
			_outY = scale (ce_ceil-1);
		} else {
			_outY = scale (inY);
		}
	
		return _outY;
	}
	
	function drawLongTerm(dc) {
		var _maxY = 0;
		   
	    dc.setColor( $.Label3Colour, Gfx.COLOR_TRANSPARENT);
	    //var _EnT = false; // enable trend if enough data
	    var _x = ctrX;
        var _y = (dispH * 88 ) / 100;		
		dc.drawText( _x, _y, mLabelFont, "RMSSD", mJust);	
		
		// Determine range of data - already done in load of data
		// - count # samples, min/max, #days covered, date of latest sample = day N
		// - output Y scale factor for data		
		// probably should check we have a count! Also might want to check whether if a test wasn't done today that date measure works - might 
		// need to look at data for last test date
		// sets ce_ceilfloor, range and scaleY then draws UY axis labels
		_maxY = defineRange( dc, _resT[4], _resT[2], _resT[3]);
		
		// need at least one day between samples
		if (noDaysToTrend) { return;} 
				
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
	
		// x value of plot needs to start at zero to align with days plot
		for (var d=0; d < RESGL_ARRAY_SIZE; d+=2) {	
		 	var _date =	GG.resGL[d];	
			// is date in range
			if (_date >= sDay) {
				xDate = (_date - sDay) / 86400;
				yCoord = scale( GG.resGL[d+1]);
				//Sys.println("xDate: "+xDate+" yCoord: "+yCoord+" scaled from "+GG.resGL[d+1]);
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

		// #days in array: number of days found with actual data in regression calculated in glanceGen			
		var _sX; // start X
		var _sY; // start Y
		//var _eX;
		var _eY;
		// Plot regression lines as should have some! Check each one for 0 entries

		//_eX = _listSize * xStep;
		
		dc.setPenWidth(3);
		// check data exists. 
		// assume that regression test itself checks we have enough points in range of interest
		// All we need are three data points for the trend. Could be anywhere over the days since first test taken
		if (GG.mTrendLT !=  null && GG.mTrendLT[3] >= 3 && GG.mTrendLT[0] != 0)  {
			// we know that trend would not be created unless we had this much data
			_sX = 0; // starts at earliest day
			_sY = checknScale( GG.mTrendLT[1] * 1 + GG.mTrendLT[0]);
			_eY = checknScale( GG.mTrendLT[1] * _listSize + GG.mTrendLT[0]); 
			dc.setColor( Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
			dc.drawLine(leftX + _sX, floorY - _sY, leftX + _eX, floorY - _eY);
		}

		// now do monthly
		if (GG.mTrendMT !=  null && GG.mTrendMT[0] != 0 && GG.mTrendMT[3] >= 3) {
			// trend for last 28 days. to have this regression line must have this number of days
			// however, for defensive programming check anyway
			_sX = _listSize - _index - 28; // start at earliest day
			_sX = _sX < 0 ? 0 : _sX * xStep;
			
			// x for trend starts at 1 and goes for length ???
			_sY = checknScale( GG.mTrendMT[1] * 1 + GG.mTrendMT[0]);
			_eY = checknScale( GG.mTrendMT[1] * 28 + GG.mTrendMT[0]); 
			dc.setColor( Gfx.COLOR_PINK, Gfx.COLOR_TRANSPARENT);
			dc.drawLine(leftX + _sX, floorY - _sY, leftX + _eX, floorY - _eY);			
		}

		// now do weekly
		if (GG.mTrendST !=  null && GG.mTrendST[0] != 0 && GG.mTrendST[3] > 2) {
			//_sX = (_listSize - 7) * xStep; // starts at earliest day
			// trend for last 7 days. to have this regression line must have this number of days
			// however, for defensive programming check anyway
			_sX = _listSize - _index - 7;
			_sX = _sX < 0 ? 0 : _sX * xStep;
			// _eX = _listSize * xStep;
			//_sY = scale( GG.mTrendST[1] * 1 + GG.mTrendST[0]);		
			_sY = checknScale( GG.mTrendST[1] * 1 + GG.mTrendST[0]);
						
			//_eY = scale( GG.mTrendST[1] * 7 + GG.mTrendST[0]); 				
			var _val2 =  GG.mTrendST[1] * 7 + GG.mTrendST[0];			
			// cap _eY at top of chart			
			// take off 1 to cater for rounding
			//_eY = _val2 > ce_ceil ? scale ( ce_ceil - 1) : scale (_eY);			
			_eY = checknScale( _val2);
											
			//Sys.println("_val2:"+_val2+", ce_ceil:"+ce_ceil+", floor:"+floor+", eY:"+_eY+", floorY:"+floorY+", scaleY:"+scaleY);	

			//Sys.println("ST plot: _sX= "+_sX+" _sY= "+_sY+" end X= "+_eX+" _eY: "+_eY);
			dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
			dc.drawLine(leftX + _sX, floorY - _sY, leftX + _eX, floorY - _eY);			
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
		
		//Sys.println("Results per day Size:"+GG.mSortedRes.size()+" data:"+GG.mSortedRes);
		
		_ind++; // move past initial point
		var x2 = 0;
		var y2;
		//for ( var i=_index; i < _listSize; i++) { // need to test ranges used
		while (_ind < _listSize)  { 
			x2 += xStep;		
			var _pt = GG.mSortedRes[_ind];
			if ( _pt != 0) {
				y2 = scale( _pt);
				//Sys.println("y2:"+y2+" from "+_pt);
				// have a data point so update
				dc.drawLine(leftX + x1, floorY - y1, leftX + x2, floorY - y2);
				y1 = y2;
				x1 = x2;
			}
			//Sys.println("_ind="+_ind);
			_ind++;
		} 
		
		// TEST CODE		
		//Sys.println("History-2 used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	
	
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
		ce_ceil = (max + 5) - (max % 5);		
		floor = min - (min % 5);
		//if (floor < 0 ) { floor = 0;}
		
		// now expand to multiple of 10 as height also multiple of 10. 
		// Ensure floor doesn't go negative  
		var test = (ce_ceil - floor) % 10;
		if (test == 5) { 
			ce_ceil += 5;
		} 
		//range = ce_ceil floor;
		
		// chartHeight defines height of chart and sets scale
		//scaleY = chartHeight / range.toFloat();
		scaleY = chartHeight / (ce_ceil - floor).toFloat();
		
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
		var gap = (ce_ceil- floor);	

		for (var i=0; i<7; i++) {
			var num = ce_ceil - ((i * gap) / 6.0); // may need to be 7.0
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
		var resIndL = new [MAX_DISPLAY_VAR]; // resultsIndexList
		
		if ( $.results == null) {
			prepResults();
		}
		
		var mHistoryLabelList = Ui.loadResource(Rez.JsonData.jsonHistoryLabelList); 
		
		//0.4.3 - Now have list available to match label and colour!
		// resIndL to null if no data to display
		if ( $.mHistoryLabel1 == 0 && $.mHistoryLabel2 == 0 && $.mHistoryLabel3 == 0) {
			mHistoryLabelList = null;
			return;
		}	
		 
		labelList[0] = mHistoryLabelList[$.mHistoryLabel1];
        resIndL[0] = ( $.mHistoryLabel1 == 0 ? null : $.mHistoryLabel1);
		labelList[1] = mHistoryLabelList[$.mHistoryLabel2];
        resIndL[1] = ( $.mHistoryLabel2 == 0 ? null : $.mHistoryLabel2);
		labelList[2] = mHistoryLabelList[$.mHistoryLabel3];
        resIndL[2] = ( $.mHistoryLabel3 == 0 ? null : $.mHistoryLabel3);   
        
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
		
		//Sys.println("labelList = "+labelList+" resIndL = "+resIndL);
		
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
					var j = resIndL[i];					
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

		// sets ce_ceilfloor, range and scaleY
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
				var j = resIndL[i];	
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
			if (resIndL[0] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel1Val1, 2);}
			dc.setColor($.Label2Colour, $.mBgColour);
			if (resIndL[1] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel2Val1, 2);}					
			dc.setColor($.Label3Colour, $.mBgColour);
			if (resIndL[2] !=null ) {dc.fillCircle(leftX + 3, floorY - mLabel3Val1, 2);}	
			
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
					var j = resIndL[i];	
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
					var j = resIndL[i];	
					// shouldn't need null test as have number of valid entries and already checked not zero			
					if (j != null) {
						firstData[i] = $.results[secondIndex+j].toNumber();
					} // j != null
				} // for each display value

				// scale can return null which need to check on draw
	 			var mLabel1Val2 = scale(firstData[0]);
	 			var mLabel2Val2 = scale(firstData[1]);
	 			var mLabel3Val2 = scale(firstData[2]);	
	 			
	 			//Sys.println("#2 firstData, resIndL and #points, secondIndex :"+firstData+", "+resIndL+", #"+pointNumber+","+secondIndex);			

				dc.setColor($.Label1Colour, $.mBgColour);
				if (resIndL[0] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel1Val1, leftX + x2, floorY - mLabel1Val2);}
				dc.setColor($.Label2Colour, $.mBgColour);
				if (resIndL[1] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel2Val1, leftX + x2, floorY - mLabel2Val2);}
				dc.setColor($.Label3Colour, $.mBgColour);
				if (resIndL[2] !=null ) {dc.drawLine(leftX + x1, floorY - mLabel3Val1, leftX + x2, floorY - mLabel3Val2);}
				
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
		//Sys.println("History-1 used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);
		
    }
    
    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	//Sys.println("History view:"+mView+" hide");
    	// free up all the arrays - NO as maybe switches without a new ...
    	mLabelFont = null;
    	//GG.resGL = null;
    	GG.purgeMemG();
  		//remove buffer
		freeResults();  	
    }
}