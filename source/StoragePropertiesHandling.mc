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

	var mApp;

	// setup storage functions	
    function initialize() {
    	mApp = App.getApp();
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
			mApp.Properties.setValue("pAuxHRAntID", 0);
			Storage.setValue("firstLoadEver", true);
			Storage.setValue("pFitWriteEnabled", false);
			mApp.Properties.setValue("soundSet", true);
			mApp.Properties.setValue("vibeSet", false);
			mApp.Properties.setValue("testTypeSet", 0);
			mApp.Properties.setValue("timerTimeSet", 300);
			mApp.Properties.setValue("MaxTimerTimeSet", 300);
			mApp.Properties.setValue("ManualTimeSet", 300);
			mApp.Properties.setValue("bgColSet", 3);
			mApp.Properties.setValue("lblColSet", 10);
			mApp.Properties.setValue("txtColSet", 13);
			mApp.Properties.setValue("hrvColSet", 10);
			mApp.Properties.setValue("avgHrvColSet", 12);
			mApp.Properties.setValue("pulseColSet", 13);
			mApp.Properties.setValue("avgPulseColSet", 6);
			mApp.Properties.setValue("inhaleTimeSet", 4);
			mApp.Properties.setValue("exhaleTimeSet", 4);
			mApp.Properties.setValue("relaxTimeSet", 2);				
		} else {
			mApp.setProperty("pAuxHRAntID", 0);
			mApp.setProperty("firstLoadEver", true);
			mApp.setProperty("pFitWriteEnabled", false);
			mApp.setProperty("soundSet", true);
			mApp.setProperty("vibeSet", false);
			mApp.setProperty("testTypeSet", 0);
			mApp.setProperty("timerTimeSet", 300);
			mApp.setProperty("MaxTimerTimeSet", 300);
			mApp.setProperty("ManualTimeSet", 300);
			mApp.setProperty("bgColSet", 3);
			mApp.setProperty("lblColSet", 10);
			mApp.setProperty("txtColSet", 13);
			mApp.setProperty("hrvColSet", 10);
			mApp.setProperty("avgHrvColSet", 12);
			mApp.setProperty("pulseColSet", 13);
			mApp.setProperty("avgPulseColSet", 6);
			mApp.setProperty("inhaleTimeSet", 4);
			mApp.setProperty("exhaleTimeSet", 4);
			mApp.setProperty("relaxTimeSet", 2);			
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
		//value = mApp.getProperty("firstLoadEver");
		//if (mDebugging == true) {value = null;}
			
		//if (value == null) {
		//	mApp.setProperty("firstLoadEver", true);
		//} else {
			// assumes all these values exist
			mApp.timestampSet = mApp.getProperty("timestampSet");
			mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			mApp.mFitWriteEnabled = mApp.getProperty("pFitWriteEnabled");
			mApp.soundSet = mApp.getProperty("soundSet");
			mApp.vibeSet = mApp.getProperty("vibeSet");
			mApp.testTypeSet = mApp.getProperty("testTypeSet").toNumber();
			mApp.timerTimeSet = mApp.getProperty("timerTimeSet").toNumber();
			mApp.mMaxTimerTimeSet = mApp.getProperty("MaxTimerTimeSet").toNumber();
			mApp.mManualTimeSet = mApp.getProperty("ManualTimeSet").toNumber();	      
			// ColSet are index into colour map
			mApp.bgColSet = mApp.getProperty("bgColSet").toNumber();
			mApp.lblColSet = mApp.getProperty("lblColSet").toNumber();
			mApp.txtColSet = mApp.getProperty("txtColSet").toNumber();
			mApp.hrvColSet = mApp.getProperty("hrvColSet").toNumber();
			mApp.avgHrvColSet = mApp.getProperty("avgHrvColSet").toNumber();
			mApp.pulseColSet = mApp.getProperty("pulseColSet").toNumber();
			mApp.avgPulseColSet = mApp.getProperty("avgPulseColSet").toNumber();
	
			mApp.inhaleTimeSet = mApp.getProperty("inhaleTimeSet").toNumber();
			mApp.exhaleTimeSet = mApp.getProperty("exhaleTimeSet").toNumber();
			mApp.relaxTimeSet = mApp.getProperty("relaxTimeSet").toNumber();	
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
			mApp.timestampSet = Storage.getValue("timestampSet");
			mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
			mApp.versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			mApp.mFitWriteEnabled = Storage.getValue("pFitWriteEnabled");
			mApp.soundSet = mApp.Properties.getValue("soundSet");
			mApp.vibeSet = mApp.Properties.getValue("vibeSet");
			mApp.testTypeSet = mApp.Properties.getValue("testTypeSet").toNumber();
			mApp.timerTimeSet = mApp.Properties.getValue("timerTimeSet").toNumber();
			mApp.mMaxTimerTimeSet = mApp.Properties.getValue("MaxTimerTimeSet").toNumber();
			mApp.mManualTimeSet = mApp.Properties.getValue("ManualTimeSet").toNumber();
	      
			// ColSet are index into colour map
			mApp.bgColSet = mApp.Properties.getValue("bgColSet").toNumber();
			mApp.lblColSet = mApp.Properties.getValue("lblColSet").toNumber();
			mApp.txtColSet = mApp.Properties.getValue("txtColSet").toNumber();
			mApp.hrvColSet = mApp.Properties.getValue("hrvColSet").toNumber();
			mApp.avgHrvColSet = mApp.Properties.getValue("avgHrvColSet").toNumber();
			mApp.pulseColSet = mApp.Properties.getValue("pulseColSet").toNumber();
			mApp.avgPulseColSet = mApp.Properties.getValue("avgPulseColSet").toNumber();	
			mApp.inhaleTimeSet = mApp.Properties.getValue("inhaleTimeSet").toNumber();
			mApp.exhaleTimeSet = mApp.Properties.getValue("exhaleTimeSet").toNumber();
			mApp.relaxTimeSet = mApp.Properties.getValue("relaxTimeSet").toNumber();	
		//}	
	}
	
	function _CallSavePropStorage() {
		Storage.setValue("timestampSet", mApp.timestampSet);
		Storage.setValue("pFitWriteEnabled", mApp.mFitWriteEnabled);
		
		// user changable
		mApp.Properties.setValue("soundSet", mApp.soundSet);
		mApp.Properties.setValue("vibeSet", mApp.vibeSet);
		mApp.Properties.setValue("testTypeSet", mApp.testTypeSet);
		mApp.Properties.setValue("timerTimeSet", mApp.timerTimeSet);
		mApp.Properties.setValue("MaxTimerTimeSet", mApp.mMaxTimerTimeSet);
		mApp.Properties.setValue("ManualTimeSet", mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		mApp.Properties.setValue("bgColSet", mApp.bgColSet);
		mApp.Properties.setValue("lblColSet", mApp.lblColSet);
		mApp.Properties.setValue("txtColSet", mApp.txtColSet);
		mApp.Properties.setValue("hrvColSet", mApp.hrvColSet);
		mApp.Properties.setValue("avgHrvColSet", mApp.avgHrvColSet);
		mApp.Properties.setValue("pulseColSet", mApp.pulseColSet);
		mApp.Properties.setValue("avgPulseColSet", mApp.avgPulseColSet);	
		mApp.Properties.setValue("inhaleTimeSet", mApp.inhaleTimeSet);
		mApp.Properties.setValue("exhaleTimeSet", mApp.exhaleTimeSet);
		mApp.Properties.setValue("relaxTimeSet", mApp.relaxTimeSet);			
	}
	
	function _CallSavePropProperty() {
		mApp.setProperty("timestampSet", mApp.timestampSet);
		mApp.setProperty("pFitWriteEnabled", mApp.mFitWriteEnabled);
		
		mApp.setProperty("soundSet", mApp.soundSet);
		mApp.setProperty("vibeSet", mApp.vibeSet);
		mApp.setProperty("testTypeSet", mApp.testTypeSet);
		mApp.setProperty("timerTimeSet", mApp.timerTimeSet);
		mApp.setProperty("MaxTimerTimeSet", mApp.mMaxTimerTimeSet);
		mApp.setProperty("ManualTimeSet", mApp.mManualTimeSet);
      
		// ColSet are index into colour map
		mApp.setProperty("bgColSet", mApp.bgColSet);
		mApp.setProperty("lblColSet", mApp.lblColSet);
		mApp.setProperty("txtColSet", mApp.txtColSet);
		mApp.setProperty("hrvColSet", mApp.hrvColSet);
		mApp.setProperty("avgHrvColSet", mApp.avgHrvColSet);
		mApp.setProperty("pulseColSet", mApp.pulseColSet);
		mApp.setProperty("avgPulseColSet", mApp.avgPulseColSet);	
		mApp.setProperty("inhaleTimeSet", mApp.inhaleTimeSet);
		mApp.setProperty("exhaleTimeSet", mApp.exhaleTimeSet);
		mApp.setProperty("relaxTimeSet", mApp.relaxTimeSet);	
	}

	function resetResults() {
		// should only be called from settings
		mApp.results = new [NUM_RESULT_ENTRIES * DATA_SET_SIZE];

		for(var i = 0; i < (NUM_RESULT_ENTRIES * DATA_SET_SIZE); i++) {
			mApp.results[i] = 0;
		}
	}
	
	function retrieveResults() {
		// currently references a results array in HRVApp
		if (Toybox.Application has :Storage) {
			var mCheck = Storage.getValue("resultsArray");
			if (mCheck == null) {new mApp.myException("retrieveResults: no results array");}
			else {
				mApp.results = mCheck;
			} 
		} else {		
			for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
				var result = mApp.getProperty(RESULTS + i);
				var ii = i * DATA_SET_SIZE;
				if(null != result) {
					mApp.results[ii + 0] = result[0];
					mApp.results[ii + 1] = result[1];
					mApp.results[ii + 2] = result[2];
					mApp.results[ii + 3] = result[3];
					mApp.results[ii + 4] = result[4];
				}
			}
		}
	}
	
	function storeResults() {
	    // Save results to memory
	    if (Toybox.Application has :Storage) {
			Storage.setValue("resultsArray", mApp.results);
		} else {	
	    	for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
				var ii = i * DATA_SET_SIZE;
				var result = mApp.getProperty(RESULTS + i);
				if(null == result || mApp.results[ii] != result[0]) {
					mApp.setProperty(RESULTS + i, [
						mApp.results[ii + 0],
						mApp.results[ii + 1],
						mApp.results[ii + 2],
						mApp.results[ii + 3],
						mApp.results[ii + 4]]);
				}
			}
		}
	}
	
}

 