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
	
	SENSOR_INTERNAL = 0, // false
	SENSOR_SEARCH = 1 // true
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
		// Save should be done in saveResults()
		//$._mApp.mStorage.storeResults(); 			
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
		mState.isSaved = false;
		utcStop = timeNow();
    }
    
    function alert(type)
	{
    	if($._mApp.soundSet) {
    		Attention.playTone(type);
    	}
    	if($._mApp.vibeSet) {
    		Attention.vibrate([new Attention.VibeProfile(100,400)]);
    	}
    }
    
    function discardTest() { mState.isNotSaved = false;  }

    function resetTest() {
    	$._mApp.mSensor.mHRData.initForTest();
    	// need to be careful we have shown all results first!!!
		utcStart = 0;
		utcStop = 0;
		mState.isTesting = false;
		mState.isFinished = false;
		mState.isNotSaved = true;
		mState.isSaved = false;
    }
    
    function saveTest() {
    	Sys.println("TestControl: saveTest() called");
    	
    	// seconds in day = 86400
    	// make whole number of days (still seconds since UNIX epoch)
    	// This ignores possiblity of 32 bit integar of time wrapping on testday and epoch
    	// should change to use time functions available
		var testDay = utcStart - (utcStart % 86400);
		// 29 days ago...
		var epoch = testDay - (86400 * 29);
		// (testDay modulo 30) * 5 ...
		var index = ((testDay / 86400) % 30) * 5;
		
		Sys.println("utcStart, testday, epoch, index = "+utcStart+","+testDay+","+epoch+","+index);
		
		var sumHrv = 0;
		var sumPulse = 0;
		var count = 0;

		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 3600) % 30) * 5;
		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 60) % 30) * 5;

		$._mApp.results[index + 0] = utcStart;
		$._mApp.results[index + 1] = $._mApp.mSampleProc.mLnRMSSD;
		$._mApp.results[index + 2] = $._mApp.mSampleProc.avgPulse;

		// Calculate averages
		for(var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			var ii = i * DATA_SET_SIZE;
			if(epoch <= $._mApp.results[ii]) {
				sumHrv += $._mApp.results[ii + 1];
				sumPulse += $._mApp.results[ii + 2];
				count++;
			}
		}
		$._mApp.results[index + 3] = sumHrv / count;
		$._mApp.results[index + 4] = sumPulse / count;

		// Print values to file in csv format with ISO 8601 date & time
		var date = Calendar.info(startMoment, 0);
    	Sys.println(format("$1$-$2$-$3$T$4$:$5$:$6$,$7$,$8$,$9$,$10$",[
    		date.year,
    		date.month,
    		date.day,
    		date.hour,
    		date.min.format("%02d"),
    		date.sec.format("%02d"),
    		$._mApp.mSampleProc.mLnRMSSD,
    		$._mApp.mSampleProc.avgPulse,
    		sumHrv / count,
    		sumPulse / count]));
    	
    	// better write results to memory!!
    	$._mApp.mStorage.storeResults(); 
    		
    	mState.isNotSaved = false;
    	mState.isSaved = true;
    }
    
	// called by startTest() to initial test timers etc
    function start() {
		if (mDebugging == true) {Sys.println("Start: entered");}
		// assumes that we have isAntRx true
		// Set up test type and timer up or down.
		
		resetTest();
		Sys.println("TestControl: start() - clearing sample buffer - is this right place?");
    	$._mApp.mSampleProc.resetSampleBuffer();
		
		//set test state
		// now in isTesting = true can start processing ANT samples!
		mState.isTesting = true;
		mManualTestStopTime = 0;
		testTimer.stop();	// This is in case user has changed test type while waiting
    	
    	var testType = $._mApp.testTypeSet;
    				
    	if(TYPE_MANUAL == testType){
 			// kick off a timer for max period of testing allowed
 			// going to stop a manual test at the time set by user OR when Start pressed again
 			// note value here is in elapsed seconds
 			mManualTestStopTime = $._mApp.mManualTimeSet;	 			
			testTimer.start(method(:finishTest),$._mApp.mMaxTimerTimeSet,false); // false   	
    	} else {
    		// kick off a timer for period of test
    		timerTime = $._mApp.timerTimeSet;
			testTimer.start(method(:finishTest),timerTime*1000,false); // false
		}

		// Common start
		startMoment = Time.now();
		//utcStart = timeNow();
		utcStart = startMoment.value() + System.getClockTime().timeZoneOffset;

    	if (mDebugging == true) {Sys.println("Start: leaving func");}
    }
      
    function onEnterPressed() {
    	// tells HRVDelegate not to save
    	var mValue = false;
    	
    	if(mState.isFinished) {
    		if (mDebugging == true) {Sys.println("TestControl: onEnterPressed() - Finished");}
    		resetTest();
    		Ui.requestUpdate();
    	}
    	else if(mState.isTesting) {
    		if (mDebugging == true) {Sys.println("TestControl: onEnterPressed() - Stop test");}
    		if(mState.isNotSaved && MIN_SAMPLES < $._mApp.mSampleProc.dataCount) {
				if (mDebugging == true) {Sys.println("TestControl: save option");}
				// user can either save or discard. in either event we are done
				// returning true tells HRV Delegate to ask to save
				mValue = true;
	    	}
	    	stopTest();
    		Ui.requestUpdate();
    	}
    	else if(!$._mApp.mSensor.mHRData.isAntRx || !$._mApp.mSensor.mHRData.isPulseRx ){
    		if (mDebugging == true) {Sys.println("TestControl: onEnterPressed() - no ANT");}
    		alert(TONE_ERROR);
    	}
    	else {
    		if (mDebugging == true) {Sys.println("TestControl: onEnterPressed() - start branch");}
    		startTest();
    	}  
   		// signal whether save needed
   		return mValue;    
    }
    
    function onEscapePressed() {
  		if(mState.isTesting) {
			stopTest();
		}
			
		if(mState.isFinished && mState.isNotSaved && MIN_SAMPLES < $._mApp.mSampleProc.dataCount) {
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
    	// called every second
		if (mDebugging == true) {Sys.println("TestControl: UpdateTestStatus()");}
		
		// Timer information for view
		timerTime = 0; // = utcStop - utcStart;
		var testType = $._mApp.testTypeSet;
		
		// set default time display and adjust in tests below
		if(TYPE_TIMER == testType) {
			timerTime = $._mApp.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			// driven by user stopping or hitting limit
			timerTime = 0;
		}

		// Message
    	var msgTxt ="";
    	var testTime = timeNow() - utcStart;

		if(mState.isFinished) {
			if (mDebugging == true) {Sys.println("TestControl: isFinished branch");}
			testTime = utcStop - utcStart;

			if(MIN_SAMPLES > $._mApp.mSampleProc.dataCount) {
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
    		if (mDebugging == true) {Sys.println("TestControl: isTesting branch");}
    		
    		msgTxt = "Breathe regularly";

			if(TYPE_TIMER == testType) {
				// reduce time left
				timerTime -= testTime;
			}
			else {
				// manual timer counts up
				timerTime = testTime;
				if (testTime >= mManualTestStopTime) {
					// reached limit set by user
					if (mDebugging == true) {Sys.println("Update: manual test time expired : "+testTime);}
					finishTest();
				}
			}
    	}
    	else if($._mApp.mSensor.mHRData.isStrapRx) {
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

		if (mDebugging == true) {Sys.println("TestControl: invoking test view");}
		
		// update Test View data  
    	if (mFunc != null) {
    		mFunc.invoke(:Update, [ msgTxt, timerFormat(timerTime)]);
    	}
    	if (mDebugging == true) {Sys.println("TestControl: exiting UpdateStatus");}
    }   
	
}