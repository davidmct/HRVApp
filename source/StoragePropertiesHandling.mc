using Toybox.System as Sys;
using Toybox.Application.Properties as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;

// Results memory locations. (X) <> (X + 29)
const NUM_RESULT_ENTRIES = 30; // last 30 days
const DATA_SET_SIZE = 5; // each containing this number of entries
// for properties method of storage, arranged as arrays of results per time period
const RESULTS = "RESULTS";

// Samples needed for stats min
const MIN_SAMPLES = 20;

class HRVStorageHandler {

// if initial run then we should clear store
// Storage.clearValues();
// then save default set of properties

	// setup storage functions	
    function initialize() {
    	// create buffers here? use function so external can call parts
    	
    }

	// message from Garmin that settings have been changed on mobile - called from main app
	function onSettingsChangedStore() {
		// should probably stop any test and reload settings

	}

// date settings from Garmin are in UTC so use Gregorian.utcInfo() when working with these in place of Gregorian.info()

	// This should be factory default settings and should write values back to store
	function resetSettings() {
	
		if (Toybox.Application has :Storage) {
			// use Storage.get/setValue("", value) for storage or properties not used in settings			
			$._mApp.Properties.setValue("pAuxHRAntID", 0);
			Storage.setValue("firstLoadEver", true);
			$._mApp.Properties.setValue("pFitWriteEnabled", false);
			$._mApp.Properties.setValue("pSensorSelect", true);
			$._mApp.Properties.setValue("soundSet", true);
			$._mApp.Properties.setValue("vibeSet", false);
			$._mApp.Properties.setValue("testTypeSet", 0);
			$._mApp.Properties.setValue("timerTimeSet", 300);
			$._mApp.Properties.setValue("MaxTimerTimeSet", 300);
			$._mApp.Properties.setValue("ManualTimeSet", 300);
			$._mApp.Properties.setValue("bgColSet", 3);
			$._mApp.Properties.setValue("lblColSet", 10);
			$._mApp.Properties.setValue("txtColSet", 13);
			$._mApp.Properties.setValue("hrvColSet", 10);
			$._mApp.Properties.setValue("avgHrvColSet", 12);
			$._mApp.Properties.setValue("pulseColSet", 13);
			$._mApp.Properties.setValue("avgPulseColSet", 6);		
		} else {
			$._mApp.setProperty("pAuxHRAntID", 0);
			$._mApp.setProperty("firstLoadEver", true);
			$._mApp.setProperty("pFitWriteEnabled", false);
			$._mApp.setProperty("pSensorSelect", true);
			$._mApp.setProperty("soundSet", true);
			$._mApp.setProperty("vibeSet", false);
			$._mApp.setProperty("testTypeSet", 0);
			$._mApp.setProperty("timerTimeSet", 300);
			$._mApp.setProperty("MaxTimerTimeSet", 300);
			$._mApp.setProperty("ManualTimeSet", 300);
			$._mApp.setProperty("bgColSet", 3);
			$._mApp.setProperty("lblColSet", 10);
			$._mApp.setProperty("txtColSet", 13);
			$._mApp.setProperty("hrvColSet", 10);
			$._mApp.setProperty("avgHrvColSet", 12);
			$._mApp.setProperty("pulseColSet", 13);
			$._mApp.setProperty("avgPulseColSet", 6);		
		}
	
		// now load up variables
		readProperties();
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
	
	function _CallReadPropProperty() {	
		// On very first use of app don't read in properties!
		//var value;
		
		// FORCE NOT OVER WRITE
		//value = $._mApp.getProperty("firstLoadEver");
		//if (mDebugging == true) {value = null;}
			
		//if (value == null) {
		//	$._mApp.setProperty("firstLoadEver", true);
		//} else {
			// assumes all these values exist
			$._mApp.timestampSet = $._mApp.getProperty("timestampSet");
			$._mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			$._mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			$._mApp.mFitWriteEnabled = $._mApp.getProperty("pFitWriteEnabled");
			$._mApp.mSensorTypeExt = $._mApp.getProperty("pSensorSelect");	
			$._mApp.soundSet = $._mApp.getProperty("soundSet");
			$._mApp.vibeSet = $._mApp.getProperty("vibeSet");
			$._mApp.testTypeSet = $._mApp.getProperty("testTypeSet").toNumber();
			$._mApp.timerTimeSet = $._mApp.getProperty("timerTimeSet").toNumber();
			$._mApp.mMaxTimerTimeSet = $._mApp.getProperty("MaxTimerTimeSet").toNumber();
			$._mApp.mManualTimeSet = $._mApp.getProperty("ManualTimeSet").toNumber();	      
			// ColSet are index into colour map
			$._mApp.bgColSet = $._mApp.getProperty("bgColSet").toNumber();
			$._mApp.lblColSet = $._mApp.getProperty("lblColSet").toNumber();
			$._mApp.txtColSet = $._mApp.getProperty("txtColSet").toNumber();
			$._mApp.hrvColSet = $._mApp.getProperty("hrvColSet").toNumber();
			$._mApp.avgHrvColSet = $._mApp.getProperty("avgHrvColSet").toNumber();
			$._mApp.pulseColSet = $._mApp.getProperty("pulseColSet").toNumber();
			$._mApp.avgPulseColSet = $._mApp.getProperty("avgPulseColSet").toNumber();
	
		//}
	}
	
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		// On very first use of app don't read in properties!
		//var value;
		
		// FORCE NOT OVER WRITE
		//value = Storage.getValue("firstLoadEver");
		//if (mDebugging == true) {value = null;}
			
		//if (value == null) {
			//Storage.setValue("firstLoadEver", true);
		//} else {	
			$._mApp.timestampSet = Storage.getValue("timestampSet");
			$._mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			$._mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			$._mApp.mFitWriteEnabled = $._mApp.Properties.getValue("pFitWriteEnabled");
			$._mApp.mSensorTypeExt = $._mApp.Properties.getValue("pSensorSelect");
			$._mApp.soundSet = $._mApp.Properties.getValue("soundSet");
			$._mApp.vibeSet = $._mApp.Properties.getValue("vibeSet");
			$._mApp.testTypeSet = $._mApp.Properties.getValue("testTypeSet").toNumber();
			$._mApp.timerTimeSet = $._mApp.Properties.getValue("timerTimeSet").toNumber();
			$._mApp.mMaxTimerTimeSet = $._mApp.Properties.getValue("MaxTimerTimeSet").toNumber();
			$._mApp.mManualTimeSet = $._mApp.Properties.getValue("ManualTimeSet").toNumber();
	      
			// ColSet are index into colour map
			$._mApp.bgColSet = $._mApp.Properties.getValue("bgColSet").toNumber();
			$._mApp.lblColSet = $._mApp.Properties.getValue("lblColSet").toNumber();
			$._mApp.txtColSet = $._mApp.Properties.getValue("txtColSet").toNumber();
			$._mApp.hrvColSet = $._mApp.Properties.getValue("hrvColSet").toNumber();
			$._mApp.avgHrvColSet = $._mApp.Properties.getValue("avgHrvColSet").toNumber();
			$._mApp.pulseColSet = $._mApp.Properties.getValue("pulseColSet").toNumber();
			$._mApp.avgPulseColSet = $._mApp.Properties.getValue("avgPulseColSet").toNumber();	
		//}	
	}
	
	function _CallSavePropStorage() {
		Storage.setValue("timestampSet", $._mApp.timestampSet);
		$._mApp.Properties.setValue("pFitWriteEnabled", $._mApp.mFitWriteEnabled);
		$._mApp.Properties.setValue("pSensorSelect", $._mApp.mSensorTypeExt);
		
		// user changable
		$._mApp.Properties.setValue("soundSet", $._mApp.soundSet);
		$._mApp.Properties.setValue("vibeSet", $._mApp.vibeSet);
		$._mApp.Properties.setValue("testTypeSet", $._mApp.testTypeSet);
		$._mApp.Properties.setValue("timerTimeSet", $._mApp.timerTimeSet);
		$._mApp.Properties.setValue("MaxTimerTimeSet", $._mApp.mMaxTimerTimeSet);
		$._mApp.Properties.setValue("ManualTimeSet", $._mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		$._mApp.Properties.setValue("bgColSet", $._mApp.bgColSet);
		$._mApp.Properties.setValue("lblColSet", $._mApp.lblColSet);
		$._mApp.Properties.setValue("txtColSet", $._mApp.txtColSet);
		$._mApp.Properties.setValue("hrvColSet", $._mApp.hrvColSet);
		$._mApp.Properties.setValue("avgHrvColSet", $._mApp.avgHrvColSet);
		$._mApp.Properties.setValue("pulseColSet", $._mApp.pulseColSet);
		$._mApp.Properties.setValue("avgPulseColSet", $._mApp.avgPulseColSet);	
		
	}
	
	function _CallSavePropProperty() {
		$._mApp.setProperty("timestampSet", $._mApp.timestampSet);
		$._mApp.setProperty("pFitWriteEnabled", $._mApp.mFitWriteEnabled);
		$._mApp.setProperty("pSensorSelect", $._mApp.mFitWriteEnabled);

		$._mApp.setProperty("soundSet", $._mApp.soundSet);
		$._mApp.setProperty("vibeSet", $._mApp.vibeSet);
		$._mApp.setProperty("testTypeSet", $._mApp.testTypeSet);
		$._mApp.setProperty("timerTimeSet", $._mApp.timerTimeSet);
		$._mApp.setProperty("MaxTimerTimeSet", $._mApp.mMaxTimerTimeSet);
		$._mApp.setProperty("ManualTimeSet", $._mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		$._mApp.setProperty("bgColSet", $._mApp.bgColSet);
		$._mApp.setProperty("lblColSet", $._mApp.lblColSet);
		$._mApp.setProperty("txtColSet", $._mApp.txtColSet);
		$._mApp.setProperty("hrvColSet", $._mApp.hrvColSet);
		$._mApp.setProperty("avgHrvColSet", $._mApp.avgHrvColSet);
		$._mApp.setProperty("pulseColSet", $._mApp.pulseColSet);
		$._mApp.setProperty("avgPulseColSet", $._mApp.avgPulseColSet);	

	}

	function resetResults() {
		// should only be called from settings - also called onStart()
		$._mApp.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			$._mApp.results[i] = 0;
		}
	}
	
	function retrieveResults() {
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			var mCheck = Storage.getValue("resultsArray");
			if (mCheck == null) {new $._mApp.myException("retrieveResults: no results array");}
			else {
				$._mApp.results = mCheck;
			} 
		} else {		
			for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
				var result = $._mApp.getProperty(RESULTS + i);
				var ii = i * DATA_SET_SIZE;
				if(null != result) {
					$._mApp.results[ii + 0] = result[0];
					$._mApp.results[ii + 1] = result[1];
					$._mApp.results[ii + 2] = result[2];
					$._mApp.results[ii + 3] = result[3];
					$._mApp.results[ii + 4] = result[4];
				}
			}
		}
	}
	
	function storeResults() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArray", $._mApp.results);
		} else {	
	    	for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
				var ii = i * DATA_SET_SIZE;
				var result = $._mApp.getProperty(RESULTS + i);
				if(null == result || $._mApp.results[ii] != result[0]) {
					$._mApp.setProperty(RESULTS + i, [
						$._mApp.results[ii + 0],
						$._mApp.results[ii + 1],
						$._mApp.results[ii + 2],
						$._mApp.results[ii + 3],
						$._mApp.results[ii + 4]]);
				}
			}
		}
	}
	
}

 