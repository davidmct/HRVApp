using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties as Property;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.System as Sys;
using Toybox.Sensor;


// Things still to fix
//3. check initialisation of storage and properties on first run to avoid null on read
//8. sample processing check skipped or double beats
//8b. Look at frequency domain processing
//9. Do timer on trial mode and disable for now?
//13. When using optical should call it PRV not HRV
//17. Check download and setting online properties works
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

class HRVAnalysis extends App.AppBase {

    // The device type
	var mDeviceType;
	var mApp;
	var mSensor;
	var mAntID;
	// true if external unknown strap ie not enabled in watch
	var mSensorTypeExt;
	
	// try only one creation of a view - consumes more memory as multiple views saved
	//hidden var mPoincare_view;
	//hidden var mSummaryView;
	//hidden var mHistoryView;
	//hidden var mCurrentView;
	//hidden var mTestView;
	
	// Trial mode variables!!
	hidden var mTrialMode;
	hidden var mTrialStarted;
	hidden var mAuthorised;
	hidden var mTrailPeriod;
	hidden var mTrialStartDate; 
	hidden var mAuthID;
	hidden var mTrialMessage;

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

(:storageMethod)    
    function initializeWithStorage() {
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
    }
 
 (:preCIQ24)   
    function initializeNoStorage() {
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
    
(:storageMethod)    
    function saveTrialWithStorage() {		
		// save trial variables
		$._mApp.Properties.setValue("pTrialStarted", mTrialStarted);
		$._mApp.Properties.setValue("pAuthorised", mAuthorised );
		$._mApp.Properties.setValue("pTrialStartDate", mTrialStartDate);
		      
    }
 
 (:preCIQ24)   
    function saveTrialNoStorage() {
		$._mApp.setProperty("pTrialStarted", mTrialStarted);
		$._mApp.setProperty("pAuthorised", mAuthorised );
		$._mApp.setProperty("pTrialStartDate", mTrialStartDate );   
    }    
 
 	function checkAuth(AutorisationID, DeviceIdentification) {
 		return false; //true;
 	}
 	 
    function UpdateTrialState() {
 		//Sys.println("Trial properties: "+mTrialMode+","+mTrialStartDate+","+mTrialStarted+","+mAuthorised+","+mTrailPeriod);  
 		Sys.println("UpdateTrialState() called");
 		mTrialMessage = true;
 		Sys.println("updateTrial State mAuthorised = "+mAuthorised); 		
 		if (checkAuth(mAuthID, mDeviceID) == true) {
 			mAuthorised = true;
 			mTrialMessage = false;
 		}
 		Sys.println("updateTrial State mAuthorised = "+mAuthorised);
 		if (mAuthorised) {
 			// good to go
 			mTrialMode = false;
 			mTrialStarted = false;
 			mTrialMessage = false;
 		} else if (!mTrialStarted && mTrialMode) {
    		// initialise trial and save properties
    		mTrialStartDate = Time.now() + System.getClockTime().timeZoneOffset;
    		mTrialStarted = true;
    	} else if ( mTrialStarted && mTrialMode ) {
    		// started and in trial mode

    	}
    	
  		// update properties store
    	if (Toybox.Application has :Storage) {
			saveTrialWithStorage();				
		} else {
			saveTrialNoStorage();
		}
    	Sys.println("exit updateTrial State mAuthorised = "+mAuthorised);
    }
    
    function getTrialDaysRemaining() {
    	// days remaining or null if trials not supported or 0 to disable app
    	return null;
    	
  		var daysToGo;  	
     	if (mAuthorised) {
 			// good to go
 			Sys.println("getTrailDaysRemaining() called, returned : null");
 			return null;
 		} else if (!mTrialStarted && mTrialMode) {
    		// initialise trial and save properties
    		Sys.println("getTrailDaysRemaining() called, returned : 30");
    		return 30;
    	} else if ( mTrialStarted && mTrialMode ) {
    		// started and in trial mode 	
    		var timeDiff = Time.now() + System.getClockTime().timeZoneOffset - mTrialStartDate;    	
    		daysToGo = 30 - timeDiff / 86400;
	
    		Sys.println("getTrailDaysRemaining() called, returned :"+daysToGo.toNumber());
    		return daysToGo.toNumber();
    	} else {
    		return 30;
    	}
    }
 
 	function allowTrialMessage() {
 		// return false if you want no reminders
 		Sys.println("allowTrialMessage() called");
 		return false; //mTrialMessage;
 	}
    
    
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
			initializeWithStorage();				
		} else {
			initializeNoStorage();
		}
		
		Sys.println("HRVApp: ANT ID set to : " + mAntID);
		Sys.println("HRVApp: SensorType = "+mSensorTypeExt);
		Sys.println("Is app in trial mode? "+AppBase.isTrial());
		Sys.println("Trial properties: "+mTrialMode+","+mTrialStartDate+","+mTrialStarted+","+mAuthorised+","+mTrailPeriod);
		
		//UpdateTrialState();
				
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
		mDeviceType = Ui.loadResource(Rez.Strings.Device).toNumber();

   		// Start up HR sensor. Create the sensor object and open it
	   	mSensor = new SensorHandler(mAntID, mSensorTypeExt);

	   	Sys.println("HRVApp: onStart() Sensor set to "+mSensorTypeExt);
	   	
	   	// now setup sensors as have created data structures
	   	mSensor.SetUpSensors();
	    
	    if (mDebugging) {
	    	Sys.println("HRVApp: sensor created: " + mSensor);
	    	Sys.println("HRVApp: Sensor channel open? " + mSensor.mHRData.isChOpen);
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
		viewNum = TEST_VIEW;
		lastViewNum = TEST_VIEW;

		// Init timers
		_uiTimer = new Timer.Timer();
		_uiTimer.start(method(:updateScreen), UI_UPDATE_PERIOD_MS, true);	
		
		// create views .. rather than every time view is called
		// only issue might be initialisation each time
		//mPoincare_view = new PoincareView();	
		//mSummaryView = new SummaryView();
		//mHistoryView = new HistoryView();
		//mCurrentView = new CurrentValueView();
		//mTestView = new TestView();
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
		Sys.println("Settings changed on connect");
		// DO NOTHING AT MOMENT - next restart will impact
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
		
		var mNumEntries = mSampleProc.getNumberOfSamples();
		var mNumBlocks = mNumEntries / BLOCK_SIZE ;
		var mRemainder = mNumEntries % BLOCK_SIZE ;
		var mString = "";
		var i;
		var base;
		
		if (mNumEntries <= 0) { return;}
		Sys.println("Dumping intervals");
		
		//if (mDebugging == true) {
		//	Sys.println("DumpIntervals: mNumEntries, blocks, remainder: " + mNumEntries+","+ mNumBlocks+","+ mRemainder);				
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


