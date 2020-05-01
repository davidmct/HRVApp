//
// Copyright 2020 David McTernan
// 
// Test control logic

// Attempt to use Model-View-Controller structure
// push Model information into StoragePropertiesHandling file
// This converts user input in to model commands or view updates
// data model should accept commands
// views should register for change notifications if needed

// NOTE:
// Adding a PAUSE state still doesn't allow ABORT/CLOSE states to show message and we go back to READY before
// TestView Ui appears to be updated. However, state changes and Ui update requests are in sync!
// Might need this type of code...
// https://forums.garmin.com/developer/connect-iq/f/discussion/4396/how-can-i-update-watch-app-ui-in-realtime-when-receiving-messages-from-android-app

using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.System as Sys;	

class TestController {

	var timerTime;	
	hidden var testTimer;
	
	var mTestState;
	var mTestMessage;
	var mSensorReady;
	
	var utcStart;
	var utcNow; 
	var startMoment;
	var mManualTestStopTime;
	hidden var mFunc;
	hidden var mFuncCurrent;
	hidden var mHRmsgTxt;

	function initialize() {
		testTimer = new Timer.Timer();
		mTestState = TS_INIT;
		mTestMessage = "";
		// Init test variables
		startMoment = 0;
    	timerTime = 0;
    	utcStart = 0;
		utcNow = 0;		
		startMoment = 0;
		mManualTestStopTime = 0;
		mSensorReady = false;
		mHRmsgTxt = "";	
	}

	
	// function to call to update Summary view
	function setObserver(func) {
		//Sys.println("Testcontrol: setObserver() called with "+func);
		mFunc = func;
	}
	
	function setObserver2(func) {
		mFuncCurrent = func;
	}	
	
	// allow 
	function onNotify(symbol, params) {
		// [ msgTxt, HR status, state INIT]
		var stateInit;
		mHRmsgTxt = params[0];
		mSensorReady = params[1];	
		stateInit = params[2];
		//Sys.println("TestControl: onNotify : "+params);
		// sensor has changed so force INIT
		if (stateInit) { 
			Sys.println("TestControl: statemachine forced INIT");
			mTestState = TS_INIT;
			StateMachine(:restart);
		}		
	}
	
	// probably need to modify Sensor to notify statemachine when found strap etc
	// sets mSensorReady = true or false
	function StateMachine(caller) {
		// we have a set of callers who can influence state
		// :enterPressed - obvious
		// :escapePressed - bvious
		// :timerExpired - we have reached end of test naturally
		// :HR_ready - found strap has a pulse - make this a variable... set by notify
		// :UpdateUI
		if (mDebugging == true) {Sys.println("TestControl: StateMachine() entered");}

		// request to restart		
		if (caller == :RestartControl) { 
			Sys.println("TestControl(): Restart issued"); 
			mTestState = TS_INIT; 
			discardTest();
		}
					
		var mResponse = false; // some UI inputs require response
		var enoughSamples = false;
		var setSensorStr = ($._mApp.mSensorTypeExt ? "external" : "registered");
		
		// Timer information for view
		timerTime = 0; 
		var testType = $._mApp.testTypeSet;
		
		// set default time display and adjust below
		if(TYPE_TIMER == testType) {
			timerTime = $._mApp.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			// driven by user stopping or hitting limit
			timerTime = 0;
		}
    	var testTime = timeNow() - utcStart;
		
		switch (mTestState) {
			case TS_INIT:
				Sys.println("TS_INIT");
				// We may need to reinitialise sensors if swapped here
				mTestMessage = "Initialising...";
				resetTest();
				mTestState = TS_WAITING; 
				// Sensor status update method
				$._mApp.mSensor.setObserver(self.method(:onNotify));
			break;
			case TS_WAITING:
				//Sys.println("TS_WAITING");
				// we are waiting for the HR strap to be ready
				if ( mSensorReady ) { 
					mTestMessage = setSensorStr+" sensor ready";
					mTestState = TS_READY; 
				} else {
					mTestMessage = "Waiting for "+setSensorStr+" HR source";
				}
				if (caller == :enterPressed) {
					// we might be lucky and HR is ready at the same time as sensor is ready
					// ignore this
					alert(TONE_ERROR);				
				} else if (caller == :escapePressed) {
					// just pop the view by returning false
				}				
			break;
			case TS_READY:
				// stars are aligned. we have a source of data and waiting to go
				if(TYPE_TIMER == testType) {
					mTestMessage = "Timer test ready. Press Enter";
				}
				else if(TYPE_MANUAL == testType) {
					mTestMessage= "Manual test ready. Press Enter";
				}
				//Sys.println("TS_READY: message: "+mTestMessage);
				
				if (caller == :enterPressed) {
					// now we can setup test ready to go
					// KEEP OLD data until actually starting the test!
					$._mApp.mSensor.mHRData.initForTest();
					startTest();
					mTestState = TS_TESTING; 	
					Sys.println("TS_READY - enter pressed");		
				} else if (caller == :escapePressed) {
					// just pop the view by returning false
					// go back to initialising or READY?
					endTest(); // maybe in line as only timer to stop
					mTestState = TS_INIT; 
					mTestMessage = "escape pressed";
				}				
			break;
			case TS_TESTING:
				//Sys.println("TS_TESTING");
				// now we are in the mist of testing
				mTestMessage = "Breathe regularly and stay still";
				
				if (MIN_SAMPLES < $._mApp.mSampleProc.dataCount) {enoughSamples = true;}
				
				switch (caller) {
					case :timerExpired:
					case :manualExpired:
						// need to check enough samples
						if (enoughSamples) {
							autoFinish();
						} else {
							// no save
							finishTest();
						}
						mTestState = TS_CLOSE; 	
						mTestMessage = "Test time ended";
					break;
					case :enterPressed:
					case :escapePressed:
						// test stopped by user so saving is UI issue if enough
						stopTest();
						if (enoughSamples) {mResponse = true;}					
						mTestState = TS_ABORT; 	
						mTestMessage = "Test terminated";
					break;
					default:
						if(TYPE_TIMER == testType) {
							// reduce time left
							timerTime -= testTime;
						}
						else {
							// manual timer counts up
							timerTime = testTime;
							// manual timer finished and in manual test!
							if ((testTime >= mManualTestStopTime) && (TYPE_MANUAL == testType)) {
								mTestMessage = "Manual Test Finished";
								// reached limit set by user
								if (mDebugging == true) {Sys.println("Update: manual test time expired : "+testTime);}
								if (enoughSamples) {
									autoFinish();
								} else {
									// no save
									finishTest();
								}
								mTestState = TS_CLOSE;
							}
						}
					break;				
				} // end caller switch	
							
			break;
			case TS_ABORT:
				Sys.println("TS_ABORT");
				// go back to ready or maybe INIT if new sensors
				mTestMessage = "Results available until you return to view";
				mTestState = TS_PAUSE;	
				resetTest();
			break;
			case TS_CLOSE:
				Sys.println("TS_CLOSE");
				// go back to ready or maybe INIT if new sensors
				// maybe TestView is popped at this point?
				mTestState = TS_PAUSE;	
				mTestMessage = "Results available until you return to view";
				resetTest();
			break;
			case TS_PAUSE:
				// allow one update cycle to show close and and abort messages
				Sys.println("TS_PAUSE");
				mTestState = TS_READY;					
			break;
			default:
				Sys.println("UNKNOWN state in test controller!");
			break;	
		} // end switch
		
		// update Test View data  
		//if (mFunc == null) {Sys.println("TestControl: Statemachine: mFunc NULL "); }
    	if (mFunc != null) {
    		mFunc.invoke(:Update, [ mTestMessage, timerFormat(timerTime)]);
    		if (mDebugging == true) {Sys.println("TestControl: Statemachine: Testview update - "+mTestMessage);}
    	}
    	
    	// update Current  View data  
    	if (mFuncCurrent != null) {
    		var limit = TYPE_MANUAL == testType ? $._mApp.mManualTimeSet : $._mApp.timerTimeSet;
    		mFuncCurrent.invoke(:Update,  [timerFormat(timerTime), timerFormat(limit)]);
    	}
    	    	
    	if (mDebugging == true) {Sys.println("TestControl: exiting State machine");}
		//Ui.requestUpdate();
		return mResponse;
	}
	
	function fCheckSwitchType( caller, value) {
		if (caller == :FitType) {
			if (value != $._mApp.mFitWriteEnabled) {
				discardTest();
				StateMachine(:RestartControl); 	
			}	
		}
		else if (caller == :SensorType) {
			// this also restarts state machine and discard FIT data
			$._mApp.mSensor.fSwitchSensor( value);		
		} else if (caller == :TestType) {	
	 		if (value != $._mApp.testTypeSet) {             
	        	StateMachine(:RestartControl); 
	        	Sys.println("fCheckSwitchType(): TestType changed so restart controller");
	        }
		}	
	}  
	
	// function onHide() {getModel().setObserver(null);}
	
	function startTest() {
		// make sure no old FIT open
		discardTest();
		// set up FIT to write data if enabled
		$._mApp.mFitControl.createSession();
		// now start recording
		$._mApp.mFitControl.startFITrec(); 
		
    	alert(TONE_START);
    	start();
    }

    function stopTest() {
    	Sys.println("stopTest() called");
    	endTest();
		alert(TONE_STOP);
    }

    function finishTest() {
    	// called when not enough data 
    	Sys.println("finishTest()");
    	if ($._mApp.mFitControl != null) { $._mApp.mFitControl.discardTest(); }
    	endTest();
    	alert(TONE_SUCCESS);
    }

	// this isn't used at the moment
    function autoFinish() {
    	Sys.println("autoFinish()");
    	endTest();
    	saveTest();
    	alert(TONE_SUCCESS);
    }

    function endTest() {
    	Sys.println("endTest()");
    	testTimer.stop();
    }
    
    function alert(type)
	{
		if( Attention has :playTone ) {
    		if($._mApp.soundSet) { Attention.playTone(type);  }
    	}
    	if (Attention has :vibrate) {
    		if($._mApp.vibeSet) { Attention.vibrate([new Attention.VibeProfile(100,400)]); }
    	}
    }

    function resetTest() {
    	//Sys.println("TestControl: resetTest() called");
    	// don't call this as useful to see old data before starting a new test
    	//$._mApp.mSensor.mHRData.initForTest();
    	testTimer.stop();
    	// reseting utcStart here overwrites when we about test but have enough samples
		//utcStart = 0;
    }
    
    function discardTest() {
    	// called from HRVBehaviourDelegate
    	Sys.println("discardTest() called");
    	resetTest(); // may not be necessary as handled by state machine
    	if ($._mApp.mFitControl != null) {
    		$._mApp.mFitControl.discardFITrec();
    	}
    }
    
    function saveTest() {
    	Sys.println("TestControl: saveTest() called");
    	
    	// seconds in day = 86400
    	// make whole number of days (still seconds since UNIX epoch)
    	// This ignores possiblity of 32 bit integar of time wrapping on testday and epoch
    	// should change to use time functions available
		var testDayutc = utcStart - (utcStart % 86400);
		
		// next slot in cycle, can overwrite multiple times in a day and keep last ones
		// Check whether we are creating another set of results on the same day by inspecting previous entry
		var previousEntry = ($._mApp.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
		var previousIndex = previousEntry * DATA_SET_SIZE;
		var currentIndex = $._mApp.resultsIndex * DATA_SET_SIZE;	
		
		var x = $._mApp.results[previousIndex + TIME_STAMP_INDEX];
		// convery to day units
		var previousSavedutc = 	x - (x % 86400);
		x = $._mApp.results[currentIndex + TIME_STAMP_INDEX];
		var currentSavedutc = x - (x % 86400);
		var index;
		
		if (testDayutc == previousSavedutc) {
			// overwrite current days entry
			index = previousIndex;
		}
		else {
			index = currentIndex;			
			// written a new entry so move pointer
   			// increment write pointer to circular buffer
   			$._mApp.resultsIndex = ($._mApp.resultsIndex + 1 ) % NUM_RESULT_ENTRIES;
   			Sys.println("SaveTest: pointer now "+$._mApp.resultsIndex);
   		}
			
		Sys.println("utcStart, index, testdayutc, previous entry utc = "+utcStart+", "+index+", "+testDayutc+", "+previousSavedutc);

		$._mApp.results[index + TIME_STAMP_INDEX] = utcStart;
		$._mApp.results[index + AVG_PULSE_INDEX] = $._mApp.mSampleProc.avgPulse;
		$._mApp.results[index + MIN_II_INDEX] = $._mApp.mSampleProc.minIntervalFound;
		$._mApp.results[index + MAX_II_INDEX] = $._mApp.mSampleProc.maxIntervalFound;		
		$._mApp.results[index + MAX_DIFF_INDEX] = $._mApp.mSampleProc.minDiffFound;
		$._mApp.results[index + MAX_DIFF_INDEX] = $._mApp.mSampleProc.maxDiffFound;				
		$._mApp.results[index + RMSSD_INDEX] = $._mApp.mSampleProc.mRMSSD;
		$._mApp.results[index + LNRMSSD_INDEX] = $._mApp.mSampleProc.mLnRMSSD;

		$._mApp.results[index + SDNN_INDEX] = $._mApp.mSampleProc.mSDNN;
		$._mApp.results[index + SDSD_INDEX] = $._mApp.mSampleProc.mSDSD; 
		$._mApp.results[index + NN50_INDEX] = $._mApp.mSampleProc.mNN50;
		$._mApp.results[index + PNN50_INDEX] = $._mApp.mSampleProc.mpNN50; 
		$._mApp.results[index + NN20_INDEX] = $._mApp.mSampleProc.mNN20;
		$._mApp.results[index + PNN20_INDEX] = $._mApp.mSampleProc.mpNN20;
   		
    	// better write results to memory!!
    	$._mApp.mStorage.storeResults(); 
    	// save intervals as well so we can reload and display
    	$._mApp.mStorage.saveIntervalsToStore();
    	$._mApp.mStorage.saveStatsToStore();    
    		
    	// FIT FILE SESSION RESULTS HERE
    	$._mApp.mFitControl.saveFITrec(); // also sets mSession to null

    }
    
	// called by startTest() to initial test timers etc
    function start() {
		Sys.println("start() ENTERED");
		// Set up test type and timer up or down.
		
		resetTest();
		//Sys.println("TestControl: start() - clearing stats and interval buffer");
    	//$._mApp.mSampleProc.resetSampleBuffer();
		$._mApp.mSensor.mHRData.initForTest();
		
		mManualTestStopTime = 0;
		testTimer.stop();	// This is in case user has changed test type while waiting
    	
    	var testType = $._mApp.testTypeSet;
    				
    	if(TYPE_MANUAL == testType){
 			// kick off a timer for max period of testing allowed
 			// going to stop a manual test at the time set by user OR when Start pressed again
 			// note value here is in elapsed seconds
 			mManualTestStopTime = $._mApp.mManualTimeSet;	 			
			testTimer.start(method(:timerEnded),$._mApp.mMaxTimerTimeSet*1000,false); // false   	
    	} else {
    		// kick off a timer for period of test
    		timerTime = $._mApp.timerTimeSet;
    		//Sys.println("timerTime in timed test = "+timerTime);
			testTimer.start(method(:timerEnded),timerTime*1000,false); // false
		}

		// Common start
		startMoment = Time.now();
		utcStart = startMoment.value() + System.getClockTime().timeZoneOffset;
		
		Sys.println("Test started at : "+utcStart);
    } 
    
    function timerEnded() {
    	// either hit limit on manual or test time finsished on auto
    	Sys.println("timerEnded()");
    	StateMachine(:timerExpired);
	}
    		
}