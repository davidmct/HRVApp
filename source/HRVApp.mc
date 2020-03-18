using Toybox.Application as App;
using Toybox.Application.Storage as Store;
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
//4. Update ANT logic and interface
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
	//test
	// Settings memory locations
	TIMESTAMP = 0,
	APP_NAME = 1,
	VERSION = 2,
	GREEN_TIME = 5,
	SOUND = 6,
	VIBE = 7,
	TEST_TYPE = 8,
	TIMER_TIME = 9,
	AUTO_START = 10,
	AUTO_TIME = 11,
	BG_COL = 12,
	LABEL_COL = 13,
	TEXT_COL = 14,

	HRV_COL = 15,		// Not applied yet
	AVG_HRV_COL = 16,	// Not applied yet
	PULSE_COL = 17,		// Not applied yet
	AVG_PULSE_COL = 18,	// Not applied yet

	INHALE_TIME = 20,
	EXHALE_TIME = 21,
	RELAX_TIME = 22,
	
	INITIAL_RUN = 23,

	// Results memory locations. (X) <> (X + 29)
	RESULTS = 100,

	// Tones
	TONE_KEY = 0,
	TONE_START = 1,
	TONE_STOP = 2,
	TONE_RESET = 9,
	TONE_FAILURE = 14,
	TONE_SUCCESS = 15,
	TONE_ERROR = 18,

	// Test types
	TYPE_TIMER = 0,
	TYPE_MANUAL = 1,
	TYPE_AUTO = 2,

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

	// Test minimum
	MIN_SAMPLES = 20

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

	var greenTimeSet;
	var soundSet;
	var vibeSet;
	var testTypeSet;
	var timerTimeSet;
	var mMaxTimerTimeSet;
	var autoStartSet;
	var autoTimeSet;
	var mMaxAutoTimeSet;
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
	var isSeconds;
	var isMinutes;

	var utcStart;
	var utcStop;

	var startMoment;
	//var stopMoment;

    var timeAutoStart;
    var timerTime;
    
    var mStorage;

    hidden var greenTimer;
    hidden var viewTimer;
    hidden var testTimer;
    const UI_UPDATE_PERIOD_MS = 1000;
    // ensure second update
    hidden var _uiTimer;
    
    function initialize() {
    	Sys.println("HRVApp initialisation called RUN 7");
        mApp = App.getApp();
        mAntID = mApp.getProperty("pAuxHRAntID");
        mStorage = new HRVStorageHandler();
        // could possibly call in initialize func in class
        mStorage.resetSettings();
    	AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
    	if (mDebugging) {
    		Sys.println("getInitialView() called");
    	}
    	viewNum = 0;
		lastViewNum = 0;
		return [ new TestView(), new HRVBehaviourDelegate() ];
    }
    
    //! onStart() is called on application start up
    function onStart(state) {
		// Retrieve device type
		device = Ui.loadResource(Rez.Strings.Device).toNumber();
		// Retrieve saved settings from memory	
		mStorage.readProperties();

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
    	 	soundSet = 0;
    	}

		// Retrieve saved results from memory
		mStorage.resetResults();		
		mStorage.loadResults();

		// Init test variables
		resetTest();
		startMoment = 0;
    	timeAutoStart = 0;
    	timerTime = 0;

    	// Init view variables
		viewNum = 0;
		lastViewNum = 0;

		isClosing = false;
		isSeconds = false;
		isMinutes = false;

		// Init timers
    	greenTimer = new Timer.Timer();
		viewTimer = new Timer.Timer();
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

		if (state == null) {
		//???
		
		}
    	// Close ant channel
		mSensor.closeCh();		
		mStorage.saveProperties();
		mStorage.saveResults();

		greenTimer.stop();
		viewTimer.stop();
		testTimer.stop();
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
    	resetGreenTimer();
    }

    function endTest() {
    	testTimer.stop();
    	if(isWaiting) {
			isWaiting = false;
			if(!mSensor.mHRData.isChOpen) {
				mSensor.openCh();
			}
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
		Sys.println("stopped code");
		//return;
		
		testTimer.stop();	// This is in case user has changed test type while waiting
    	var testType = testTypeSet;
    	if(TYPE_MANUAL != testType){
			if(TYPE_AUTO == testType) {
				// Auto wait
				if(!isWaiting) {
					timeAutoStart = timeToday() + autoStartSet;
					timerTime = autoTimeSet;
					if(timeAutoStart < timeNow()) {
						timeAutoStart += 86400;
					}
					isWaiting = true;
					if(mSensor.mHRData.isChOpen) {
						mSensor.closeCh();
					}
					testTimer.start(method(:start),(timeAutoStart - timeNow())*1000,false); // false
					return;
				}
				else {
					isWaiting = false;
					if(!mSensor.mHRData.isChOpen) {
						mSensor.openCh();
					}
					testTimer.start(method(:autoFinish),timerTime*1000,true); // true
				}
			}
			// Timer start
			else {
				timerTime = timerTimeSet;
				testTimer.start(method(:finishTest),timerTime*1000,false); // false
			}
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

    function resetGreenTimer() {
		greenTimer.stop();
		greenTimer.start(method(:startGreenMode),greenTimeSet*1000,true);
    }

    function stopGreenTimer() {
    	greenTimer.stop();
    }

    function startGreenMode() {
    	if(!isTesting && mSensor.mHRData.isChOpen) {
    		mSensor.closeCh();
    	}
    	if(WATCH_VIEW != viewNum) {
    		Ui.switchToView(getView(WATCH_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_LEFT);
    	}
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

    function stopViewTimer() {

    	viewTimer.stop();
    	isMinutes = false;
	    isSeconds = false;
    }

    function updateMinutes() {

    	if(!isMinutes) {
	    	viewTimer.stop();
	    	var sec = System.getClockTime().sec;
			var ms;
			if(0 == sec) {
	    		ms = 60000;
	    	}
	    	else {
	    		ms = 60000 - sec * 1000;
	    	}
	    	viewTimer.start(method(:updateSynced),ms,false);
	    	isMinutes = true;
	    	isSeconds = false;
    	}
    	Ui.requestUpdate();
    }

    function updateSeconds() {

    	if(!isSeconds) {
    		viewTimer.stop();
    		viewTimer.start(method(:onViewTimer),1000,true);
    		isSeconds = true;
    		isMinutes = false;
    	}
    	Ui.requestUpdate();
    }

    function updateSynced() {

    	viewTimer.stop();
    	viewTimer.start(method(:onViewTimer),60000,true);
    	Ui.requestUpdate();
    }

    function onViewTimer() {

    	Ui.requestUpdate();
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

    function lastView() {
    	return getView(lastViewNum);
    }

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


