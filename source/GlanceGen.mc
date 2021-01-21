using Toybox.System as Sys;  
using Toybox.UserProfile;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.Math;
using Toybox.WatchUi as Ui;
using Toybox.Application.Properties; // as Property;
using Toybox.Application.Storage as Storage;

// Uses 
//
// returns
// $.glanceData which is also stored in Storage

module GlanceGen
{
	// Results array variable
	var resGL = null;
	//var mHistorySelectFlags;
	// write pointer into results array
	var resGLIndex = 0;
	
	var mLowAge = 0.0;
	var mHighAge = 0.0;
	
	var mSortedRes = null;
	// trend data y=a+bx and R2 [a, b, r]
	var	mTrendLT = new[3];
	var	mTrendMT = new[3];
	var	mTrendST = new[3];
	
    function getHRVAgeRange() {
    	var min = null;
    	var max = null;
    	
    	var mAgeUser = 0;
    	var mHRVGender = null;
    	
    	var mYear = UserProfile.getProfile().birthYear;
    	var mGender = UserProfile.getProfile().gender;
    	
    	if (mGender == null) {
    		// none set to will need to fake range?
    		Sys.println("No gender found in profile");
    		min = 0.0;
    		max = 100.0;
    		
    		Sys.println("HRV range forced to "+min+" to "+max);   	
    		return [min.toFloat(), max.toFloat()];    
    			
    	} else if (mGender == UserProfile.GENDER_FEMALE) {
    		// load female HRV range
    		mHRVGender = Ui.loadResource(Rez.JsonData.jsonFemaleHRV); 
    	} else {
    		// load male HRV range
    		mHRVGender = Ui.loadResource(Rez.JsonData.jsonMaleHRV); 
    	}
    	
    	if (mYear == null) {
    		// handle no age set 
    		Sys.println("generateResults: no age found. Assuming 35");
    		mAgeUser = 35;    		
    	} else {
    		var mCurrYear = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM).year;
    		mAgeUser = mCurrYear - mYear.toNumber();
    		Sys.println("year is "+mCurrYear+" user year ="+mYear+" gives age="+mAgeUser);
    	}	
    	
    	var mLastAge = mHRVGender.size()-3;
    	if (mAgeUser < mHRVGender[0]) {
    		min = mHRVGender[2];
    		max = mHRVGender[3];
    	} else if ( mAgeUser > mHRVGender[mLastAge]) {
    		min = mHRVGender[mLastAge+1];
    		max = mHRVGender[mLastAge+2];    	   	
    	} else {
	    	// data is four items
	    	for (var i=0; i < mHRVGender.size(); i = i+4) {
	    		if ((mAgeUser >= mHRVGender[i]) && (mAgeUser <= mHRVGender[i+1])) {
		    		min = mHRVGender[i+2];
		    		max = mHRVGender[i+3];
		    		break;	    			
	    		}	    	
	    	}
    	}
    	    	
    	Sys.println("HRV range for age is "+min+" to "+max);
    	
     	mHRVGender = null;   	
    	return [min.toFloat(), max.toFloat()];
    }
    
    // scan results array skipping empty entries for min/max range of HRV
    // now done in data read
(:discard)
    function getHRVActualRange() {
        var min = 100.0;
    	var max = 0.0;	
    	var count = 0;
 
 		// need to look at all entries
		for (var i=0; i < RESGL_ARRAY_SIZE; i+=GL_SET_SIZE) {
			if ( resGL[i] == 0) { continue; }
			var val = resGL[i+1];
			count++;
			if (val > max ) { max = val;}
			if (val < min ) { min = val;}
		}
    
     	Sys.println("HRV actual range is "+min+" to "+max);
    	
    	if (min == 0 && max == 0) {
    		// array empty but date possibly set
    		return [0.0, 100.0, count];
    	} else { 
    		return [min, max, count];
    	}      
    }
    
    // return [ monthly, weekly] average of HRV data where it exists
    // will average all values in the week and then add up and average weekly
    // Don't provide a monthly average until we have four weeks of data
	function calcHRVAvg( _today) {
		// work four separate weeks
		var mWeekly = [0, 0, 0, 0];
		// count of entries per week
		var mWkCnt = [0, 0, 0, 0];
		
		var mCurrWk = _today / 604800;
		var mSrchWk = 0;
		// now we need to look through results and see if entries fall in the right weeks!
		
		//Sys.println("calcHRVAvg: resGl size="+resGL.size());
		
		for (var i=0; i < resGL.size(); i+=GL_SET_SIZE) {
			// skip if no data
			if ( resGL[i] == 0) { continue; }
			
			// now we have a date. Which week is it offset from today (make +ve for back in time
			mSrchWk =  mCurrWk - resGL[i] / 604800;
			
			var tmp = resGL[i] / 604800;
			//Sys.println("calcHRVAvg: current wk="+mCurrWk+" found week="+tmp+" search week="+mSrchWk+" loop#="+i);
			 
			if (mSrchWk > 3 ) {continue;}
			
			// add HRV found to sum and inc cnt
			mWeekly[mSrchWk] +=  resGL[i+1];
			mWkCnt[ mSrchWk]++; 
		}
		
		// work out week averages
		for (var i=0; i < 4; i++) {
			// only average weeks with values!
			if ( mWkCnt[i] == 0) { continue; }
			mWeekly[i] = mWeekly[i] / mWkCnt[i].toFloat();
		}
				
		var mMonthAvg = 0;
		var mMcnt = 0;
		for (var i=0; i < 4; i++) {
			// only average weeks with values!
			if ( mWeekly[i] == 0) { continue; }
			mMonthAvg += mWeekly[i];
			mMcnt++;
		}
		
		// Make it so we need four weeks
		if (mMcnt == 4) { mMonthAvg = mMonthAvg / mMcnt.toFloat(); } else { mMonthAvg = 0;}
		
		Sys.println("Weekly averages="+mWeekly+" Monthly average="+mMonthAvg);
			
		return [ mMonthAvg, mWeekly[0] ];
	}
	
	function calcPosition( _HRV, _expected, _found) {
		var mPos = 0;
		
	    if ( _HRV >= _expected[0] && _HRV <= _expected[1]) {
     		mPos = 20 + 60.0 * ( _HRV - _expected[0]) / (_expected[1] - _expected[0]);
     	} else if (_HRV < _expected[0] ) {
     		// range it in the lower 20% 
     		// value must be lower than expected and also by implication min is also less
     		mPos = 20 * (_HRV - _found[0]) / (_expected[0] - _found[0]); 
     		// Monthly can be zero _HRV as no data 
     		if (mPos < 0 ) {mPos = 0;}   	
     	} else {
     		// over range for age
     		// range it in the upper 20% 
     		// value must be higher than expected and also by implication max is also more
     		mPos = 80 + 20 * (_HRV - _expected[1]) / (_found[1] - _expected[1]);     		
     	}     	
    	
    	mPos = mPos / 100.0;
    	Sys.println("Position in range is "+mPos+" percent based on HRV of "+_HRV);
		
		return mPos;
	}
	
	// we need to go through results and sort into daily buckets
	// Want to know number of days in range
	// passed first time stamp
	// Array created has today as highest index
	function orgData( _utc, minUtc) {
		//var minUtc = _utc; // can't be after today unless wrapped
		var val;
		var count=0;
		
		// find data range so we can work out number of entries
		//for (var i=0; i < RESGL_ARRAY_SIZE; i+=GL_SET_SIZE) {
		//	val = resGL[i];
		//	if (val == 0) { continue; } // no data
		//	if (val < minUtc ) { minUtc = val; Sys.println("New min date: "+val); }
		//}
		
		// now we could have big gaps in dates but not much we can do!
		mSortedRes = null;
		
		var _str2 = ((minUtc - minUtc % 86400) / 86400);
		var _str3 = ((_utc - _utc % 86400) / 86400);
		count = _str3 - _str2 + 1;
		
		Sys.println("UTC delta in seconds across dates: "+count+" based on oldest date of:"+_str2+" days");
		
		if (count <= 3) {
			Sys.println(" Not enough dates found for trend!");
			return false;
		} else {
			Sys.println("Days found ="+count);
		}
		
		mSortedRes = new [count];
		var mSortedCnt = new [ count];
		// zero array
		for (var i=0; i< count; i++) { mSortedRes[i] = 0.0; mSortedCnt[i] = 0;}
		
		// use simplistic algo to start to get daily averages
		// iterate through results finding which day each entry is in
		var mCurrDay = (_utc - _utc % 86400) / 86400; // might be able to do divide and round...
		mCurrDay = mCurrDay.toNumber();
		
		var mData = 0.0;
		for (var i=0; i < RESGL_ARRAY_SIZE; i+=GL_SET_SIZE) {
			var tmp = resGL[i];
			if ( tmp == 0) { continue; } // no date data
			
			var _str = ((tmp - tmp % 86400) / 86400);
			
			val = (count-1) - (mCurrDay - (tmp - tmp % 86400) / 86400); // get day number
			val = val.toNumber();
						
			// HRV might be zero but unlikley
			mData = resGL[i+1];
			
			//Sys.println("Today="+mCurrDay+" looking at day:"+_str+" day index="+val+" res index "+i+" HRV value="+mData);
			
			if ( mData == 0.0) { 
				continue; 
			} else {
				mSortedRes[val] += mData;
				mSortedCnt[val] = mSortedCnt[val]+1;			
			}						
		}
		
		//Sys.println("Pre avg sum="+mSortedRes+"\nCnt="+mSortedCnt);
		
		// Work out averages for array
		for (var i=0; i< count; i++) { 
			if ( mSortedCnt[i] == 0 ) { continue;}
			mSortedRes[i] = mSortedRes[i] / mSortedCnt[i]; 
		}
		
		Sys.println("Sorted "+count+" days with o/p="+mSortedRes);
		
		mSortedCnt = null;
		return true;
	}

//Trend
//1. All results ie LT. need representative data set eg more than a months worth
//2. Month into past (assuming each week has data)
//3. ST last 5 days (maybe days missing) including today
//4. Current reading (or all todays?) Compared to yesterday's average	

	// work out the trends of the HRV results
	// utStart = time of latest test
	// values returned are for ST trend
	// returns 0 if trend close to flat using FLATNESS as threshold otherwise +/- and size of gap from trend
	// returns flag true if enough data
	// mSortedRes has an entry for each day EVEN if empty ie always have required data points
	function calcTrends( _utc, _HRV, _minUtc) {		
		var mEnough = false;
		var HRVDelta = 0.0;
		
		// trend data y=a+bx and R2 [a, b, r]		
		mTrendLT = [0.0, 0.0, 0.0];
		mTrendMT = [0.0, 0.0, 0.0];
		mTrendST = [0.0, 0.0, 0.0];

		if ( !orgData( _utc, _minUtc) ) {
			// data for less than 3 days! Doesn't make a compelling case
			return [0.0, false];		
		} 
				
		// Calculate LT trend - this uses all of the data and should have >1.5 months
		if (mSortedRes.size() > 45) {
			mTrendLT = regressionLine( 0 );
		}

		// Calculate MT trend - this uses the last month of data and we should have > 28 days duration
		if (mSortedRes.size() > 28) {
			mTrendMT = regressionLine( 1 );
		}		
		
		// Calculate ST trend - this uses >3 days for last week (ie max 7 samples)
		if (mSortedRes.size() > 3) {
			mTrendST = regressionLine( 2 );
		}
		
		Sys.println("Regression line is [intersect, slope, R] LT="+mTrendLT+" MT="+mTrendMT+" ST="+mTrendST);
		
		// HRV delta is difference between ST trend and actual value
		// might need to range to see how flat...
		
		// what is expected for one week (max) trend
		var _num = (mSortedRes.size() >= 7 ? 6 : mSortedRes.size() - 1);
		var y = mTrendST[0]+ (mSortedRes.size()-1) * mTrendST[1];
		
		HRVDelta = _HRV - y;

		Sys.println("Measured HRV="+_HRV+" Expected trend HRV="+y+" gives delta:"+HRVDelta+" for "+_num+" samples");		

		return [HRVDelta, true];
	}
	
	// using data array slice calculate regression y=b+mx and fit coefficient
	// any Y value of zero is skipped
	// this function assumes there is enough data and this has already been calculated
	// function is not called if inadequate data
	
	// m (slope) = (n*(sum xy) - (sum x)*(sum y)) / (n*(sum x^2) - (sum x)^2)
	// b (intercept) = (sum y - m * sum x) / n

	// so need to calc sum x, sum y, sum (xy), sum (x^2), sum (y^2) (and additionally (sum x)^2 and (sum y)^2 )
	// in this case we need to ignore any zero values of y and hence reduce n

	// correlation coeff r. as near zero bad fit. Ranges from -1 to +1
	// r = (n* sum xy - sum x * sum y) / (SQRT( n* sum x^2 - (sum x)^2) * SQRT( n* sum y^2  - (sum y)^2 ))
	
	function regressionLine( _type ) {
		var mB = 0.0;
		var mM = 0.0;
		var mR = 0.0;
		var _startIdx = 0;
		
		var _sumY = 0.0;
		var _sumX = 0.0;
		var _sumXY = 0.0;
		var _sumX2 = 0.0; // sum of x^2
		var _sumY2 = 0.0; 
		var _NumSamp = 0; // actual number of valid values (could use _tmp in this)
		
		var	_cnt = mSortedRes.size(); // how many entries
		var _endIdx = _cnt-1 ; // end of array

		if (_type == 0) { // LT 
			_startIdx = 0; // start at beginning of array
		} else if ( _type == 1) { // MT
			_cnt = 28; // called with at least 28 entries
			_startIdx = _endIdx - _cnt;
		}  else if (_type == 2) { // ST
			_cnt = mSortedRes.size() > 7 ? 7 : mSortedRes.size()-1; // called with at least 3 entries. Need -1 for case when less samples than 7
			_startIdx = _endIdx - _cnt; 
		}
		
		Sys.println("Regression line range: _startIdx="+_startIdx+" _endIdx="+_endIdx+" with type="+_type+" count of "+_cnt+"+1 entries");

		// check for how many non zero entires in range being used
		var _tmp = 0;
		for (var i=_startIdx; i <= _endIdx; i++) {
			// check how many valid entries
			// index starts at 0 but want x to start at 1 otherwise lose a value as * 0
			var x = i + 1;
			var _val = mSortedRes[i];
			if ( _val != 0.0) { // only use non zero values
			 	_tmp++; 
			 	_sumY += _val;
			 	_sumX += x;
			 	_sumXY += _val * x;
			 	_sumX2 += x * x;
			 	_sumY2 += _val * _val;			 	
			}
		}

		if ( _tmp < 3) {
			// no fit going to be possible for any period!!
			return [mB, mM, mR];
		}

		// now get down to meat of linear regression!!!
		_NumSamp = _tmp;		
		
		// check for values that will give 0 divisor!!!		
		// m (slope) = (n*(sum xy) - (sum x)*(sum y)) / (n*(sum x^2) - (sum x)^2)
		var _div = ( _NumSamp * _sumX2 - _sumX * _sumX);
		if (_div != 0.0 ) {
			mM = ( _NumSamp * _sumXY - _sumX*_sumY) / _div;
		} // defaults to initial value of zero
		
		// b (intercept) = (sum y - m * sum x) / n. N will always be > 0
		mB = ( _sumY - mM * _sumX) / _NumSamp;
		
		// calculate fit
		_div = (Math.sqrt( _NumSamp * _sumX2 - _sumX * _sumX) * Math.sqrt( _NumSamp * _sumY2  - _sumY*_sumY ));
		if (_div != 0.0 ) {
			mR = ( _NumSamp * _sumXY - _sumX * _sumY) / _div;
		}	
		
		Sys.println(" _sumY= "+_sumY+" _sumX="+_sumX+" _sumXY="+_sumXY+" _sumX^2="+_sumX2+" _sumY2="+_sumY2+" _NumSamp="+_NumSamp); 
	
		return [mB, mM, mR];
	}
    
    function generateResults( _stats) {
    	Sys.println("Generate results");
    	var mHRVExpected = new [2];
    	var mHRVFound = new [3];
    	var mTrend = [0, false];
    	var mAdvice = "Rest";
    	mLowAge = 0.0;
		mHighAge = 0.0;	
		mSortedRes = null;
		var mActualHRV = _stats[0];
		
		// minD, MaxD, minHRV, maxHRV, count
		var mScan = new [5];
    	
    	mHRVExpected = getHRVAgeRange();
    	
    	// keep values for arc tags
    	mLowAge = mHRVExpected[0];
		mHighAge = mHRVExpected[1];
    	    	
    	var startMoment = Time.now();
		var utcStart = startMoment.value() + Sys.getClockTime().timeZoneOffset;
		
		// prepare results and save current data
    	// loads up resGL;
    	// for test purposes return timestamp of test data or incoming value!    	
    	// returns real utcStart ie one passed or in test code the first date in the test data
    	//utcStart = prepareSaveResGL( utcStart, _stats); 
    	
    	mScan = prepareSaveResGL( utcStart, _stats); 
    	utcStart = mScan[1]; // oldest date
    	var mMinUtc = mScan[0];
    	// min, max, count
    	mHRVFound[0] = mScan[2];
    	mHRVFound[1] = mScan[3];
    	mHRVFound[2] = mScan[4];
    	  	
    	// min, max and number
    	//mHRVFound = getHRVActualRange();  	
    	 	
    	// calculate stats on all results 
    	// Churn through results - results being old dealt with in glance. Results are for every test ... not once per day    	
    	// index is pointing at one past last entry
    	// lets work out averages
		var mAvgHRV = new [2];
		
		// return [ monthly, weekly] average of HRV data where it exists
		mAvgHRV = calcHRVAvg( utcStart);
		
		// now are arc is split 20% below age, 60% age split in two and 20% over
    	// if outside of this range then threshold to that and might also need to comment on result screen
     	//%  Position in age range (under, low, high, over) : split display 20%, 60%, 20%    	
     	var mPosInRange = [0, 0, 0];
     	//are we in range expected?
     	//var mActualHRV = $.mSampleProc.mRMSSD; // now parameter
     	mPosInRange[0] = calcPosition (mActualHRV, mHRVExpected, mHRVFound);     	 
     	// weekly
   		mPosInRange[1] = calcPosition (mAvgHRV[1], mHRVExpected, mHRVFound);
		// monthly
		mPosInRange[2] = calcPosition (mAvgHRV[0], mHRVExpected, mHRVFound);
		
    	// note if not enough data then we need to change output    	
		mTrend = calcTrends( utcStart, mActualHRV, mMinUtc);
    	
    	if (mTrend[1] == false ) {
    		// no data to make trend
    		mAdvice ="measure!";
    	} else if (mTrend[0] < 0) {
    		mAdvice = "Rest";
    	} else if (mTrend[0] > 0 ) {
    		mAdvice = "Ready!";
    	} else {
    		mAdvice = "No change";
    	}	
    	
    	Sys.println("Position in range set ="+mPosInRange+" with trend "+mTrend+" and advice="+mAdvice);
    	
    	// Message to glance structure
		//	[0] Avg HRV 1 month = 0 if no data... do we have to work out which days data falls on?
		//	[1] Avg HRV 1 week = 0 if no data
		//	[2] Latest HRV
		//	[3] Valid trend?
		//	[4] Trend and value +/-X. can we scale this and fit in range??
		//	[5] "Comment" string
		//	[6] current %  Position in age range (under, (low, high), over) : split display 20%, 60%, 20%
		//	[7] last update time utc		
		//  [8] Position for weekly dial
		//  [9] Position for monthly dial
		// [10] Low age HRV
		// [11] High age HRV
    	  	
    	$.glanceData = [mAvgHRV[0], mAvgHRV[1], mActualHRV, mTrend[1], mTrend[0], mAdvice, mPosInRange[0], utcStart, mPosInRange[1], mPosInRange[2], mLowAge, mHighAge ]; 
    	
    	Sys.println("Glance results saved at : "+utcStart+" with Glance data ="+$.glanceData);
    	  	
    	// create a package for glance and save in store   
 		$.saveGResultsToStore();   
 		resGL = null;   
 		
 		return mPosInRange[0]*100;  // make available for circle colour in % not fraction
    }

	function resetResGLArray() {
		resGL = null;
		resGL = new [NUM_RESGL_ENTRIES * GL_SET_SIZE];
		Sys.println("resetResGLArray() array created");

		for(var i = 0; i < (NUM_RESGL_ENTRIES * GL_SET_SIZE); i++) {
			resGL[i] = 0;
		}
		resGLIndex = 0;	
	}
	
	function resetResGL( _discardArray) {
		// should only be called from settings RESET menu
		resetResGLArray();
		
		// force history to empty
		storeResGL();
		
		if (_discardArray) { 
			resGL = null;
		}
	}

// this function does the scan of array AND moves data over to ResGL
// takes array read in, current date and current HRV
	function f_MinMax ( _mCheck, _cD, _cH) {
        var minH = 100.0;
    	var maxH = 0.0;	
    	var cntH = 0;
    	var minD = _cD;
    	var maxD = 0;	
    	
    	Sys.println("ENTER: f_minmax: "+_cD+" HRV: "+_cH);
    		
		for (var i=0; i < _mCheck.size(); i=i+2) {
			resGL[i] = _mCheck[i];
			resGL[i+1] = _mCheck[i+1];
			
			// now find min and max of date and HRV
			var _val = resGL[i];
			if ( _val != 0) { 
				if (_val > maxD ) { maxD = _val;}
				if (_val < minD ) { minD = _val; Sys.println("MinD set on i of:"+i);}
				
				_val = resGL[i+1];
				cntH++;
				if (_val > maxH ) { maxH = _val;}
				if (_val < minH ) { minH = _val;}						
			}			
		}
    	
    	Sys.println("Min/max D/H found:"+minD+"/"+maxD+", HRV "+minH+"/"+maxH);
    	
    	// include current data in comparison
    	if ( _cD > maxD) { maxD = _cD;}
    	if ( _cD < minD) { minD = _cD;}
    	if ( _cH > maxH) { maxH = _cH;}
    	if ( _cH < minH) { minH = _cH;}
     	
     	Sys.println("HRV actual range is "+minH+" to "+maxH);
    	
    	//if (minH == 0 && maxH == 0) {
    	//	// array empty but date possibly set
    	//	return [0.0, 100.0, cntH];
    	//} else { 
    	//	return [min, max, count];
    	//} 	
		
		// returns an array containing min and max HRV found with a count(with valid dates) and earliest and latest dates
		return [minD, maxD, minH, maxH, cntH];
	}
	
// this function scans the loaded array for min/max HRV and dates and counts non-zero date entries
	function retrieveResGL( utcStart, _stats) {
		var mCheck;
		// res is minD, MaxD, minHRV, maxHRV, count
		var res = [ utcStart, utcStart, 0.0, 100.0, 0];
		
		resetResGLArray();
		
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			try {
				mCheck = Storage.getValue("resultsArrayW");
				resGLIndex = Storage.getValue("resultIndexW");
				// occasionally sim/dev gets varaibles out of sync
				if (resGLIndex == null) { resGLIndex = 0;}
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResGL: no results array");
				resGLIndex = 0;
				// Rather than return go to save array
				mCheck = null;
				//return false;
			}				
			
			if (mCheck != null) { 
				Sys.println("retrieveResGL: mCheck="+mCheck+"\n with resGL:"+resGL);
				Sys.println("size mCheck="+mCheck.size()+" resGL="+resGL.size());
				
				// pass array, today and current HRV
				res = f_MinMax ( mCheck, utcStart, _stats[0]);
				
				mCheck = null;
			} else {
				// have a null if not saved 1st time
				Sys.println("No results array in store");
				//resetResGLArray();
				storeResGL();
			}
			//return true;			
		} else {
			Sys.println("NO STORAGE");
			//return false;
		}
		
		// check current date and 
		
		// removed boolean on return as always forced an array to exist
		Sys.println("retrieveResGL() finished. Rtn:"+res);
		return res;	     
	
	}
	
	function storeResGL() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArrayW", resGL);
			Storage.setValue("resultIndexW", resGLIndex);
		} 
	}

(:TestVersionGL)
	// pull in JSON data instead
	function prepareSaveResGL( utcStart, _stats) {
		var _res = new [5];	
		// create arrays, store and keep
		resetResGL( false);
		
		var dateList = Ui.loadResource(Rez.JsonData.jsonTestDates); 
		var latestDate = dateList[0]; // force to earliest
		
		var hrvList = Ui.loadResource(TESTSET); 
		var j = 0;
		for(var i=0; i < dateList.size(); i++) {		
			resGL[j+1] = hrvList[i];
			
			// check date is not zero
			if ( hrvList[i] != 0 ) {
				resGL[j] = dateList[i];			
				if (resGL[j] > latestDate ) { latestDate = resGL[j];}
			} else {
				// force date to zero
				resGL[j] = 0; // no data for this date
			}
			
			//resGL[j+1] = hrvList[i]; //done already at start of loop
			//resGL[j+2] = 0.0;
			//resGL[j+3] = 0.0;	
			j += GL_SET_SIZE;		
			
			// NEED TO EDIT IF DATA SIZE CHANGES
		}
		
		// pass array, today and current HRV
		_res = f_MinMax ( resGL, utcStart, _stats[0]);
		
		// We want to set date to last valid HRV entry
		_res[1] = latestDate;
				
		Sys.println("dateList size = "+dateList.size()+" with latest date of "+latestDate);
		Sys.println("Dates loaded="+dateList+"\n and HRV="+hrvList);
		Sys.println("resGL array created ="+resGL);
		Sys.println("passing back res:"+_res);
		
		dateList = null;
		hrvList = null; 
		// leave index at 0 as doesn't matter	
		storeResGL();
		//return latestDate;
		
		return _res;	
	}

	// function to read in results array 
	// update current values and write back to store 	
(:notTestVersionGL)
	function prepareSaveResGL( utcStart, _stats) {
		// need to load results array fill and then save
		// assume pointer still valid	
		var _res = new [5];	
		_res = retrieveResGL( utcStart, _stats); 
		
		//Sys.println("ResGL restored: index:"+resGLIndex+" resGL="+resGL);

    	// seconds in day = 86400
    	var index;
		
		// we write every entry!
		index = resGLIndex * GL_SET_SIZE;	
		
		Sys.println("index = "+index+"ResGL: "+utcStart+","+_stats);
			
		resGL[index + TIME_STAMP_INDEX] = utcStart;		
		resGL[index + RMSSD_INDEX] = _stats[0];
		//resGL[index + ECT_INDEX] = _stats[1];
		//resGL[index + NN50_INDEX] = _stats[2];
  		
   		Sys.println("storing resGL ... ="+resGL);
   		
		// written a new entry so move pointer
   		// increment write pointer to circular buffer
   		resGLIndex = (resGLIndex + 1 ) % NUM_RESGL_ENTRIES;
   		//Sys.println("pointer now "+resGLIndex);   
   				
    	// better write results to memory!!
    	storeResGL(); 
 	
    	// keep time unchanged
    	// return utcStart;
    	return _res;
    	
	} // end prepareResults 

}