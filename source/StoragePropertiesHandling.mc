using Toybox.System as Sys;
using Toybox.Application.Properties; // as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

// STORAGE came in with CIQ 2.4 - could cut down code by removing all pre CIQ2.4 code

// Results memory locations. (X) <> (X + 29)

class HRVStorageHandler {

	var gg; //$._ mApp to make global more local!

	// setup storage functions	
    function initialize() {
    	// create buffers here? use function so external can call parts   
    	gg = $._mApp;	
    }

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
		gg.Properties.setValue("pAuxHRAntID", 0);
		Storage.setValue("firstLoadEver", true);
		gg.Properties.setValue("pFitWriteEnabled", false);
		gg.Properties.setValue("pSensorSelect", SENSOR_INTERNAL);
		// Auto scale if true
		gg.Properties.setValue("pIIScale", false);
		gg.Properties.setValue("soundSet", true);
		gg.Properties.setValue("vibeSet", false);
		gg.Properties.setValue("testTypeSet", TYPE_TIMER);
		gg.Properties.setValue("timerTimeSet", 300);
		// 0.4.2
		//gg.Properties.setValue("MaxTimerTimeSet", 300);
		gg.Properties.setValue("ManualTimeSet", 300);
		gg.Properties.setValue("bgColSet", 3);
		gg.Properties.setValue("lblColSet", 10);
		gg.Properties.setValue("txtColSet", 9);
		gg.Properties.setValue("Label1ColSet", 10);
		gg.Properties.setValue("Label3ColSet", 12);
		gg.Properties.setValue("Label2ColSet", 6);		
		
		//0.4.3
		gg.Properties.setValue("pHistLabel1", 1);	
		gg.Properties.setValue("pHistLabel2", 6);	
		gg.Properties.setValue("pHistLabel3", 7);	
		
		//0.4.6
		gg.Properties.setValue("pNumberBeatsGraph", 10);	
		gg.Properties.setValue("pLongThresholdIndex", 0.2); // nominal
		gg.Properties.setValue("pShortThresholdIndex", 0.2); // nominal	
	
	}

(:preCIQ24)	
	function fresetPropertiesPreCIQ24() {		
		gg.setProperty("pAuxHRAntID", 0);
		//gg.setProperty("firstLoadEver", true);
		gg.setProperty("pFitWriteEnabled", false);
		gg.setProperty("pSensorSelect", SENSOR_SEARCH);
		gg.setProperty("pIIScale", false);
		gg.setProperty("soundSet", true);
		gg.setProperty("vibeSet", false);
		gg.setProperty("testTypeSet", TYPE_TIMER);
		gg.setProperty("timerTimeSet", 300);
		//0.4.2
		//gg.setProperty("MaxTimerTimeSet", 300);
		gg.setProperty("ManualTimeSet", 300);
		gg.setProperty("bgColSet", 3);
		gg.setProperty("lblColSet", 10);
		gg.setProperty("txtColSet", 13);
		gg.setProperty("Label1ColSet", 10);
		gg.setProperty("Label3ColSet", 12);
		gg.setProperty("Label2ColSet", 6);	
		
		//0.4.3
		gg.setProperty("pHistLabel1", 1);	
		gg.setProperty("pHistLabel2", 6);	
		gg.setProperty("pHistLabel3", 7);		
		
		//0.4.6
		gg.setProperty("pNumberBeatsGraph", 10);	
		gg.setProperty("pLongThresholdIndex", 0.2); // nominal
		gg.setProperty("pShortThresholdIndex", 0.2); // nominal	
	
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
		str = str+gg.mSampleProc.avgPulse+","+gg.mSampleProc.mRMSSD+","+gg.mSampleProc.mLnRMSSD+","+
			gg.mSampleProc.mSDNN+","+gg.mSampleProc.mSDSD+","+gg.mSampleProc.mNN50+","+
			gg.mSampleProc.mpNN50+","+gg.mSampleProc.mNN20+","+gg.mSampleProc.mpNN20;
	
		Sys.println(str);
	}
	
	function saveStatsToStore() {
		Sys.println("saveStatsToStore() called");	
		var stats = new [11];
		stats[0] = gg.mSampleProc.avgPulse;
		stats[1] = gg.mSampleProc.mRMSSD;
		stats[2] = gg.mSampleProc.mLnRMSSD;
		stats[3] = gg.mSampleProc.mSDNN;
		stats[4] = gg.mSampleProc.mSDSD; 
		stats[5] = gg.mSampleProc.mNN50;
		stats[6] = gg.mSampleProc.mpNN50; 
		stats[7] = gg.mSampleProc.mNN20;
		stats[8] = gg.mSampleProc.mpNN20;
		stats[9] = gg.mSampleProc.minDiffFound;
		stats[10] = gg.mSampleProc.maxDiffFound;
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("runstats", stats);				
		} else {
			gg.setProperty("runstats", stats);			
		}			
	}
	
	function loadStatsFromStore() {
		Sys.println("loadStatsFromStore() called");	
		var stats = new [11];
		
		try {
			if (Toybox.Application has :Storage) {	
				stats = Storage.getValue("runstats");		
			} else {
				stats = gg.getProperty("runstats");			
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
				gg.mSampleProc.avgPulse = stats[0];
				gg.mSampleProc.mRMSSD = stats[1];
				gg.mSampleProc.mLnRMSSD = stats[2];
				gg.mSampleProc.mSDNN = stats[3];
				gg.mSampleProc.mSDSD = stats[4]; 
				gg.mSampleProc.mNN50 = stats[5];
				gg.mSampleProc.mpNN50 = stats[6]; 
				gg.mSampleProc.mNN20 = stats[7];
				gg.mSampleProc.mpNN20 = stats[8];	
				gg.mSampleProc.minDiffFound = stats[9];
				gg.mSampleProc.maxDiffFound = stats[10];			
				return true;
			}
		}	
	
	}
	
	function saveIntervalsToStore() {
		Sys.println("saveIntervalsToStore() called");
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("IntervalStoreData", gg.mIntervalSampleBuffer);	
			Storage.setValue("IntervalStoreMin", gg.mSampleProc.minIntervalFound);	
			Storage.setValue("IntervalStoreMax", gg.mSampleProc.maxIntervalFound);	
			Storage.setValue("IntervalStoreIndex", gg.mSampleProc.getNumberOfSamples());				
		} else {
			gg.setProperty("IntervalStoreData", gg.mIntervalSampleBuffer);	
			gg.setProperty("IntervalStoreMin", gg.mSampleProc.minIntervalFound);	
			gg.setProperty("IntervalStoreMax", gg.mSampleProc.maxIntervalFound);	
			gg.setProperty("IntervalStoreIndex", gg.mSampleProc.getNumberOfSamples());			
		}	
	}
	
	function loadIntervalsFromStore() {
		Sys.println("loadIntervalsFromStore() called");
		
		try {
			if (Toybox.Application has :Storage) {	
				gg.mIntervalSampleBuffer = Storage.getValue("IntervalStoreData");	
				gg.mSampleProc.minIntervalFound = Storage.getValue("IntervalStoreMin");	
				gg.mSampleProc.maxIntervalFound = Storage.getValue("IntervalStoreMax");	
				gg.mSampleProc.setNumberOfSamples( Storage.getValue("IntervalStoreIndex"));	
			} else {
				gg.mIntervalSampleBuffer = gg.getProperty("IntervalStoreData");	
				gg.mSampleProc.minIntervalFound = gg.getProperty("IntervalStoreMin");	
				gg.mSampleProc.maxIntervalFound = gg.getProperty("IntervalStoreMax");	
				gg.mSampleProc.setNumberOfSamples( gg.getProperty("IntervalStoreIndex"));			
			}
		} catch (ex) {
			// storage error - most likely not written
			Sys.println("StoragePropertiesHandling: ERROR loadIntervalsFromStore");
			return false;
		}
		finally {
			// any null entries means we haven't written anything yet
			if (gg.mIntervalSampleBuffer == null) {
				// we have now written over the sample buffer
				// reinitialise the sample buffer!!
				// we should recreate the class but this runs risk of overflowing memory available during heap clear up
				//gg.mSampleProc = new SampleProcessing();
				gg.mSampleProc.initialize();			
				return false;
			} else {
				return true;
			}
		}
	}

(:preCIQ24)	
	function _CallReadPropProperty() {	
		// assumes all these values exist
		//gg.timestampSet = gg.getProperty("timestampSet");
		gg.appNameSet = Ui.loadResource(Rez.Strings.AppName);
		gg.mFitWriteEnabled = gg.getProperty("pFitWriteEnabled");
		gg.mSensorTypeExt = gg.getProperty("pSensorSelect");	
		gg.mBoolScaleII = gg.getProperty("pIIScale");
		gg.soundSet = gg.getProperty("soundSet");
		gg.vibeSet = gg.getProperty("vibeSet");
		gg.testTypeSet = gg.getProperty("testTypeSet");
		gg.timerTimeSet = gg.getProperty("timerTimeSet").toNumber();
		// 0.4.2
		gg.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;		
		//gg.mMaxTimerTimeSet = gg.getProperty("MaxTimerTimeSet").toNumber();
		gg.mManualTimeSet = gg.getProperty("ManualTimeSet").toNumber();	      
		// ColSet are index into colour map
		gg.bgColSet = gg.getProperty("bgColSet").toNumber();
		gg.lblColSet = gg.getProperty("lblColSet").toNumber();
		gg.txtColSet = gg.getProperty("txtColSet").toNumber();
		gg.Label1ColSet = gg.getProperty("Label1ColSet").toNumber();
		gg.Label3ColSet = gg.getProperty("Label3ColSet").toNumber();
		gg.Label2ColSet = gg.getProperty("Label2ColSet").toNumber();
		
		//0.4.3
		gg.mHistoryLabel1 = gg.getProperty("pHistLabel1").toNumber();	
		gg.mHistoryLabel2 = gg.getProperty("pHistLabel2").toNumber();	
		gg.mHistoryLabel3 = gg.getProperty("pHistLabel3").toNumber();	
		
		mapIndexToColours();
		
		// no history selected. binary flags as bits
		// set default selection
		// Used in menu creation
		// Note array 0 entry is time stamp but use for null case
		//gg.mHistorySelectFlags = (1 << gg.mHistoryLabel1);
		//gg.mHistorySelectFlags |= (1 << gg.mHistoryLabel2);
		//gg.mHistorySelectFlags |= (1 << gg.mHistoryLabel3);	
		
		//0.4.6
		gg.mNumberBeatsGraph = gg.getProperty("pNumberBeatsGraph").toNumber();	
		
		//var index = gg.getProperty("pLongThresholdIndex").toNumber();
		//var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
        //var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
		//gg.vUpperThresholdSet = mLongThresholdMap[index];
		//index = gg.getProperty("pShortThresholdIndex").toNumber();	
		//gg.vLowerThresholdSet = mShortThresholdMap[index];	
		gg.vUpperThresholdSet = gg.getProperty("pLongThresholdIndex").toFloat();
		gg.vLowerThresholdSet = gg.getProperty("pShortThresholdIndex").toFloat();
	}

(:storageMethod)	
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		// On very first use of app don't read in properties!
		//try {
			//gg.timestampSet = Storage.getValue("timestampSet");
			gg.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			gg.mFitWriteEnabled = gg.Properties.getValue("pFitWriteEnabled");
			gg.mSensorTypeExt = gg.Properties.getValue("pSensorSelect");
			gg.mBoolScaleII = gg.Properties.getValue("pIIScale");
			gg.soundSet = gg.Properties.getValue("soundSet");
			gg.vibeSet = gg.Properties.getValue("vibeSet");
			gg.testTypeSet = gg.Properties.getValue("testTypeSet");
			gg.timerTimeSet = gg.Properties.getValue("timerTimeSet").toNumber();
			// 0.4.2
			gg.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;	
			//gg.mMaxTimerTimeSet = gg.Properties.getValue("MaxTimerTimeSet").toNumber();
			gg.mManualTimeSet = gg.Properties.getValue("ManualTimeSet").toNumber();
	      
			// ColSet are index into colour map
			gg.bgColSet = gg.Properties.getValue("bgColSet").toNumber();
			gg.lblColSet = gg.Properties.getValue("lblColSet").toNumber();
			gg.txtColSet = gg.Properties.getValue("txtColSet").toNumber();
			gg.Label1ColSet = gg.Properties.getValue("Label1ColSet").toNumber();
			gg.Label3ColSet = gg.Properties.getValue("Label3ColSet").toNumber();
			gg.Label2ColSet = gg.Properties.getValue("Label2ColSet").toNumber();	
			
			//0.4.3
			gg.mHistoryLabel1 = gg.Properties.getValue("pHistLabel1").toNumber();	
			gg.mHistoryLabel2 = gg.Properties.getValue("pHistLabel2").toNumber();	
			gg.mHistoryLabel3 = gg.Properties.getValue("pHistLabel3").toNumber();	
			
			mapIndexToColours();
			
		//} catch (e) {
		//	Sys.println(e.getErrorMessage() );
		//}
			gg.mNumberBeatsGraph = gg.Properties.getValue("pNumberBeatsGraph").toNumber();	
			
			//var index = gg.Properties.getValue("pLongThresholdIndex").toNumber();
			//var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
            //var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
			//gg.vUpperThresholdSet = mLongThresholdMap[index];
			//index = gg.Properties.getValue("pShortThresholdIndex").toNumber();	
			//gg.vLowerThresholdSet = mShortThresholdMap[index];	
		gg.vUpperThresholdSet = gg.getProperty("pLongThresholdIndex").toFloat();
		gg.vLowerThresholdSet = gg.getProperty("pShortThresholdIndex").toFloat();
	}

(:discard)	
	function fFindThresholdIndex() {
		var long = 0;
		var short = 0;
		
		var index;
		var mThreshold;
		var value;
		// need to reverse lookup current threshold string from value then index in array
		mThreshold = gg.vUpperThresholdSet; 
		
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
		
		mThreshold = gg.vLowerThresholdSet; 
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
		//Storage.setValue("timestampSet", gg.timestampSet);
		gg.Properties.setValue("pFitWriteEnabled", gg.mFitWriteEnabled);
		gg.Properties.setValue("pSensorSelect", gg.mSensorTypeExt);
		
		// user changable
		gg.Properties.setValue("pIIScale", gg.mBoolScaleII);
		gg.Properties.setValue("soundSet", gg.soundSet);
		gg.Properties.setValue("vibeSet", gg.vibeSet);
		gg.Properties.setValue("testTypeSet", gg.testTypeSet);
		gg.Properties.setValue("timerTimeSet", gg.timerTimeSet);
		// 0.4.2
		//gg.Properties.setValue("MaxTimerTimeSet", gg.mMaxTimerTimeSet);
		gg.Properties.setValue("ManualTimeSet", gg.mManualTimeSet);
      
		// ColSet are index into colour map
		gg.Properties.setValue("bgColSet", gg.bgColSet);
		gg.Properties.setValue("lblColSet", gg.lblColSet);
		gg.Properties.setValue("txtColSet", gg.txtColSet);
		gg.Properties.setValue("Label1ColSet", gg.Label1ColSet);
		gg.Properties.setValue("Label3ColSet", gg.Label3ColSet);
		gg.Properties.setValue("Label2ColSet", gg.Label2ColSet);	
		
		//0.4.3
		gg.Properties.setValue("pHistLabel1", gg.mHistoryLabel1);
		gg.Properties.setValue("pHistLabel2", gg.mHistoryLabel2);
		gg.Properties.setValue("pHistLabel3", gg.mHistoryLabel3);
		
		//0.4.6
		gg.Properties.setValue("pNumberBeatsGraph", gg.mNumberBeatsGraph);
		
		
		//0.4.7
		// move code to function
		//var res = new [2];
		//res = fFindThresholdIndex();
		
		//gg.Properties.setValue("pLongThresholdIndex", res[0]);		
		//gg.Properties.setValue("pShortThresholdIndex", res[1]);
		
		gg.Properties.setValue("pLongThresholdIndex", gg.vUpperThresholdSet );		
		gg.Properties.setValue("pShortThresholdIndex", gg.vLowerThresholdSet);
			
	}

(:preCIQ24)	
	function _CallSavePropProperty() {
		//gg.setProperty("timestampSet", gg.timestampSet);
		gg.setProperty("pFitWriteEnabled", gg.mFitWriteEnabled);
		gg.setProperty("pSensorSelect", gg.mFitWriteEnabled);

		gg.setProperty("pIIScale", gg.mBoolScaleII);
		gg.setProperty("soundSet", gg.soundSet);
		gg.setProperty("vibeSet", gg.vibeSet);
		gg.setProperty("testTypeSet", gg.testTypeSet);
		gg.setProperty("timerTimeSet", gg.timerTimeSet);
		// 0.4.2	
		//gg.setProperty("MaxTimerTimeSet", gg.mMaxTimerTimeSet);
		gg.setProperty("ManualTimeSet", gg.mManualTimeSet);
      
		// ColSet are index into colour map
		gg.setProperty("bgColSet", gg.bgColSet);
		gg.setProperty("lblColSet", gg.lblColSet);
		gg.setProperty("txtColSet", gg.txtColSet);
		gg.setProperty("Label1ColSet", gg.Label1ColSet);
		gg.setProperty("Label3ColSet", gg.Label3ColSet);
		gg.setProperty("Label2ColSet", gg.Label2ColSet);	

		//0.4.3
		gg.setProperty("pHistLabel1", gg.mHistoryLabel1);
		gg.setProperty("pHistLabel2", gg.mHistoryLabel2);
		gg.setProperty("pHistLabel3", gg.mHistoryLabel3);
		
		//0.4.6
		gg.setProperty("pNumberBeatsGraph", gg.mNumberBeatsGraph);	
		
		//var res = new [2];
		//res = fFindThresholdIndex();
		
		//gg.setProperty("pLongThresholdIndex", res[0]);		
		//gg.setProperty("pShortThresholdIndex", res[1]);	
		
		gg.setProperty("pLongThresholdIndex", gg.vUpperThresholdSet );		
		gg.setProperty("pShortThresholdIndex", gg.vLowerThresholdSet);
		
	}

(:oldResults)
	function resetResults() {
		// should only be called from settings - also called onStart() but followed by load
		gg.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		Sys.println("resetResults() array created");

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			gg.results[i] = 0;
		}
		// this will be overridden if we load results
		gg.resultsIndex = 0;
	}
	
(:newResults)
	function resetResults() {
		// should only be called from settings - also called onStart() but followed by load
		gg.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		Sys.println("resetResults() array created");

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			gg.results[i] = 0;
		}
		gg.resultsIndex = 0;
		
		// force history to empty
		storeResults();
		 
		gg.results = null;
	}

(:preCIQ24)
	function retrieveResultsProp() {
		var tmp = gg.getProperty("resultIndex");
		if (tmp == null) { tmp = 0;}
		gg.resultsIndex = tmp;
		
		for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var result = gg.getProperty(RESULTS + i);
			var ii = i * DATA_SET_SIZE;
			if(null != result) {
				gg.results[ii + 0] = result[0];
				gg.results[ii + 1] = result[1];
				gg.results[ii + 2] = result[2];
				gg.results[ii + 3] = result[3];
				gg.results[ii + 4] = result[4];
				gg.results[ii + 5] = result[5];
				gg.results[ii + 6] = result[6];
				gg.results[ii + 7] = result[7];
				gg.results[ii + 8] = result[8];
				gg.results[ii + 9] = result[9];
				gg.results[ii + 10] = result[10];
				gg.results[ii + 11] = result[11];
				gg.results[ii + 12] = result[12];
				gg.results[ii + 13] = result[13];
			}
		}	
	}
	
	function retrieveResults() {
		var mCheck;
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			try {
				mCheck = Storage.getValue("resultsArray");
				gg.resultsIndex = Storage.getValue("resultIndex");
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResults: no results array");
				gg.resultsIndex = 0;
				return false;
			}				
			
			if (mCheck != null) { gg.results = mCheck; } 
			// have a null if not saved 1st time
			if (gg.resultsIndex == null) {gg.resultsIndex = 0;}
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
				gg.resultsIndex = Storage.getValue("resultIndex");
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResults: no results array");
				gg.resultsIndex = 0;
				return false;
			}				
			
			if (mCheck != null) { buffer = mCheck; } 
			
			Sys.println("retrievefunc:\n mCheck ="+mCheck+"\nbuffer ="+buffer);
			// have a null if not saved 1st time
			if (gg.resultsIndex == null) {gg.resultsIndex = 0;}
			return true;			
		} else {
			retrieveResultsProp();	
		}
		Sys.println("restrieveResults() finished");
		return true;
	}

(:preCIQ24)
	function storeResultsProp() {
		gg.setProperty("resultIndex", gg.resultsIndex);
    	for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var ii = i * DATA_SET_SIZE;
			var result = gg.getProperty(RESULTS + i);
			if(null == result || gg.results[ii] != result[0]) {
				gg.setProperty(RESULTS + i, [
					gg.results[ii + 0],
					gg.results[ii + 1],
					gg.results[ii + 2],
					gg.results[ii + 3],
					gg.results[ii + 4],
					gg.results[ii + 5],
					gg.results[ii + 6],
					gg.results[ii + 7],
					gg.results[ii + 8],
					gg.results[ii + 9],
					gg.results[ii + 10],
					gg.results[ii + 11],						
					gg.results[ii + 12],
					gg.results[ii + 13]						
					]);
			}
		}	
	}
		
	function storeResults() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArray", gg.results);
			Storage.setValue("resultIndex", gg.resultsIndex);
		} else {
			storeResultsProp();
		}
	}

(:newResults)
	// function to readin results array 
	// update current day values and write back to store 	
	function prepareSaveResults( utcStart) {
		// need to load results array fill and then save
		// assume pointer still valid
		gg.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		
		// if retrieve returns null i eno storage then we will have all 0's
		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			gg.results[i] = 0;
		}
		// this will be overridden if we load results
		gg.resultsIndex = 0;
		
		retrieveResults(); 

    	// seconds in day = 86400
    	// make whole number of days (still seconds since UNIX epoch)
    	// This ignores possiblity of 32 bit integar of time wrapping on testday and epoch
    	// should change to use time functions available
		var testDayutc = utcStart - (utcStart % 86400);
		
		// next slot in cycle, can overwrite multiple times in a day and keep last ones
		// Check whether we are creating another set of results on the same day by inspecting previous entry
		var previousEntry = (gg.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
		var previousIndex = previousEntry * DATA_SET_SIZE;
		var currentIndex = gg.resultsIndex * DATA_SET_SIZE;	
		
		var x = gg.results[previousIndex + TIME_STAMP_INDEX];
		// convery to day units
		var previousSavedutc = 	x - (x % 86400);
		x = gg.results[currentIndex + TIME_STAMP_INDEX];
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
   			gg.resultsIndex = (gg.resultsIndex + 1 ) % NUM_RESULT_ENTRIES;
   			Sys.println("SaveTest: pointer now "+gg.resultsIndex);
   		}
			
		Sys.println("utcStart, index, testdayutc, previous entry utc = "+utcStart+", "+index+", "+testDayutc+", "+previousSavedutc);

		gg.results[index + TIME_STAMP_INDEX] = utcStart;
		gg.results[index + AVG_PULSE_INDEX] = gg.mSampleProc.avgPulse;
		gg.results[index + MIN_II_INDEX] = gg.mSampleProc.minIntervalFound;
		gg.results[index + MAX_II_INDEX] = gg.mSampleProc.maxIntervalFound;		
		gg.results[index + MAX_DIFF_INDEX] = gg.mSampleProc.minDiffFound;
		gg.results[index + MAX_DIFF_INDEX] = gg.mSampleProc.maxDiffFound;				
		gg.results[index + RMSSD_INDEX] = gg.mSampleProc.mRMSSD;
		gg.results[index + LNRMSSD_INDEX] = gg.mSampleProc.mLnRMSSD;

		gg.results[index + SDNN_INDEX] = gg.mSampleProc.mSDNN;
		gg.results[index + SDSD_INDEX] = gg.mSampleProc.mSDSD; 
		gg.results[index + NN50_INDEX] = gg.mSampleProc.mNN50;
		gg.results[index + PNN50_INDEX] = gg.mSampleProc.mpNN50; 
		gg.results[index + NN20_INDEX] = gg.mSampleProc.mNN20;
		gg.results[index + PNN20_INDEX] = gg.mSampleProc.mpNN20;
   		
   		Sys.println("storing results ... ="+gg.results);
   		
    	// better write results to memory!!
    	storeResults(); 
    	// save intervals as well so we can reload and display
    	saveIntervalsToStore();
    	saveStatsToStore();   	
    	
    	// discard results buffer as large
    	gg.results = null;
    	
	} // end prepareResults 

	function saveStrings(_type) {
		var mString;
		var base;
		var mSp;
		var separator = ",";
		var mNumEntries = gg.mSampleProc.getNumberOfSamples();

		if (mNumEntries <= 0) { return;}
			
		mString = ( _type == 0 ? "II:," : "Flags:,");

		for (var i=0; i < mNumEntries; i++) {
				mSp = gg.mIntervalSampleBuffer[i];
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

 