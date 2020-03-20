using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties as Property;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.System as Sys;

// we should be saving results to storage NOT properties
//Storage.setValue( tag, value) eg ("results_array", results); where results is an array

// home page timer placement needs fixing if >1hr...

// Things still to fix
//1. Confirmation dialogue still old style
//2. Need to make sure any Delegate Pop's view when done
//3. Set up properties and storage
//5. Redo HRV measurements and fix graph
//6. Add poincare view

var mDebugging = true;

using Toybox.Lang;

class myException extends Lang.Exception {
    function initialize(message) {
    	Sys.println(message);
        Exception.initialize();
    }
}

enum {
	// Tones
	TONE_KEY = 0,
	TONE_START = 1,
	TONE_STOP = 2,
	TONE_RESET = 9,
	TONE_FAILURE = 14,
	TONE_SUCCESS = 15,
	TONE_ERROR = 18,

	// Test types
	TYPE_MANUAL = 0, // runs as long as useer wants up to max time
	TYPE_TIMER = 1,  // defaults to 5 mins and can be changed down or to max-time

	// Device types
	EPIX = 0,
	FENIX = 1,
	FORERUNNER = 2,
	VIVOACTIVE = 3,
	FENIX6 = 4,

	// Views
	TEST_VIEW = 0,
	RESULT_VIEW = 1,
	GRAPH_VIEW = 2,
	WATCH_VIEW = 3,
	POINCARE_VIEW = 4,
	NUM_VIEWS = 5,
}

class HRVApp extends App.AppBase {

    // The device type
	var device;
	var mApp;
	var mSensor;
	var mAntID;

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
	var hrvColSet;
	var avgHrvColSet;
	var pulseColSet;
	var avgPulseColSet;

	var inhaleTimeSet;
	var exhaleTimeSet;
	var relaxTimeSet;

	// Results array variable
	var results;

	// View trackers
	var viewNum;
	var lastViewNum;

	// App states
	var isWaiting;
	var isTesting;
	var isFinished;
	var isNotSaved;
	var isSaved;
	var isClosing;
	var mFitWriteEnabled;

	var utcStart;
	var utcStop;

	var startMoment;
	//var stopMoment;

    var timerTime;
    
    var mStorage;

    hidden var testTimer;
    const UI_UPDATE_PERIOD_MS = 1000;
    
    // ensure second update
    hidden var _uiTimer;
    
    function initialize() {
    	if (mDebugging) { 	Sys.println("HRVApp initialisation called");}
        
        mApp = App.getApp();
        
		if (Toybox.Application has :Storage) {
			mAntID = mApp.Properties.getValue("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);			
		} else {
			mAntID = mApp.getProperty("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);
		}
		Sys.println("ANT ID set to : " + mAntID);
		
        mStorage = new HRVStorageHandler();
        mStorage.readProperties();
    	AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	if (mDebugging) { Sys.println("getInitialView() called"); }
    	
    	viewNum = 0;
		lastViewNum = 0;
		return [ new TestView(), new HRVBehaviourDelegate() ];
    }
    
    //! onStart() is called on application start up
    function onStart(state) {
		// Retrieve device type
		device = Ui.loadResource(Rez.Strings.Device).toNumber();

   		// Start up ANT device
	    try {
	    	//Create the sensor object and open it
	   		mSensor = new AntHandler(mAntID);
	    	//mSensor.openCh();
	    } catch(e instanceof Ant.UnableToAcquireChannelException) {
	    	System.println(e.getErrorMessage());
	   		mSensor = null;
	    }
	    
	    if (mDebugging) {
	    	Sys.println("AUX sensor created: " + mSensor);
	    	Sys.println("Sensor channel open? " + mSensor.mHRData.isChOpen);
	    }

    	if(VIVOACTIVE == device) {
    	 	soundSet = false;
    	}

		// Retrieve saved results from memory
		// clear buffer
		mStorage.resetResults();
		//restore previous results from properties/store		
		mStorage.retrieveResults();

		// Init test variables
		resetTest();
		startMoment = 0;
    	timerTime = 0;

    	// Init view variables
		viewNum = 0;
		lastViewNum = 0;

		isClosing = false;

		// Init timers
		testTimer = new Timer.Timer();
		_uiTimer = new Timer.Timer();
		_uiTimer.start(method(:updateScreen), UI_UPDATE_PERIOD_MS, true);
		
    }
    
    //! A wrapper function to allow the timer to request a screen update
    function updateScreen() {
        Ui.requestUpdate();
    }
    
    //! onStop() is called when your application is exiting
    function onStop(state) {

		if (state == null) { 		}
	
		mStorage.saveProperties();
		mStorage.storeResults();

		testTimer.stop();
		
		Sys.println("App stopped");
    }
    
   	// App running and Garmin Mobile has changed settings
	function onSettingsChanged() {
		// update any things depending on storage functions
		mStorage.onSettingsChangedStore();	
		Ui.requestUpdate();
	}

    function startTest() {
    	alert(TONE_START);
    	start();
    }

    function stopTest() {
    	endTest();
		alert(TONE_STOP);
    }

    function finishTest() {
    	endTest();
    	alert(TONE_SUCCESS);
    }

    function autoFinish() {
    	endTest();
    	saveTest();
    }

    function endTest() {
    	testTimer.stop();
    	if(isWaiting) {
			isWaiting = false;
			//if(!mSensor.mHRData.isChOpen) {
			//	mSensor.openCh();
			//}
		}
		else {
			isTesting = false;
			isFinished = true;
			isNotSaved = true;
			utcStop = timeNow();
		}
    }

    function discardTest() {
    	isNotSaved = false;
    }

    function resetTest() {
    	mSensor.mHRData.resetTestVariables();
		utcStart = 0;
		utcStop = 0;
		isWaiting = false;
		isTesting = false;
		isFinished = false;
		isNotSaved = false;
		isSaved = false;
    }

    function start() {
		Sys.println("Start: entered");
		
		testTimer.stop();	// This is in case user has changed test type while waiting
    	var testType = testTypeSet;
    	
    	// isWaiting is unused now I think
    	isWaiting = false;
    	isTesting = true;  
    				
    	if(TYPE_MANUAL == testType){
 			// kick off a timer for period of test
 			
 			var x = mManualTimeSet;
 			
    		timerTime = timerTimeSet;
			testTimer.start(method(:finishTest),mMaxTimerTimeSet,false); // false
 		
    	
    	} else {
    		// kick off a timer for period of test
    		timerTime = timerTimeSet;
			testTimer.start(method(:finishTest),timerTime*1000,false); // false
		}

		// Common start
		startMoment = Time.now();
		//utcStart = timeNow();
		utcStart = startMoment.value() + System.getClockTime().timeZoneOffset;
		isTesting = true;

		// Print live data
		//var date = Calendar.info(startMoment, 0);
    	//System.println(format("$1$-$2$-$3$ $4$:$5$:$6$",[
    	//	date.year,
    	//	date.month,
    	//	date.day,
    	//	date.hour,
    	//	date.min.format("%02d"),
    	//	date.sec.format("%02d")]));
    	Sys.println("Start: leaving func");
    }

    function timerFormat(time) {
    	var hour = time / 3600;
		var min = (time / 60) % 60;
		var sec = time % 60;
		if(0 < hour) {
			return format("$1$:$2$:$3$",[hour.format("%01d"),min.format("%02d"),sec.format("%02d")]);
		}
		else {
			return format("$1$:$2$",[min.format("%01d"),sec.format("%02d")]);
		}
    }

	function clockFormat(time) 	{
		var hour = (time / 3600) % 24;
		var min = (time / 60) % 60;
		var sec = time % 60;
		var meridiem = "";
		if(System.getDeviceSettings().is24Hour) {
			if(0 == time) {
				hour = 24;
			}
			else {
				hour = hour % 24;
			}
			return format("$1$$2$",[hour.format("%02d"),min.format("%02d")]);
		}
		else {
			if(12 > hour) {
				meridiem = "AM";
			}
			else {
				meridiem = "PM";
			}
			hour = 1 + (hour + 11) % 12;
			return format("$1$:$2$:$3$ $4$",[hour.format("%01d"),
				min.format("%02d"),sec.format("%02d"),meridiem]);
		}
	}

	function alert(type)
	{
    	if(soundSet) {
    		Attention.playTone(type);
    	}
    	if(vibeSet) {
    		Attention.vibrate([new Attention.VibeProfile(100,400)]);
    	}
    }

    function timeNow() {
    	return (Time.now().value() + System.getClockTime().timeZoneOffset);
    }

    function timeToday() {
    	return (timeNow() - (timeNow() % 86400));
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
		
		Sys.println("Last view: " + lastViewNum + " current: " + viewNum);

		if(RESULT_VIEW == viewNum) {
			return new ResultView();
		}
		else if(GRAPH_VIEW == viewNum) {
			return new GraphView();
		}
		else if(WATCH_VIEW == viewNum) {
			return new WatchView();
		}
		else if(POINCARE_VIEW == viewNum) {
			return new PoincareView();
		}
		else {
			return new TestView();
		}
	}
}


