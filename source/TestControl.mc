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

// TBD is here or in main
//enum {
	// Tones
//	TONE_KEY = 0,
//	TONE_START = 1,
//	TONE_STOP = 2,
//	TONE_RESET = 9,
//	TONE_FAILURE = 14,
//	TONE_SUCCESS = 15,
//	TONE_ERROR = 18,

	// Test types
//	TYPE_MANUAL = 0, // runs as long as useer wants up to max time
//	TYPE_TIMER = 1,  // defaults to 5 mins and can be changed down or to max-time
//}	


class TestController {

	var timerTime;	
	hidden var testTimer;
	var mState;
	var utcStart;
	var utcStop;	
	var startMoment;
	//var stopMoment;
	hidden var mApp;
	    
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
		resetTest();
		startMoment = 0;
    	timerTime = 0;
    	utcStart = 0;
		utcStop = 0;		
		startMoment = 0;	
		
	}
	
	// application is stopping
	function stopControl() { testTimer.stop(); 	}
	
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
    	mSensor.mHRData.resetTestVariables();
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
    
    function UpdateTestStatus() {
    	// this should drive the state transistions and state view information
    	// AntHandler drives data model information in sampleProcessing
    
    
    }
	
}