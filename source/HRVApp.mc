using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties as Property;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.System as Sys;
using Toybox.Sensor;

// we should be saving results to storage NOT properties
//Storage.setValue( tag, value) eg ("results_array", results); where results is an array

// home page timer placement needs fixing if >1hr...

// Things still to fix
//2. Need to make sure any Delegate Pop's view when done
//3. check initialisation of storage and properties on first run to avoid null on read
//8. sample processing check skipped or double beats
//8b. Look at frequency domain processing
//9. how to make trial version and possible payment
//10. Test sensor switching more
//13. When using optical should call it PRV not HRV
//17. Check download and setting online properties works
//21. Change nore layouts to % and see if works on 260/240 displays
//18. Poincare view sometimes has y=0 and hence rectangle is drawn below axis
// Optimisations:
// - check no string assignment in loops. Use Lang.format()
// - remove unwanted test messages
// - any more local vars rather than global
// - reduce dictionaries 

// Trial end point (of URL) requirements seems not to be published!!


var mDebugging = false;
var mDebuggingANT = false;
var mDumpIntervals = true;
// dump results array on every call to view history
var mDebuggingResults = false;

// access App variables and classes
var _mApp;

using Toybox.Lang;

class myException extends Lang.Exception {
    function initialize(message) {
    	Sys.println(message);
        Exception.initialize();
		//Exception.printStackTrace;
    }
}

class HRVApp extends App.AppBase {

    // The device type
	var device;
	var mApp;
	var mSensor;
	var mAntID;
	// true if external unknown strap ie not enabled in watch
	var mSensorTypeExt;
	
	// Trial mode variables!!
	hidden var mTrialMode;
	hidden var mTrialStarted;
	hidden var mAuthorised;
	hidden var mTrailPeriod;
	hidden var mTrialStartDate; 
	hidden var mAuthID;

	// Settings variables
    var timestampSet;
	var appNameSet;
	var versionSet;

	var soundSet;
	var vibeSet;
	var testTypeSet;
	var timerTimeSet;
	var mManualTimeSet;
	var mMaxTimerTimeSet;
	var bgColSet;
	var lblColSet;
    var txtColSet;
	var Label1ColSet;
	var Label3ColSet;
	var Label2ColSet;
	
	var mMenuTitleSize;
	var mDeviceID;

	// Results array variable
	var results;
	var mHistorySelectFlags;
	// write pointer into results array
	var resultsIndex;

	// View trackers
	var viewNum;
	var lastViewNum;

	var mFitWriteEnabled;   
    var mStorage;
    var mTestControl;
    var mIntervalSampleBuffer; // buffer in app space for intervals
    var mSampleProc; // instance of sample processor
    var mFitControl;
    
    // ensure second update
    hidden var _uiTimer;
    const UI_UPDATE_PERIOD_MS = 1000;
    
    // Block size for dump to debug of intervals
    const BLOCK_SIZE = 40;
    
    function initialize() {
    	Sys.println("HRVApp INITIALISATION called");
        
        $._mApp = App.getApp();
         
        mStorage = new HRVStorageHandler();
        mTestControl = new TestController();
        mSampleProc = new SampleProcessing();
        mStorage.readProperties();  
               
		//A unique alphanumeric device identifier.
		//The value is unique for every app, but is stable on a device across uninstall and reinstall. 
		//Any use of this value for tracking user information must be in compliance with international privacy law.
		var mySettings = Sys.getDeviceSettings();
        mDeviceID = mySettings.uniqueIdentifier;
             
		if (Toybox.Application has :Storage) {
			mAntID = $._mApp.Properties.getValue("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);	
			mFitWriteEnabled = $._mApp.Properties.getValue("pFitWriteEnabled"); 
			mSensorTypeExt = $._mApp.Properties.getValue("pSensorSelect");	
			
			// load trial variables
			mTrialMode = $._mApp.Properties.getValue("pTrialMode");
			mTrialStarted = $._mApp.Properties.getValue("pTrialStarted");
			mAuthorised = $._mApp.Properties.getValue("pAuthorised");
			mTrailPeriod = $._mApp.Properties.getValue("pTrailPeriod");
			mTrialStartDate = $._mApp.Properties.getValue("pTrialStartDate");
			
			$._mApp.Properties.setValue("pDeviceID", mDeviceID);
			// code to authenticate device with given DeviceID
			mAuthID = $._mApp.Properties.getValue("pAuthID");
				
		} else {
			mAntID = $._mApp.getProperty("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			mFitWriteEnabled = $._mApp.getProperty("pFitWriteEnabled");
			mSensorTypeExt = $._mApp.getProperty("pSensorSelect");
			
			// load trial variables
			mTrialMode = $._mApp.getProperty("pTrialMode");
			mTrialStarted = $._mApp.getProperty("pTrialStarted");
			mAuthorised = $._mApp.getProperty("pAuthorised");
			mTrailPeriod = $._mApp.getProperty("pTrailPeriod");
			mTrialStartDate = $._mApp.getProperty("pTrialStartDate");
			
			$._mApp.Properties.setProperty("pDeviceID", mDeviceID);
			mAuthID = $._mApp.getProperty("pAuthID");
		}
		
		Sys.println("HRVApp: ANT ID set to : " + mAntID);
		Sys.println("HRVApp: SensorType = "+mSensorTypeExt);
		Sys.println("Is app in trial mode? "+AppBase.isTrial());
		Sys.println("Trial properties: "+mTrialMode+","+mTrialStartDate+","+mTrialStarted+","+mAuthorised+","+mTrailPeriod);
				
		//Menu title size
		mMenuTitleSize = Ui.loadResource(Rez.Strings.MenuTitleSize).toNumber();	
		
		// no history selected. binary flags as bits
		// set default selection
		// Note array 0 entry is time stamp
		mHistorySelectFlags = (1 << (AVG_PULSE_INDEX-1));
		mHistorySelectFlags |= (1 << (RMSSD_INDEX-1));
		mHistorySelectFlags |= (1 << (LNRMSSD_INDEX-1));		
						
    	AppBase.initialize();
    }
    
    function getTrialDaysRemaining() {
    	// days remaining or null if trials not supported or 0 to disable app
    	Sys.println("getTrailDaysRemaining() called");
    	return 30;
    }
 
 	function allowTrialMessage() {
 		// return false if you want no reminders
 		Sys.println("allowTrialMessage() called");
 		return false;
 	}

    //! Return the initial view of your application here
    function getInitialView() {
    		    
    	if (mDebugging) { Sys.println("HRVApp: getInitialView() called"); }   	
    	viewNum = 0;
		lastViewNum = 0;
		return [ new TestView(), new HRVBehaviourDelegate() ];
    }
    
    //! onStart() is called on application start up
    function onStart(state) {
		// Retrieve device type
		device = Ui.loadResource(Rez.Strings.Device).toNumber();

   		// Start up HR sensor. Create the sensor object and open it
	   	mSensor = new SensorHandler(mAntID, mSensorTypeExt);

	   	Sys.println("HRVApp: onStart() Sensor set to "+mSensorTypeExt);
	   	
	   	// now setup sensors as have created data structures
	   	mSensor.SetUpSensors();
	    
	    if (mDebugging) {
	    	Sys.println("HRVApp: sensor created: " + mSensor);
	    	Sys.println("HRVApp: Sensor channel open? " + mSensor.mHRData.isChOpen);
	    }

    	if(VIVOACTIVE == device) {
    	 	soundSet = false;
    	}

		// Retrieve saved results from memory
		// create and clear buffer - only one set per day
		mStorage.resetResults();
		//restore previous results from properties/store		
		mStorage.retrieveResults();
		// initialise for testing
		mTestControl.resetTest();
		
		// strictly speaking no need to create FIT contributor unless we want to write
		// however we then lose all the functions
		mFitControl = new HRVFitContributor();

    	// Init view variables
		viewNum = 0;
		lastViewNum = 0;

		// Init timers
		_uiTimer = new Timer.Timer();
		_uiTimer.start(method(:updateScreen), UI_UPDATE_PERIOD_MS, true);		
    }
    
    //! A wrapper function to allow the timer to request a screen update
    function updateScreen() {
    	// drive teststate transitions outside UI
    	mTestControl.StateMachine(:UpdateUI);
    	
    	// Update FIT data
    	mFitControl.compute();
    	
    	// update views
        Ui.requestUpdate();
    }
    
    //! onStop() is called when your application is exiting
    function onStop(state) {		
		if (state == null) { 		}
	
		mStorage.saveProperties();
		mTestControl.stopTest();
		_uiTimer.stop();
		
		// Dump all interval data to txt file on device
		if (mDumpIntervals == true) {DumpIntervals();}
		
		Sys.println("App stopped");
    }
    
   	// App running and Garmin Mobile has changed settings
	function onSettingsChanged() {
		// update any things depending on storage functions
		mStorage.onSettingsChangedStore();	
		Ui.requestUpdate();
	}

    function plusView() {
    	var plusView = (viewNum + 1) % NUM_VIEWS;
    	return getView(plusView);
    }

    function lastView() { return getView(lastViewNum); }

    function subView() {
    	var subView = (viewNum + NUM_VIEWS - 1) % NUM_VIEWS;
    	return getView(subView);
    }

    function getView(newViewNum) {
    	lastViewNum = viewNum;
		viewNum = newViewNum;
		
		//Sys.println("Last view: " + lastViewNum + " current: " + viewNum);

		if(SUMMARY_VIEW == viewNum) {
			return new SummaryView();
		}
		else if(HISTORY_VIEW == viewNum) {
			return new HistoryView();
		}
		else if(CURRENT_VIEW == viewNum) {
			return new CurrentValueView();
		}
		else if(POINCARE_VIEW == viewNum) {
			return new PoincareView();
		}	
		else {
			return new TestView();
		}
	}
	
	function DumpIntervals() {
		// to reduce write time group up the data
		Sys.println("Dumping intervals");
		
		var mNumEntries = mSampleProc.getNumberOfSamples();
		var mNumBlocks = mNumEntries / BLOCK_SIZE ;
		var mRemainder = mNumEntries % BLOCK_SIZE ;
		var mString = "";
		var i;
		var base;
		
		if (mNumEntries <= 0) { return;}
		
		//if (mDebugging == true) {
			Sys.println("DumpIntervals: mNumEntries, blocks, remainder: " + mNumEntries+","+ mNumBlocks+","+ mRemainder);				
		//}
		
		// should propably use getSample(index) if using circular buffer
		var separator = ",";
		for (i=0; i < mNumBlocks; i++) {
			base = i*BLOCK_SIZE;
			var j;
			for (j=0; j< BLOCK_SIZE; j++) {
				mString += mIntervalSampleBuffer[base+j].toString()+separator;			
			}
			Sys.println(mString);
			mString = "";		
		}
		mString = "";
		// Write tail end of buffer
		base = BLOCK_SIZE * mNumBlocks;
		for (i=0; i < mRemainder; i++) {	
			mString += mIntervalSampleBuffer[base+i].toString()+separator;				
		}	
		Sys.println(mString);
	}
	
}


