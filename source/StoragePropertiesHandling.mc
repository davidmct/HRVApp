using Toybox.System as Sys;
using Toybox.Application.Properties; // as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Lang;

// STORAGE came in with CIQ 2.4 - could cut down code by removing all pre CIQ2.4 code

// Results memory locations. (X) <> (X + 29)

class HRVStorageHandler {

	// setup storage functions	
    function initialize() {
    	// create buffers here? use function so external can call parts   	
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
		$._mApp.Properties.setValue("pAuxHRAntID", 0);
		Storage.setValue("firstLoadEver", true);
		$._mApp.Properties.setValue("pFitWriteEnabled", false);
		$._mApp.Properties.setValue("pSensorSelect", SENSOR_SEARCH);
		$._mApp.Properties.setValue("soundSet", true);
		$._mApp.Properties.setValue("vibeSet", false);
		$._mApp.Properties.setValue("testTypeSet", TYPE_TIMER);
		$._mApp.Properties.setValue("timerTimeSet", 300);
		// 0.4.2
		//$._mApp.Properties.setValue("MaxTimerTimeSet", 300);
		$._mApp.Properties.setValue("ManualTimeSet", 300);
		$._mApp.Properties.setValue("bgColSet", 3);
		$._mApp.Properties.setValue("lblColSet", 10);
		$._mApp.Properties.setValue("txtColSet", 9);
		$._mApp.Properties.setValue("Label1ColSet", 10);
		$._mApp.Properties.setValue("Label3ColSet", 12);
		$._mApp.Properties.setValue("Label2ColSet", 6);		
		
		//0.4.3
		$._mApp.Properties.setValue("pHistLabel1", 1);	
		$._mApp.Properties.setValue("pHistLabel2", 6);	
		$._mApp.Properties.setValue("pHistLabel3", 7);	
		
		//0.4.6
		$._mApp.Properties.setValue("pNumberBeatsGraph", 10);	
		$._mApp.Properties.setValue("pLongThresholdIndex", 2); // nominal
		$._mApp.Properties.setValue("pShortThresholdIndex", 2); // nominal	
	
	}

(:preCIQ24)	
	function fresetPropertiesPreCIQ24() {		
		$._mApp.setProperty("pAuxHRAntID", 0);
		//$._mApp.setProperty("firstLoadEver", true);
		$._mApp.setProperty("pFitWriteEnabled", false);
		$._mApp.setProperty("pSensorSelect", SENSOR_SEARCH);
		$._mApp.setProperty("soundSet", true);
		$._mApp.setProperty("vibeSet", false);
		$._mApp.setProperty("testTypeSet", TYPE_TIMER);
		$._mApp.setProperty("timerTimeSet", 300);
		//0.4.2
		//$._mApp.setProperty("MaxTimerTimeSet", 300);
		$._mApp.setProperty("ManualTimeSet", 300);
		$._mApp.setProperty("bgColSet", 3);
		$._mApp.setProperty("lblColSet", 10);
		$._mApp.setProperty("txtColSet", 13);
		$._mApp.setProperty("Label1ColSet", 10);
		$._mApp.setProperty("Label3ColSet", 12);
		$._mApp.setProperty("Label2ColSet", 6);	
		
		//0.4.3
		$._mApp.setProperty("pHistLabel1", 1);	
		$._mApp.setProperty("pHistLabel2", 6);	
		$._mApp.setProperty("pHistLabel3", 7);		
		
		//0.4.6
		$._mApp.setProperty("pNumberBeatsGraph", 10);	
		$._mApp.setProperty("pLongThresholdIndex", 2); // nominal
		$._mApp.setProperty("pShortThresholdIndex", 2); // nominal	
	
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
		str = str+$._mApp.mSampleProc.avgPulse+","+$._mApp.mSampleProc.mRMSSD+","+$._mApp.mSampleProc.mLnRMSSD+","+
			$._mApp.mSampleProc.mSDNN+","+$._mApp.mSampleProc.mSDSD+","+$._mApp.mSampleProc.mNN50+","+
			$._mApp.mSampleProc.mpNN50+","+$._mApp.mSampleProc.mNN20+","+$._mApp.mSampleProc.mpNN20;
	
		Sys.println(str);
	}
	
	function saveStatsToStore() {
		Sys.println("saveStatsToStore() called");	
		var stats = new [11];
		stats[0] = $._mApp.mSampleProc.avgPulse;
		stats[1] = $._mApp.mSampleProc.mRMSSD;
		stats[2] = $._mApp.mSampleProc.mLnRMSSD;
		stats[3] = $._mApp.mSampleProc.mSDNN;
		stats[4] = $._mApp.mSampleProc.mSDSD; 
		stats[5] = $._mApp.mSampleProc.mNN50;
		stats[6] = $._mApp.mSampleProc.mpNN50; 
		stats[7] = $._mApp.mSampleProc.mNN20;
		stats[8] = $._mApp.mSampleProc.mpNN20;
		stats[9] = $._mApp.mSampleProc.minDiffFound;
		stats[10] = $._mApp.mSampleProc.maxDiffFound;
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("runstats", stats);				
		} else {
			$._mApp.setProperty("runstats", stats);			
		}			
	}
	
	function loadStatsFromStore() {
		Sys.println("loadStatsFromStore() called");	
		var stats = new [11];
		
		try {
			if (Toybox.Application has :Storage) {	
				stats = Storage.getValue("runstats");		
			} else {
				stats = $._mApp.getProperty("runstats");			
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
				$._mApp.mSampleProc.avgPulse = stats[0];
				$._mApp.mSampleProc.mRMSSD = stats[1];
				$._mApp.mSampleProc.mLnRMSSD = stats[2];
				$._mApp.mSampleProc.mSDNN = stats[3];
				$._mApp.mSampleProc.mSDSD = stats[4]; 
				$._mApp.mSampleProc.mNN50 = stats[5];
				$._mApp.mSampleProc.mpNN50 = stats[6]; 
				$._mApp.mSampleProc.mNN20 = stats[7];
				$._mApp.mSampleProc.mpNN20 = stats[8];	
				$._mApp.mSampleProc.minDiffFound = stats[9];
				$._mApp.mSampleProc.maxDiffFound = stats[10];			
				return true;
			}
		}	
	
	}
	
	function saveIntervalsToStore() {
		Sys.println("saveIntervalsToStore() called");
		
		if (Toybox.Application has :Storage) {
			Storage.setValue("IntervalStoreData", $._mApp.mIntervalSampleBuffer);	
			Storage.setValue("IntervalStoreMin", $._mApp.mSampleProc.minIntervalFound);	
			Storage.setValue("IntervalStoreMax", $._mApp.mSampleProc.maxIntervalFound);	
			Storage.setValue("IntervalStoreIndex", $._mApp.mSampleProc.getNumberOfSamples());				
		} else {
			$._mApp.setProperty("IntervalStoreData", $._mApp.mIntervalSampleBuffer);	
			$._mApp.setProperty("IntervalStoreMin", $._mApp.mSampleProc.minIntervalFound);	
			$._mApp.setProperty("IntervalStoreMax", $._mApp.mSampleProc.maxIntervalFound);	
			$._mApp.setProperty("IntervalStoreIndex", $._mApp.mSampleProc.getNumberOfSamples());			
		}	
	}
	
	function loadIntervalsFromStore() {
		Sys.println("loadIntervalsFromStore() called");
		
		try {
			if (Toybox.Application has :Storage) {	
				$._mApp.mIntervalSampleBuffer = Storage.getValue("IntervalStoreData");	
				$._mApp.mSampleProc.minIntervalFound = Storage.getValue("IntervalStoreMin");	
				$._mApp.mSampleProc.maxIntervalFound = Storage.getValue("IntervalStoreMax");	
				$._mApp.mSampleProc.setNumberOfSamples( Storage.getValue("IntervalStoreIndex"));	
			} else {
				$._mApp.mIntervalSampleBuffer = $._mApp.getProperty("IntervalStoreData");	
				$._mApp.mSampleProc.minIntervalFound = $._mApp.getProperty("IntervalStoreMin");	
				$._mApp.mSampleProc.maxIntervalFound = $._mApp.getProperty("IntervalStoreMax");	
				$._mApp.mSampleProc.setNumberOfSamples( $._mApp.getProperty("IntervalStoreIndex"));			
			}
		} catch (ex) {
			// storage error - most likely not written
			Sys.println("StoragePropertiesHandling: ERROR loadIntervalsFromStore");
			return false;
		}
		finally {
			// any null entries means we haven't written anything yet
			if ($._mApp.mIntervalSampleBuffer == null) {
				// we have now written over the sample buffer
				// reinitialise the sample buffer!!
				// we should recreate the class but this runs risk of overflowing memory available during heap clear up
				//$._mApp.mSampleProc = new SampleProcessing();
				$._mApp.mSampleProc.initialize();			
				return false;
			} else {
				return true;
			}
		}
	}

(:preCIQ24)	
	function _CallReadPropProperty() {	
		// assumes all these values exist
		//$._mApp.timestampSet = $._mApp.getProperty("timestampSet");
		$._mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
		$._mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
		$._mApp.mFitWriteEnabled = $._mApp.getProperty("pFitWriteEnabled");
		$._mApp.mSensorTypeExt = $._mApp.getProperty("pSensorSelect");	
		$._mApp.soundSet = $._mApp.getProperty("soundSet");
		$._mApp.vibeSet = $._mApp.getProperty("vibeSet");
		$._mApp.testTypeSet = $._mApp.getProperty("testTypeSet");
		$._mApp.timerTimeSet = $._mApp.getProperty("timerTimeSet").toNumber();
		// 0.4.2
		$._mApp.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;		
		//$._mApp.mMaxTimerTimeSet = $._mApp.getProperty("MaxTimerTimeSet").toNumber();
		$._mApp.mManualTimeSet = $._mApp.getProperty("ManualTimeSet").toNumber();	      
		// ColSet are index into colour map
		$._mApp.bgColSet = $._mApp.getProperty("bgColSet").toNumber();
		$._mApp.lblColSet = $._mApp.getProperty("lblColSet").toNumber();
		$._mApp.txtColSet = $._mApp.getProperty("txtColSet").toNumber();
		$._mApp.Label1ColSet = $._mApp.getProperty("Label1ColSet").toNumber();
		$._mApp.Label3ColSet = $._mApp.getProperty("Label3ColSet").toNumber();
		$._mApp.Label2ColSet = $._mApp.getProperty("Label2ColSet").toNumber();
		
		//0.4.3
		$._mApp.mHistoryLabel1 = $._mApp.getProperty("pHistLabel1").toNumber();	
		$._mApp.mHistoryLabel2 = $._mApp.getProperty("pHistLabel2").toNumber();	
		$._mApp.mHistoryLabel3 = $._mApp.getProperty("pHistLabel3").toNumber();	
		
		mapIndexToColours();
		
		// no history selected. binary flags as bits
		// set default selection
		// Used in menu creation
		// Note array 0 entry is time stamp but use for null case
		//$._mApp.mHistorySelectFlags = (1 << $._mApp.mHistoryLabel1);
		//$._mApp.mHistorySelectFlags |= (1 << $._mApp.mHistoryLabel2);
		//$._mApp.mHistorySelectFlags |= (1 << $._mApp.mHistoryLabel3);	
		
		//0.4.6
		$._mApp.mNumberBeatsGraph = $._mApp.getProperty("pNumberBeatsGraph").toNumber();	
		
		var index = $._mApp.getProperty("pLongThresholdIndex").toNumber();
		var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
        var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
		$._mApp.vUpperThresholdSet = mLongThresholdMap[index];
		index = $._mApp.getProperty("pShortThresholdIndex").toNumber();	
		$._mApp.vLowerThresholdSet = mShortThresholdMap[index];	

	}

(:storageMethod)	
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		// On very first use of app don't read in properties!
		//try {
			//$._mApp.timestampSet = Storage.getValue("timestampSet");
			$._mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			$._mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			$._mApp.mFitWriteEnabled = $._mApp.Properties.getValue("pFitWriteEnabled");
			$._mApp.mSensorTypeExt = $._mApp.Properties.getValue("pSensorSelect");
			$._mApp.soundSet = $._mApp.Properties.getValue("soundSet");
			$._mApp.vibeSet = $._mApp.Properties.getValue("vibeSet");
			$._mApp.testTypeSet = $._mApp.Properties.getValue("testTypeSet");
			$._mApp.timerTimeSet = $._mApp.Properties.getValue("timerTimeSet").toNumber();
			// 0.4.2
			$._mApp.mMaxTimerTimeSet = MAX_TIME * MAX_BPM;	
			//$._mApp.mMaxTimerTimeSet = $._mApp.Properties.getValue("MaxTimerTimeSet").toNumber();
			$._mApp.mManualTimeSet = $._mApp.Properties.getValue("ManualTimeSet").toNumber();
	      
			// ColSet are index into colour map
			$._mApp.bgColSet = $._mApp.Properties.getValue("bgColSet").toNumber();
			$._mApp.lblColSet = $._mApp.Properties.getValue("lblColSet").toNumber();
			$._mApp.txtColSet = $._mApp.Properties.getValue("txtColSet").toNumber();
			$._mApp.Label1ColSet = $._mApp.Properties.getValue("Label1ColSet").toNumber();
			$._mApp.Label3ColSet = $._mApp.Properties.getValue("Label3ColSet").toNumber();
			$._mApp.Label2ColSet = $._mApp.Properties.getValue("Label2ColSet").toNumber();	
			
			//0.4.3
			$._mApp.mHistoryLabel1 = $._mApp.Properties.getValue("pHistLabel1").toNumber();	
			$._mApp.mHistoryLabel2 = $._mApp.Properties.getValue("pHistLabel2").toNumber();	
			$._mApp.mHistoryLabel3 = $._mApp.Properties.getValue("pHistLabel3").toNumber();	
			
			mapIndexToColours();
			
		//} catch (e) {
		//	Sys.println(e.getErrorMessage() );
		//}
			$._mApp.mNumberBeatsGraph = $._mApp.Properties.getValue("pNumberBeatsGraph").toNumber();	
			
			var index = $._mApp.Properties.getValue("pLongThresholdIndex").toNumber();
			var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
            var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);				
			$._mApp.vUpperThresholdSet = mLongThresholdMap[index];
			index = $._mApp.Properties.getValue("pShortThresholdIndex").toNumber();	
			$._mApp.vLowerThresholdSet = mShortThresholdMap[index];	

	}
	
	function fFindThresholdIndex() {
		var long = 0;
		var short = 0;
		
		var index;
		var mThreshold;
		var value;
		// need to reverse lookup current threshold string from value then index in array
		mThreshold = $._mApp.vUpperThresholdSet; 
		
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
		
		mThreshold = $._mApp.vLowerThresholdSet; 
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
		//Storage.setValue("timestampSet", $._mApp.timestampSet);
		$._mApp.Properties.setValue("pFitWriteEnabled", $._mApp.mFitWriteEnabled);
		$._mApp.Properties.setValue("pSensorSelect", $._mApp.mSensorTypeExt);
		
		// user changable
		$._mApp.Properties.setValue("soundSet", $._mApp.soundSet);
		$._mApp.Properties.setValue("vibeSet", $._mApp.vibeSet);
		$._mApp.Properties.setValue("testTypeSet", $._mApp.testTypeSet);
		$._mApp.Properties.setValue("timerTimeSet", $._mApp.timerTimeSet);
		// 0.4.2
		//$._mApp.Properties.setValue("MaxTimerTimeSet", $._mApp.mMaxTimerTimeSet);
		$._mApp.Properties.setValue("ManualTimeSet", $._mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		$._mApp.Properties.setValue("bgColSet", $._mApp.bgColSet);
		$._mApp.Properties.setValue("lblColSet", $._mApp.lblColSet);
		$._mApp.Properties.setValue("txtColSet", $._mApp.txtColSet);
		$._mApp.Properties.setValue("Label1ColSet", $._mApp.Label1ColSet);
		$._mApp.Properties.setValue("Label3ColSet", $._mApp.Label3ColSet);
		$._mApp.Properties.setValue("Label2ColSet", $._mApp.Label2ColSet);	
		
		//0.4.3
		$._mApp.Properties.setValue("pHistLabel1", $._mApp.mHistoryLabel1);
		$._mApp.Properties.setValue("pHistLabel2", $._mApp.mHistoryLabel2);
		$._mApp.Properties.setValue("pHistLabel3", $._mApp.mHistoryLabel3);
		
		//0.4.6
		$._mApp.Properties.setValue("pNumberBeatsGraph", $._mApp.mNumberBeatsGraph);
		
		
		//0.4.7
		// move code to function
		var res = new [2];
		res = fFindThresholdIndex();
		
		$._mApp.Properties.setValue("pLongThresholdIndex", res[0]);		
		$._mApp.Properties.setValue("pShortThresholdIndex", res[1]);	
			
	}

(:preCIQ24)	
	function _CallSavePropProperty() {
		//$._mApp.setProperty("timestampSet", $._mApp.timestampSet);
		$._mApp.setProperty("pFitWriteEnabled", $._mApp.mFitWriteEnabled);
		$._mApp.setProperty("pSensorSelect", $._mApp.mFitWriteEnabled);

		$._mApp.setProperty("soundSet", $._mApp.soundSet);
		$._mApp.setProperty("vibeSet", $._mApp.vibeSet);
		$._mApp.setProperty("testTypeSet", $._mApp.testTypeSet);
		$._mApp.setProperty("timerTimeSet", $._mApp.timerTimeSet);
		// 0.4.2	
		//$._mApp.setProperty("MaxTimerTimeSet", $._mApp.mMaxTimerTimeSet);
		$._mApp.setProperty("ManualTimeSet", $._mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		$._mApp.setProperty("bgColSet", $._mApp.bgColSet);
		$._mApp.setProperty("lblColSet", $._mApp.lblColSet);
		$._mApp.setProperty("txtColSet", $._mApp.txtColSet);
		$._mApp.setProperty("Label1ColSet", $._mApp.Label1ColSet);
		$._mApp.setProperty("Label3ColSet", $._mApp.Label3ColSet);
		$._mApp.setProperty("Label2ColSet", $._mApp.Label2ColSet);	

		//0.4.3
		$._mApp.setProperty("pHistLabel1", $._mApp.mHistoryLabel1);
		$._mApp.setProperty("pHistLabel2", $._mApp.mHistoryLabel2);
		$._mApp.setProperty("pHistLabel3", $._mApp.mHistoryLabel3);
		
		//0.4.6
		$._mApp.setProperty("pNumberBeatsGraph", $._mApp.mNumberBeatsGraph);	
		
		var res = new [2];
		res = fFindThresholdIndex();
		
		$._mApp.setProperty("pLongThresholdIndex", res[0]);		
		$._mApp.setProperty("pShortThresholdIndex", res[1]);	
		
	}

	function resetResults() {
		// should only be called from settings - also called onStart() but followed by load
		$._mApp.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];
		Sys.println("resetResults() array created");

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$._mApp.results[i] = 0;
		}
		// this will be overridden if we load results
		$._mApp.resultsIndex = 0;
	}

(:preCIQ24)
	function retrieveResultsProp() {
		var tmp = $._mApp.getProperty("resultIndex");
		if (tmp == null) { tmp = 0;}
		$._mApp.resultsIndex = tmp;
		
		for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var result = $._mApp.getProperty(RESULTS + i);
			var ii = i * DATA_SET_SIZE;
			if(null != result) {
				$._mApp.results[ii + 0] = result[0];
				$._mApp.results[ii + 1] = result[1];
				$._mApp.results[ii + 2] = result[2];
				$._mApp.results[ii + 3] = result[3];
				$._mApp.results[ii + 4] = result[4];
				$._mApp.results[ii + 5] = result[5];
				$._mApp.results[ii + 6] = result[6];
				$._mApp.results[ii + 7] = result[7];
				$._mApp.results[ii + 8] = result[8];
				$._mApp.results[ii + 9] = result[9];
				$._mApp.results[ii + 10] = result[10];
				$._mApp.results[ii + 11] = result[11];
				$._mApp.results[ii + 12] = result[12];
				$._mApp.results[ii + 13] = result[13];
			}
		}	
	}
	
	function retrieveResults() {
		var mCheck;
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			try {
				mCheck = Storage.getValue("resultsArray");
				$._mApp.resultsIndex = Storage.getValue("resultIndex");
			}
			catch (ex) {
				Sys.println("ERROR: retrieveResults: no results array");
				$._mApp.resultsIndex = 0;
				return false;
			}				
			
			if (mCheck != null) { $._mApp.results = mCheck; } 
			// have a null if not saved 1st time
			if ($._mApp.resultsIndex == null) {$._mApp.resultsIndex = 0;}
			return true;			
		} else {
			retrieveResultsProp();	
		}
		Sys.println("restrieveResults() finished");
		return true;
	}

(:preCIQ24)
	function storeResultsProp() {
		$._mApp.setProperty("resultIndex", $._mApp.resultsIndex);
    	for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var ii = i * DATA_SET_SIZE;
			var result = $._mApp.getProperty(RESULTS + i);
			if(null == result || $._mApp.results[ii] != result[0]) {
				$._mApp.setProperty(RESULTS + i, [
					$._mApp.results[ii + 0],
					$._mApp.results[ii + 1],
					$._mApp.results[ii + 2],
					$._mApp.results[ii + 3],
					$._mApp.results[ii + 4],
					$._mApp.results[ii + 5],
					$._mApp.results[ii + 6],
					$._mApp.results[ii + 7],
					$._mApp.results[ii + 8],
					$._mApp.results[ii + 9],
					$._mApp.results[ii + 10],
					$._mApp.results[ii + 11],						
					$._mApp.results[ii + 12],
					$._mApp.results[ii + 13]						
					]);
			}
		}	
	}
		
	function storeResults() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArray", $._mApp.results);
			Storage.setValue("resultIndex", $._mApp.resultsIndex);
		} else {
			storeResultsProp();
		}
	}
	
}

 