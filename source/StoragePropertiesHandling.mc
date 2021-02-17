using Toybox.System as Sys;
using Toybox.Application.Properties; // as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

// STORAGE came in with CIQ 2.4 - could cut down code by removing all pre CIQ2.4 code

// Results memory locations. (X) <> (X + 29)

module HRVStorageHandler {

	//var gg; //$._ mApp to make global more local!

	// setup storage functions	
   // function initialize(_ref) {
    //	// create buffers here? use function so external can call parts   
    //	gg = _ref; //App.getApp(); //$.;	
    //}

	// message from Garmin that settings have been changed on mobile - called from main app
	function onSettingsChangedStore() {
		// should probably stop any test and reload settings
		//0.4.04 read changed properties
		readProperties();
		// caller will do checks on changes
	}

// date settings from Garmin are in UTC so use Gregorian.utcInfo() when working with these in place of Gregorian.info()

(:storageMethod)
	function fresetPropertiesStorage() {
		// use Storage.get/setValue("", value) for storage or properties not used in settings			
		Properties.setValue("pAuxHRAntID", 0);
		//Storage.setValue("firstLoadEver", true);
		Properties.setValue("pFitWriteEnabled", false);
		//Properties.setValue("pSensorSelect", SENSOR_INTERNAL);
		// Auto scale if true
		Properties.setValue("pIIScale", false);
		Properties.setValue("soundSet", true);
		Properties.setValue("vibeSet", false);
		Properties.setValue("testTypeSet", TYPE_TIMER);
		Properties.setValue("timerTimeSet", 300);
		// 0.4.2
		//Properties.setValue("MaxTimerTimeSet", 300);
		Properties.setValue("ManualTimeSet", 300);
		Properties.setValue("bgColSet", 3);
		Properties.setValue("lblColSet", 10);
		Properties.setValue("txtColSet", 9);
		Properties.setValue("Label1ColSet", 10);
		Properties.setValue("Label3ColSet", 12);
		Properties.setValue("Label2ColSet", 6);		
		
		//0.4.3
		Properties.setValue("pHistLabel1", 1);	
		Properties.setValue("pHistLabel2", 6);	
		Properties.setValue("pHistLabel3", 7);	
		
		//0.4.6
		Properties.setValue("pNumberBeatsGraph", 10);	
		Properties.setValue("pLongThresholdIndex", 0.15); // nominal
		Properties.setValue("pShortThresholdIndex", 0.15); // nominal	
		
		//0.6.0
		Properties.setValue("pLogScale", 50.0);
		
		//Properties.setValue("pPaypalRef", "https://www.paypal.com/paypalme/hrvapp");
	}

(:preCIQ24)	
	function fresetPropertiesPreCIQ24() {		
		
	
	}
	
	// This should be factory default settings and should write values back to store
	// ideally these should align with properties defined in XML
	function resetSettings() {
	
		if (Toybox.Application has :Storage) {		
			fresetPropertiesStorage();				
		} else {		
			fresetPropertiesPreCIQ24();	
		}	
		// now load up variables
		readProperties();
		mapIndexToColours();
	}

	function readProperties() {	
		if (Toybox.Application has :Storage) {
			_CallReadPropStorage();
		} else {
			_CallReadPropProperty();
		}
	}	
	
	function saveProperties() {	
		Sys.println("saveProperties() called");
		
		if (Toybox.Application has :Storage) {
			_CallSavePropStorage();
		} else {
			_CallSavePropProperty();
		}
	}
	
	function PrintStats() {
		//0.4.3 - Need to check calculations are correct - possible bug
		var str;
		
		str = "Dumping stats:\n";
		str = str+"avgPulse, mRMSSD, mLnRMSSD, mSDNN, mSDSD, mNN50, mpNN50, mNN20, mpNN20\n";
		str = str+$.mSampleProc.avgPulse+","+$.mSampleProc.mRMSSD+","+$.mSampleProc.mLnRMSSD+","+
			$.mSampleProc.mSDNN+","+$.mSampleProc.mSDSD+","+$.mSampleProc.mNN50+","+
			$.mSampleProc.mpNN50+","+$.mSampleProc.mNN20+","+$.mSampleProc.mpNN20;
	
		Sys.println(str);
	}
	
	function saveStatsToStore() {
		Sys.println("saveStatsToStore() called");	
		var stats = new [11];
		stats[0] = $.mSampleProc.avgPulse;
		stats[1] = $.mSampleProc.mRMSSD;
		stats[2] = $.mSampleProc.mLnRMSSD;
		stats[3] = $.mSampleProc.mSDNN;
		stats[4] = $.mSampleProc.mSDSD; 
		stats[5] = $.mSampleProc.mNN50;
		stats[6] = $.mSampleProc.mpNN50; 
		stats[7] = $.mSampleProc.mNN20;
		stats[8] = $.mSampleProc.mpNN20;
		stats[9] = $.mSampleProc.minDiffFound;
		stats[10] = $.mSampleProc.maxDiffFound;
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("runstats", stats);				
		} else {
			$.setProperty("runstats", stats);			
		}			
	}
	
	function loadStatsFromStore() {
		Sys.println("loadStatsFromStore() called");	
		var stats = new [11];
		
		try {
			if (Toybox.Application has :Storage) {	
				stats = Storage.getValue("runstats");		
			} else {
				stats = $.getProperty("runstats");			
			}
		} catch (ex) {
			// storage error - most likely not written
			Sys.println("StoragePropertiesHandling: ERROR loadStatsFromStore");
			return false;
		}
		finally {
			if (stats == null) {
				// not been written yet
				return false;
			} else {
				$.mSampleProc.avgPulse = stats[0];
				$.mSampleProc.mRMSSD = stats[1];
				$.mSampleProc.mLnRMSSD = stats[2];
				$.mSampleProc.mSDNN = stats[3];
				$.mSampleProc.mSDSD = stats[4]; 
				$.mSampleProc.mNN50 = stats[5];
				$.mSampleProc.mpNN50 = stats[6]; 
				$.mSampleProc.mNN20 = stats[7];
				$.mSampleProc.mpNN20 = stats[8];	
				$.mSampleProc.minDiffFound = stats[9];
				$.mSampleProc.maxDiffFound = stats[10];			
				return true;
			}
		}	
	
	}
	
	function saveIntervalsToStore() {
		Sys.println("saveIntervalsToStore() called");
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("IntervalStoreData", $.mIntervalSampleBuffer);	
			Storage.setValue("IntervalStoreMin", $.mSampleProc.minIntervalFound);	
			Storage.setValue("IntervalStoreMax", $.mSampleProc.maxIntervalFound);	
			Storage.setValue("IntervalStoreIndex", $.mSampleProc.getNumberOfSamples());				
		} else {
Sys.println("NO CIQ 2.4 support");			
		}	
	}
	
	function loadIntervalsFromStore() {
		Sys.println("loadIntervalsFromStore() called");
		
		try {
			if (Toybox.Application has :Storage) {				
				$.mIntervalSampleBuffer = Storage.getValue("IntervalStoreData");	
				$.mSampleProc.minIntervalFound = Storage.getValue("IntervalStoreMin");	
				$.mSampleProc.maxIntervalFound = Storage.getValue("IntervalStoreMax");	
				$.mSampleProc.setNumberOfSamples( Storage.getValue("IntervalStoreIndex"));	
			} else {
		
			}
		} catch (ex) {
			// storage error - most likely not written
			Sys.println("StoragePropertiesHandling: ERROR loadIntervalsFromStore");
			return false;
		}
		finally {
			// any null entries means we haven't written anything yet
			if ($.mIntervalSampleBuffer == null) {
				// we have now written over the sample buffer
				// reinitialise the sample buffer!!
				// we should recreate the class but this runs risk of overflowing memory available during heap clear up
				//$.mSampleProc = new SampleProcessing();
				$.mSampleProc.initialize();			
				return false;
			} else {
				return true;
			}
		}
	}

(:preCIQ24)	
	function _CallReadPropProperty() {	
		// assumes all these values exist
		//$.timestampSet = $.getProperty("timestampSet");
		$.appNameSet = Ui.loadResource(Rez.Strings.AppName);
		$.mFitWriteEnabled = $.getProperty("pFitWriteEnabled");
		//$.mSensorTypeExt = $.getProperty("pSensorSelect");	
		$.mBoolScaleII = $.getProperty("pIIScale");
		$.soundSet = $.getProperty("soundSet");
		$.vibeSet = $.getProperty("vibeSet");
		$.testTypeSet = $.getProperty("testTypeSet");
		$.timerTimeSet = $.getProperty("timerTimeSet").toNumber();
		// 0.4.2
		$.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;		
		//$.mMaxTimerTimeSet = $.getProperty("MaxTimerTimeSet").toNumber();
		$.mManualTimeSet = $.getProperty("ManualTimeSet").toNumber();	      
		// ColSet are index into colour map
		$.bgColSet = $.getProperty("bgColSet").toNumber();
		$.lblColSet = $.getProperty("lblColSet").toNumber();
		$.txtColSet = $.getProperty("txtColSet").toNumber();
		$.Label1ColSet = $.getProperty("Label1ColSet").toNumber();
		$.Label3ColSet = $.getProperty("Label3ColSet").toNumber();
		$.Label2ColSet = $.getProperty("Label2ColSet").toNumber();
		
		//0.4.3
		$.mHistoryLabel1 = $.getProperty("pHistLabel1").toNumber();	
		$.mHistoryLabel2 = $.getProperty("pHistLabel2").toNumber();	
		$.mHistoryLabel3 = $.getProperty("pHistLabel3").toNumber();	
		
		mapIndexToColours();
		
		// no history selected. binary flags as bits
		// set default selection
		// Used in menu creation
		// Note array 0 entry is time stamp but use for null case
		//$.mHistorySelectFlags = (1 << $.mHistoryLabel1);
		//$.mHistorySelectFlags |= (1 << $.mHistoryLabel2);
		//$.mHistorySelectFlags |= (1 << $.mHistoryLabel3);	
		
		//0.4.6
		$.mNumberBeatsGraph = $.getProperty("pNumberBeatsGraph").toNumber();	
		
		//var index = $.getProperty("pLongThresholdIndex").toNumber();
		//var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
        //var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
		//$.vUpperThresholdSet = mLongThresholdMap[index];
		//index = $.getProperty("pShortThresholdIndex").toNumber();	
		//$.vLowerThresholdSet = mShortThresholdMap[index];	
		$.vUpperThresholdSet = $.getProperty("pLongThresholdIndex").toFloat();
		$.vLowerThresholdSet = $.getProperty("pShortThresholdIndex").toFloat();
		
		//0.6.0
		$.mLogScale = $.getProperty("pLogScale").toFloat();
	}

(:storageMethod)	
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		// On very first use of app don't read in properties!
		//try {
			//$.timestampSet = Storage.getValue("timestampSet");
			$.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			$.mFitWriteEnabled = Properties.getValue("pFitWriteEnabled");
			//$.mSensorTypeExt = Properties.getValue("pSensorSelect");
			$.mBoolScaleII = Properties.getValue("pIIScale");
			$.soundSet = Properties.getValue("soundSet");
			$.vibeSet = Properties.getValue("vibeSet");
			$.testTypeSet = Properties.getValue("testTypeSet");
			$.timerTimeSet = Properties.getValue("timerTimeSet").toNumber();
			// 0.4.2
			$.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;	
			//$.mMaxTimerTimeSet = Properties.getValue("MaxTimerTimeSet").toNumber();
			$.mManualTimeSet = Properties.getValue("ManualTimeSet").toNumber();
	      
			// ColSet are index into colour map
			$.bgColSet = Properties.getValue("bgColSet").toNumber();
			$.lblColSet = Properties.getValue("lblColSet").toNumber();
			$.txtColSet = Properties.getValue("txtColSet").toNumber();
			$.Label1ColSet = Properties.getValue("Label1ColSet").toNumber();
			$.Label3ColSet = Properties.getValue("Label3ColSet").toNumber();
			$.Label2ColSet = Properties.getValue("Label2ColSet").toNumber();	
			
			//0.4.3
			$.mHistoryLabel1 = Properties.getValue("pHistLabel1").toNumber();	
			$.mHistoryLabel2 = Properties.getValue("pHistLabel2").toNumber();	
			$.mHistoryLabel3 = Properties.getValue("pHistLabel3").toNumber();	
			
			mapIndexToColours();
			
		//} catch (e) {
		//	Sys.println(e.getErrorMessage() );
		//}
			$.mNumberBeatsGraph = Properties.getValue("pNumberBeatsGraph").toNumber();	
			
			//var index = Properties.getValue("pLongThresholdIndex").toNumber();
			//var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
            //var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
			//$.vUpperThresholdSet = mLongThresholdMap[index];
			//index = Properties.getValue("pShortThresholdIndex").toNumber();	
			//$.vLowerThresholdSet = mShortThresholdMap[index];	
		$.vUpperThresholdSet = Properties.getValue("pLongThresholdIndex").toFloat();
		$.vLowerThresholdSet = Properties.getValue("pShortThresholdIndex").toFloat();
		
		//0.6.0
		$.mLogScale = Properties.getValue("pLogScale").toFloat();
	}

(:discard)	
	function fFindThresholdIndex() {
		var long = 0;
		var short = 0;
		
		var index;
		var mThreshold;
		var value;
		// need to reverse lookup current threshold string from value then index in array
		mThreshold = $.vUpperThresholdSet; 
		
		var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
		// get actual thresholds
		var i = 0;
		do {
			index = i;
			value = mLongThresholdMap[i];	
			i++;	
		} while (( i < mLongThresholdMap.size() ) && (value != mThreshold));
		
		Sys.println("Upper threshold property save : "+index);	
		long = index;
		
		mThreshold = $.vLowerThresholdSet; 
		var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);	
		// get actual thresholds
		i = 0;
		do {
			index = i;
			value = mShortThresholdMap[i];	
			i++;	
		} while (( i < mShortThresholdMap.size() ) && (value != mThreshold));
		
		Sys.println("Lower threshold property save : "+index);			
		short = index;
	
		return [long, short];
	}

(:storageMethod)	
	function _CallSavePropStorage() {
		//Storage.setValue("timestampSet", $.timestampSet);
		Properties.setValue("pFitWriteEnabled", $.mFitWriteEnabled);
		//Properties.setValue("pSensorSelect", $.mSensorTypeExt);
		
		// user changable
		Properties.setValue("pIIScale", $.mBoolScaleII);
		Properties.setValue("soundSet", $.soundSet);
		Properties.setValue("vibeSet", $.vibeSet);
		Properties.setValue("testTypeSet", $.testTypeSet);
		Properties.setValue("timerTimeSet", $.timerTimeSet);
		// 0.4.2
		//Properties.setValue("MaxTimerTimeSet", $.mMaxTimerTimeSet);
		Properties.setValue("ManualTimeSet", $.mManualTimeSet);
      
		// ColSet are index into colour map
		Properties.setValue("bgColSet", $.bgColSet);
		Properties.setValue("lblColSet", $.lblColSet);
		Properties.setValue("txtColSet", $.txtColSet);
		Properties.setValue("Label1ColSet", $.Label1ColSet);
		Properties.setValue("Label3ColSet", $.Label3ColSet);
		Properties.setValue("Label2ColSet", $.Label2ColSet);	
		
		//0.4.3
		Properties.setValue("pHistLabel1", $.mHistoryLabel1);
		Properties.setValue("pHistLabel2", $.mHistoryLabel2);
		Properties.setValue("pHistLabel3", $.mHistoryLabel3);
		
		//0.4.6
		Properties.setValue("pNumberBeatsGraph", $.mNumberBeatsGraph);
		
		
		//0.4.7
		// move code to function
		//var res = new [2];
		//res = fFindThresholdIndex();
		
		//Properties.setValue("pLongThresholdIndex", res[0]);		
		//Properties.setValue("pShortThresholdIndex", res[1]);
		
		Properties.setValue("pLongThresholdIndex", $.vUpperThresholdSet );		
		Properties.setValue("pShortThresholdIndex", $.vLowerThresholdSet);
		
		//0.6.0
		Properties.setValue("pLogScale", $.mLogScale);
			
	}

(:preCIQ24)	
	function _CallSavePropProperty() {
	}

(:oldResults)
	function resetResults() {
		// should only be called from settings - also called onStart() but followed by load
		$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		Sys.println("resetResults() array created");

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$.results[i] = 0;
		}
		// this will be overridden if we load results
		$.resultsIndex = 0;
	}
	
(:newResults)
	function resetResults() {
		// should only be called from settings - also called onStart() but followed by load
		$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		Sys.println("resetResults() array created");

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$.results[i] = 0;
		}
		$.resultsIndex = 0;
		
		// force history to empty
		storeResults();
		 
		$.results = null;
	}

(:preCIQ24)
	function retrieveResultsProp() {
		var tmp = $.getProperty("resultIndex");
		if (tmp == null) { tmp = 0;}
		$.resultsIndex = tmp;
		
		for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var result = $.getProperty(RESULTS + i);
			var ii = i * DATA_SET_SIZE;
			if(null != result) {
				$.results[ii + 0] = result[0];
				$.results[ii + 1] = result[1];
				$.results[ii + 2] = result[2];
				$.results[ii + 3] = result[3];
				$.results[ii + 4] = result[4];
				$.results[ii + 5] = result[5];
				$.results[ii + 6] = result[6];
				$.results[ii + 7] = result[7];
				$.results[ii + 8] = result[8];
				$.results[ii + 9] = result[9];
				$.results[ii + 10] = result[10];
				$.results[ii + 11] = result[11];
				$.results[ii + 12] = result[12];
				$.results[ii + 13] = result[13];
			}
		}	
	}

// loading directly into results array and only with storage
//(:discard)	
	function retrieveResults() {
		
Sys.println("retrieveResults memory used, free, total: "+Sys.getSystemStats().usedMemory.toString()+
			", "+Sys.getSystemStats().freeMemory.toString()+
			", "+Sys.getSystemStats().totalMemory.toString()			
			);	
		$.results = null;		
		try {
			$.results = Storage.getValue("resultsArray");
			$.resultsIndex = Storage.getValue("resultIndex");
		}
		catch (ex) {
			Sys.println("ERROR: retrieveResults: no results array");
			$.resultsIndex = 0;
			return false;
		}				
		
		// have a null if not saved 1st time
		if ($.resultsIndex == null) {$.resultsIndex = 0;}
		
		Sys.println("retrieveResults() finished");		
		return true;
	}

// Creating a double buffer of results so try just loading directly
(:discard)	
	function retrieveResults() {
		var mCheck;
		// currently references a results array in HRVApp
		
Sys.println("retrieveResults memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	
		
		if (Toybox.Application has :Storage) {
			try {
				mCheck = Storage.getValue("resultsArray");
				$.resultsIndex = Storage.getValue("resultIndex");
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResults: no results array");
				$.resultsIndex = 0;
				return false;
			}				
			
			if (mCheck != null) { $.results = mCheck; } 
			// have a null if not saved 1st time
			if ($.resultsIndex == null) {$.resultsIndex = 0;}
			return true;			
		} else {
			retrieveResultsProp();	
		}
		Sys.println("restrieveResults() finished");
		return true;
	}

(:discard)	
	function retrieveResults( buffer) {
		var mCheck;
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			try {
				mCheck = Storage.getValue("resultsArray");
				$.resultsIndex = Storage.getValue("resultIndex");
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResults: no results array");
				$.resultsIndex = 0;
				return false;
			}				
			
			if (mCheck != null) { buffer = mCheck; } 
			
			Sys.println("retrievefunc:\n mCheck ="+mCheck+"\nbuffer ="+buffer);
			// have a null if not saved 1st time
			if ($.resultsIndex == null) {$.resultsIndex = 0;}
			return true;			
		} else {
			retrieveResultsProp();	
		}
		Sys.println("restrieveResults() finished");
		return true;
	}

(:preCIQ24)
	function storeResultsProp() {
		$.setProperty("resultIndex", $.resultsIndex);
    	for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var ii = i * DATA_SET_SIZE;
			var result = $.getProperty(RESULTS + i);
			if(null == result || $.results[ii] != result[0]) {
				$.setProperty(RESULTS + i, [
					$.results[ii + 0],
					$.results[ii + 1],
					$.results[ii + 2],
					$.results[ii + 3],
					$.results[ii + 4],
					$.results[ii + 5],
					$.results[ii + 6],
					$.results[ii + 7],
					$.results[ii + 8],
					$.results[ii + 9],
					$.results[ii + 10],
					$.results[ii + 11],						
					$.results[ii + 12],
					$.results[ii + 13]						
					]);
			}
		}	
	}
		
	function storeResults() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArray", $.results);
			Storage.setValue("resultIndex", $.resultsIndex);
		} else {
			storeResultsProp();
		}
	}

(:newResults)
	// function to read in results array 
	// update current day values and write back to store 	
	function prepareSaveResults( utcStart) {
		// need to load results array fill and then save
		// assume pointer still valid
		
		// remove for 0.6.3
		//$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		
		// if retrieve returns null i eno storage then we will have all 0's
		//for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
		//	$.results[i] = 0;
		//}
		
		// this will be overridden if we load results
		$.resultsIndex = 0;
		
		retrieveResults(); 
		if ($.results == null) {
			$.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
			
			// if retrieve returns null ie no storage then we will have all 0's
			for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
				$.results[i] = 0;
			}
		}

    	// seconds in day = 86400
    	// make whole number of days (still seconds since UNIX epoch)
    	// This ignores possiblity of 32 bit integar of time wrapping on testday and epoch
    	// should change to use time functions available
		var testDayutc = utcStart - (utcStart % 86400);
		
		// next slot in cycle, can overwrite multiple times in a day and keep last ones
		// Check whether we are creating another set of results on the same day by inspecting previous entry
		var previousEntry = ($.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
		var previousIndex = previousEntry * DATA_SET_SIZE;
		var currentIndex = $.resultsIndex * DATA_SET_SIZE;	
		
		var x = $.results[previousIndex + TIME_STAMP_INDEX];
		// convery to day units
		var previousSavedutc = 	x - (x % 86400);
		x = $.results[currentIndex + TIME_STAMP_INDEX];
		var currentSavedutc = x - (x % 86400);
		var index;
		
		if (testDayutc == previousSavedutc) {
			// overwrite current days entry
			index = previousIndex;
		}
		else {
			index = currentIndex;			
			// written a new entry so move pointer
   			// increment write pointer to circular buffer
   			$.resultsIndex = ($.resultsIndex + 1 ) % NUM_RESULT_ENTRIES;
   			Sys.println("SaveTest: pointer now "+$.resultsIndex);
   		}
			
		Sys.println("utcStart, index, testdayutc, previous entry utc = "+utcStart+", "+index+", "+testDayutc+", "+previousSavedutc);

		$.results[index + TIME_STAMP_INDEX] = utcStart;
		$.results[index + AVG_PULSE_INDEX] = $.mSampleProc.avgPulse;
		$.results[index + MIN_II_INDEX] = $.mSampleProc.minIntervalFound;
		$.results[index + MAX_II_INDEX] = $.mSampleProc.maxIntervalFound;		
		$.results[index + MAX_DIFF_INDEX] = $.mSampleProc.minDiffFound;
		$.results[index + MAX_DIFF_INDEX] = $.mSampleProc.maxDiffFound;				
		$.results[index + RMSSD_INDEX] = $.mSampleProc.mRMSSD;
		$.results[index + LNRMSSD_INDEX] = $.mSampleProc.mLnRMSSD;

		$.results[index + SDNN_INDEX] = $.mSampleProc.mSDNN;
		$.results[index + SDSD_INDEX] = $.mSampleProc.mSDSD; 
		$.results[index + NN50_INDEX] = $.mSampleProc.mNN50;
		$.results[index + PNN50_INDEX] = $.mSampleProc.mpNN50; 
		$.results[index + NN20_INDEX] = $.mSampleProc.mNN20;
		$.results[index + PNN20_INDEX] = $.mSampleProc.mpNN20;
   		
   		Sys.println("storing results ... ="+$.results);
   		
    	// better write results to memory!!
    	storeResults(); 
    	// discard results buffer as large
    	$.results = null;
    	
    	// save intervals as well so we can reload and display
    	saveIntervalsToStore();
    	saveStatsToStore();   	
    	
	} // end prepareResults 

	function saveStrings(_type) {
		var mString;
		var base;
		var mSp;
		var separator = ",";
		var mNumEntries = $.mSampleProc.getNumberOfSamples();

		if (mNumEntries <= 0) { return;}
			
		mString = ( _type == 0 ? "II:," : "Flags:,");

		for (var i=0; i < mNumEntries; i++) {
				mSp = $.mIntervalSampleBuffer[i];
				mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
				mString += mSp.toString()+separator;				
		}
	
		// write to storage
		if (_type == 0) { // interval string
			Storage.setValue("SavedIntervalArray", mString);
		} else {
			Storage.setValue("SavedFlagArray", mString);				
		}
		mString = "";			
	}

	
	// save intervals and flags as strings to storage to see if we can find them!!
	// on close of app so data doesn't matter
	function saveIntervalStrings() {
		
		Sys.println("Storing intervals and flags");
		
		// save memory by removing code lines
		// type 0 = II, 1 = flags
		saveStrings(0);		
		saveStrings(1);	
	}
	
}

 