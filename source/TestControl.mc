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
	var utcNow; 
	var startMoment;
	var mManualTestStopTime;
	//var stopMoment;
	hidden var mApp;
	hidden var mFunc;
	    
	class cTestState {
		// App states
		var isTesting;
		var isFinished;
		var isNotSaved;
		var isSaved;
		var isClosing;
	
		function initialize() {
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
		
		// Init test variables
		startMoment = 0;
    	timerTime = 0;
    	utcStart = 0;
		utcStop = 0;
		utcNow = 0;		
		startMoment = 0;
		mManualTestStopTime = 0;	
		
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

	// this isn't used at the moment
    function autoFinish() {
    	endTest();
    	saveTest();
    	mState.isNotSaved = false;
    	mState.isSaved = true;
    }

    function endTest() {
    	testTimer.stop();
		mState.isTesting = false;
		mState.isFinished = true;
		mState.isNotSaved = true;
		utcStop = timeNow();
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
    
    function discardTest() { mState.isNotSaved = false;  }

    function resetTest() {
    	mApp.mSensor.mHRData.initForTest();
		utcStart = 0;
		utcStop = 0;
		mState.isTesting = false;
		mState.isFinished = false;
		mState.isNotSaved = false;
		mState.isSaved = false;
    }
    
    function saveTest() {
		var testDay = utcStart - (utcStart % 86400);
		var epoch = testDay - (86400 * 29);
		var index = ((testDay / 86400) % 30) * 5;
		var sumHrv = 0;
		var sumPulse = 0;
		var count = 0;

		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 3600) % 30) * 5;
		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 60) % 30) * 5;

		mApp.results[index + 0] = utcStart;
		mApp.results[index + 1] = mApp.mSensor.mHRData.hrv;
		mApp.results[index + 2] = mApp.mSensor.mHRData.avgPulse;

		// Calculate averages
		for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {

			var ii = i * DATA_SET_SIZE;

			if(epoch <= mApp.results[ii]) {

				sumHrv += mApp.results[ii + 1];
				sumPulse += mApp.results[ii + 2];
				count++;
			}
		}
		mApp.results[index + 3] = sumHrv / count;
		mApp.results[index + 4] = sumPulse / count;

		// Print values to file in csv format with ISO 8601 date & time
		var date = Calendar.info(startMoment, 0);
    	Sys.println(format("$1$-$2$-$3$T$4$:$5$:$6$,$7$,$8$,$9$,$10$",[
    		date.year,
    		date.month,
    		date.day,
    		date.hour,
    		date.min.format("%02d"),
    		date.sec.format("%02d"),
    		mApp.mSensor.mHRData.hrv,
    		mApp.mSensor.mHRData.avgPulse,
    		sumHrv / count,
    		sumPulse / count]));
    		
    	mState.isNotSaved = false;
    	mState.isSaved = true;
    }
    
	// called by startTest() to initial test timers etc
    function start() {
		Sys.println("Start: entered");
		// assumes that we have isAntRx true
		// Set up test type and timer up or down.
		
		resetTest();
		
		//set test state
		// now in isTesting = true can start processing ANT samples!
		mState.isTesting = true;
		mManualTestStopTime = 0;
		testTimer.stop();	// This is in case user has changed test type while waiting
    	
    	var testType = mApp.testTypeSet;
    				
    	if(TYPE_MANUAL == testType){
 			// kick off a timer for max period of testing allowed
 			// going to stop a manual test at the time set by user OR when Start pressed again
 			// note value here is in elapsed seconds
 			mManualTestStopTime = mApp.mManualTimeSet;	 			
			testTimer.start(method(:finishTest),mApp.mMaxTimerTimeSet,false); // false   	
    	} else {
    		// kick off a timer for period of test
    		timerTime = timerTimeSet;
			testTimer.start(method(:finishTest),timerTime*1000,false); // false
		}

		// Common start
		startMoment = Time.now();
		//utcStart = timeNow();
		utcStart = startMoment.value() + System.getClockTime().timeZoneOffset;

    	Sys.println("Start: leaving func");
    }
      
    function onEnterPressed() {
    	if(mState.isNotSaved && MIN_SAMPLES < mApp.mSensor.mHRData.dataCount) {
			Sys.println("TestControl: onEnterPressed() - save option");
			// user can either save or discard. in either event we are done
			mState.isNotSaved = false;
			mState.isSaved = true;
			// set isFinished???
			return true;
    	}
    	else if(mState.isFinished) {
    		Sys.println("TestControl: onEnterPressed() - Finished");
    		resetTest();
    		Ui.requestUpdate();
    	}
    	else if(mState.isTesting) {
    		Sys.println("TestControl: onEnterPressed() - Stop test");
    		stopTest();
    		Ui.requestUpdate();
    	}
    	else if(!mApp.mSensor.mHRData.isAntRx || !mApp.mSensor.mHRData.isPulseRx ){
    		Sys.println("TestControl: onEnterPressed() - no ANT");
    		alert(TONE_ERROR);
    	}
    	else {
    		Sys.println("TestControl: onEnterPressed() - start branch");
    		startTest();
    	}  
   		// no save needed
   		return false;    
    }
    
    function onEscapePressed() {
  		if(mState.isTesting) {
			stopTest();
		}
			
		if(mState.isFinished && mState.isNotSaved && MIN_SAMPLES < mApp.mSensor.mHRData.dataCount) {
			mState.isClosing = true;
			return true;
		}
		else {
			// hand back to UI to close app
			return false;
		}     
    }
    
    function UpdateTestStatus() {
    	// this should drive the state transistions and state view information
    	// AntHandler drives data model information in sampleProcessing
		Sys.println("TestControl: UpdateTestStatus()");
		
		// Timer information for view
		var timerTime = utcStop - utcStart;
		var testType = mApp.testTypeSet;
		
		// set default time display and adjust in tests below
		if(TYPE_TIMER == testType) {
			timerTime = mApp.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			// driven by user stopping or hitting limit
			timerTime = 0;
		}

		// Message
    	var msgTxt ="";
    	var testTime = timeNow() - utcStart;

		if(mState.isFinished) {
			testTime = utcStop - utcStart;

			if(MIN_SAMPLES > mApp.mSensor.mHRData.dataCount) {
				msgTxt = "Not enough data";
			}
			else if(mState.isSaved) {
				msgTxt = "Result saved";
			}
			else {
				msgTxt = "Finished";
			}
    	}
    	else if(mState.isTesting) {
    		//var cycleTime = (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			var cycle = 1 + testTime % (mApp.inhaleTimeSet + mApp.exhaleTimeSet + mApp.relaxTimeSet);
			if(cycle <= mApp.inhaleTimeSet) {
				msgTxt = "Inhale through nose " + cycle;
			}
			else if(cycle <= mApp.inhaleTimeSet + mApp.exhaleTimeSet) {
				msgTxt = "Exhale out mouth " + (cycle - mApp.inhaleTimeSet);
			}
			else {
				msgTxt = "Relax " + (cycle - (mApp.inhaleTimeSet + mApp.exhaleTimeSet));
			}

			if(TYPE_TIMER == testType) {
				// reduce time left
				timerTime -= testTime;
			}
			else {
				// manual timer counts up
				timerTime = testTime;
				if (testTime >= mManualTestStopTime) {
					// reached limit set by user
					finishTest();
				}
			}
    	}
    	else if(mApp.mSensor.mHRData.isStrapRx) {
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

		// update Test View data  
    	if (mFunc != null) {
    		mFunc.invoke(:Update, [ msgTxt, timerFormat(timerTime)]);
    	}
    }   
	
}