//
// Copyright 2020 David McTernan
// 
// Test control logic

// Attempt to use Model-View-Controller structure
// push Model information into StoragePropertiesHandling file
// This converts user input in to model commands or view updates
// data model should accept commands
// views should register for change notifications if needed

using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties as Property;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.System as Sys;


enum {
	// Tones
	TONE_KEY = 0,
	TONE_START = 1,
	TONE_STOP = 2,
	TONE_RESET = 9,
	TONE_FAILURE = 14,
	TONE_SUCCESS = 15,
	TONE_ERROR = 18,

	//Test types
	TYPE_MANUAL = 0,  //runs as long as useer wants up to max time
	TYPE_TIMER = 1,   // to 5 mins and can be changed down or to max-time
}	

class TestController {

	var timerTime;	
	hidden var testTimer;
	var mState;
	var utcStart;
	var utcStop;	 
	var startMoment;
	//var stopMoment;
	hidden var mApp;
	hidden var mFunc;
	    
	class cTestState {
		// App states
		var isWaiting;
		var isTesting;
		var isFinished;
		var isNotSaved;
		var isSaved;
		var isClosing;
	
		function initialize() {
			isWaiting = false;
			isTesting = false;
			isFinished = false;
			isNotSaved = false;
			isSaved = false;
			isClosing = false;		
		}
	}

	function initialize() {
		mApp = App.getApp();
		mState = new cTestState();
		testTimer = new Timer.Timer();
		mState.isClosing = false;
		
		// Init test variables
		startMoment = 0;
    	timerTime = 0;
    	utcStart = 0;
		utcStop = 0;		
		startMoment = 0;	
		
		// resetTest() is called after sensor opened by onStart in main	
	}
	
	// function to call to update Results view
	function setObserver(func) {
		mFunc = func;	
	}
	
	// function onHide() {getModel().setObserver(null);}
	// application is stopping
	function stopControl() { 
		testTimer.stop();
		mApp.mStorage.storeResults(); 	
		
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
    	mState.isNotSaved = false;
    	mState.isSaved = true;
    }

    function endTest() {
    	testTimer.stop();
    	if(mState.isWaiting) {
			mState.isWaiting = false;
			//if(!mSensor.mHRData.isChOpen) {
			//	mSensor.openCh();
			//}
		}
		else {
			mState.isTesting = false;
			mState.isFinished = true;
			mState.isNotSaved = true;
			utcStop = timeNow();
		}
    }
    
    function alert(type)
	{
    	if(mApp.soundSet) {
    		Attention.playTone(type);
    	}
    	if(mApp.vibeSet) {
    		Attention.vibrate([new Attention.VibeProfile(100,400)]);
    	}
    }
    
    function discardTest() { mState.isNotSaved = false;    }

    function resetTest() {
    	mApp.mSensor.mHRData.resetTestVariables();
		utcStart = 0;
		utcStop = 0;
		mState.isWaiting = false;
		mState.isTesting = false;
		mState.isFinished = false;
		mState.isNotSaved = false;
		mState.isSaved = false;
    }

    function start() {
		Sys.println("Start: entered");
		
		// why don't we resetTest() here??
		
		testTimer.stop();	// This is in case user has changed test type while waiting
    	var testType = mApp.testTypeSet;
    	
    	// isWaiting is unused now I think
    	mState.isWaiting = false;
    	mState.isTesting = true;  
    				
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
		mState.isTesting = true;

    	Sys.println("Start: leaving func");
    }
    
    function performTest() {
    	// needs to be driven off a timer (UI one?)
    	// HRV
		var hrv = app.mSensor.mHRData.hrv;

		// Timer
		var timerTime = app.utcStop - app.utcStart;
		var testType = app.testTypeSet;

		if(TYPE_TIMER == testType) {
			timerTime = app.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			timerTime = app.mManualTimeSet;
		}

		// Pulse
		var pulse = app.mSensor.mHRData.livePulse;

		// Message
    	var msgTxt ="";
    	var testTime = app.timeNow() - app.utcStart;

		if(app.isFinished) {
			pulse = app.mSensor.mHRData.avgPulse;
			testTime = app.utcStop - app.utcStart;

			if(MIN_SAMPLES > app.mSensor.mHRData.dataCount) {
				msgTxt = "Not enough data";
			}
			else if(app.isSaved) {
				msgTxt = "Result saved";
			}
			else {
				msgTxt = "Finished";
			}
    	}
    	else if(app.isTesting) {
    		//var cycleTime = (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			var cycle = 1 + testTime % (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			if(cycle <= app.inhaleTimeSet) {
				msgTxt = "Inhale through nose " + cycle;
			}
			else if(cycle <= app.inhaleTimeSet + app.exhaleTimeSet) {
				msgTxt = "Exhale out mouth " + (cycle - app.inhaleTimeSet);
			}
			else {
				msgTxt = "Relax " + (cycle - (app.inhaleTimeSet + app.exhaleTimeSet));
			}

			if(TYPE_MANUAL != testType) {
				timerTime -= testTime;
			}
			else {
				timerTime = testTime;
			}
    	}
    	else if(app.mSensor.mHRData.isStrapRx) {
			if(TYPE_TIMER == testType) {
				msgTxt = "Timer test ready";
			}
			else if(TYPE_MANUAL == testType) {
				msgTxt = "Manual test ready";
			}
    	}
    	else {
    		msgTxt = "Searching for HRM";
    	}

    	// Strap & pulse indicators
    	var strapCol = app.txtColSet;
    	var pulseCol = app.txtColSet;
    	var strapTxt = "STRAP";
    	var pulseTxt = "PULSE";

    	if(!app.mSensor.mHRData.isChOpen) {
			pulse = 0;
			strapTxt = "SAVING";
			pulseTxt = "BATTERY";
		}
		else if(!app.mSensor.mHRData.isStrapRx) {
	    		strapCol = RED;
	    		pulseCol = RED;
    	}
    	else {
    		strapCol = GREEN;
    		if(!app.mSensor.mHRData.isPulseRx) {
	    		pulseCol = RED;
	    	}
	    	else {
	    		pulseCol = GREEN;
	    	}
    	}
    
    	if (mFunc != null) {
    		mFunc.invoke(:Update, mFunc, [strapTxt, strapCol, pulseTxt, pulseCol, msgTxt, hrv, 
    			app.mSensor.mHRData.avgPulse, app.timerFormat(timerTime)]);
    	}
    }
    
    function UpdateTestStatus() {
    	// this should drive the state transistions and state view information
    	// AntHandler drives data model information in sampleProcessing
    
    
    }
	
}