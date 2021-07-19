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

using HRVStorageHandler as mStorage;
using GlanceGen as GG;
using DumpData as Dump;

class TestController {

	var timerTime;
	hidden var testTimer;
	hidden var dumpTimer;
	hidden var mBlk; // block number
	hidden var mDType; // 0 = intervals, 1 = flags

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
	hidden var mWaitDump = false;

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
		mWaitDump = false;
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
		mHRmsgTxt = params[0]; // used in view
		mSensorReady = params[1];
		stateInit = params[2];
		//$.DebugMsg(false, "TestControl: onNotify : "+params);
		// sensor has changed so force INIT
		if (stateInit) {
			Sys.println("TC:OnNotify: S/M forced INIT");
			mTestState = TS_INIT;
			StateMachine(:RestartControl);
		}

		//$.DebugMsg(true, "mHRmsgTxt - "+mHRmsgTxt+", Sensor ready? "+mSensorReady);
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
		if (mDebugging == true) {Sys.println("TC: SM() start state "+mTestState); }

		// request to restart
		if (caller == :RestartControl) {
			Sys.println("TC(): Restart issued");
			mTestState = TS_INIT;
			discardTest();
		}

		var mResponse = false; // some UI inputs require response
		var enoughSamples = false;
		var setSensorStr = ($.mSensorTypeExt ? "external" : "registered");

		// Timer information for view
		timerTime = 0;
		var testType = $.testTypeSet;

		// set default time display and adjust below
		if(TYPE_TIMER == testType) {
			timerTime = $.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			// driven by user stopping or hitting limit
			timerTime = 0;
		}
    	var testTime = timeNow() - utcStart;

		switch (mTestState) {
			case TS_INIT:
				// We may need to reinitialise sensors if swapped here
				mTestMessage = "Initialising...";
				resetTest();
				mTestState = TS_WAITING;
				// Sensor status update method
				$.mSensor.setObserver(self.method(:onNotify));
			break;
			case TS_WAITING:
				// we are waiting for the HR strap to be ready
				if ( mSensorReady ) {
					mTestMessage = "Sensor Ready"; //0.6.4 setSensorStr+" sensor ready";
					mTestState = TS_READY;
				} else {
					mTestMessage = "Waiting for sensor"; // 0.6.4 "Waiting for "+setSensorStr+" sensor";
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
				//0.4.4
				// Print ID to see if we can display for external or known!
				//$.DebugMsg( true, "Found ANT ID = "+$.mAuxHRAntID);

				// we know ANT ID is now available

				// stars are aligned. we have a source of data and waiting to go
				if(TYPE_TIMER == testType) {
					//0.4.4 - simplify message
					//mTestMessage = "Timer test ready. Press Enter";
					mTestMessage = "Begin timer test?";
				}
				else if(TYPE_MANUAL == testType) {
					//0.4.4 - simplify message
					//mTestMessage= "Manual test ready. Press Enter";
					mTestMessage = "Begin manual test?";
				}
				//Sys.println("TS_READY: message: "+mTestMessage);

				if (caller == :enterPressed) {
					// now we can setup test ready to go
					// KEEP OLD data until actually starting the test!
					Sys.println("TS_READY - enter pressed");
					$.mSensor.mHRData.initForTest();
					startTest();
					mTestState = TS_TESTING;

				} else if (caller == :escapePressed) {
					// just pop the view by returning false
					// go back to initialising or READY?
					endTest(); // maybe in line as only timer to stop
					mTestState = TS_INIT;
					//04.4.4 - not on screen long and people know key pressed
					//mTestMessage = "escape pressed";
					mTestMessage = "";
				}
			break;
			case TS_TESTING:
				// now we are in the mist of testing
				//04.04.4
				//mTestMessage = "Breathe regularly and stay still";
				mTestMessage = "Testing HRV";

				if (MIN_SAMPLES < $.mSampleProc.dataCount) {enoughSamples = true;}

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
						if (enoughSamples) {
							mResponse = true;
						} else { // we don't have enough samples so close FIT
							if ($.mFitControl.mSession != null) {
    							$.mFitControl.discardFITrec();
    						}
						}
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
								//if (mDebugging == true) {Sys.println("Update: manual test time expired : "+testTime);}
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
				// go back to ready or maybe INIT if new sensors
				//mTestMessage = "Results available until next test";
				//mTestState = TS_PAUSE;
				//resetTest();
			//break;
			case TS_CLOSE:
				// go back to ready or maybe INIT if new sensors
				// maybe TestView is popped at this point?
				mTestState = TS_PAUSE;
				mTestMessage = "Results available until next test";
				resetTest();
			break;
			case TS_PAUSE:
				// allow one update cycle to show close and and abort messages
				// only move state if on large devices string dump finished
				if (!mWaitDump) {mTestState = TS_PAUSE2;}
			break;
			case TS_PAUSE2:
				// allow one update cycle to show close and and abort messages
				mTestState = TS_READY;
			break;

			default:
				Sys.println("UNKNOWN state in TC!");
			break;
		} // end switch

		// update Test View data
		//if (mFunc == null) {Sys.println("TestControl: Statemachine: mFunc NULL "); }
    	if (mFunc != null) {
    		mFunc.invoke(:Update, [ mTestMessage, timerFormat(timerTime)]);
    		if (mDebugging == true) {Sys.println("TC: Testview update - "+mTestMessage);}
    	}

    	// update Current  View data
    	if (mFuncCurrent != null) {
    		var limit = TYPE_MANUAL == testType ? $.mManualTimeSet : $.timerTimeSet;
    		mFuncCurrent.invoke(:Update,  [timerFormat(timerTime), timerFormat(limit)]);
    	}

		if (mDebugging == true) {Sys.println("TC: SM() exit in state "+mTestState); }
		return mResponse;
	}

	function fCheckSwitchType( caller, value) {
		if (caller == :FitType) {
			if (value != $.mFitWriteEnabled) {
				discardTest();
				StateMachine(:RestartControl);
			}
		}
		//else if (caller == :SensorType) {
			// this also restarts state machine and discard FIT data
			//$._mApp.mSensor.fSwitchSensor( value);
		//}
		else if (caller == :TestType) {
	 		if (value != $.testTypeSet) {
	        	StateMachine(:RestartControl);
	        	//Sys.println("fCheckSwitchType(): TestType changed so restart controller");
	        }
		}
	}

	// function onHide() {getModel().setObserver(null);}

	function startTest() {
		Sys.println("startTest() called");
		// make sure no old FIT open
		discardTest();
		// set up FIT to write data if enabled
		$.mFitControl.createSession();
		// now start recording
		$.mFitControl.startFITrec();
		
		// 0.6.3 Glance data in no longer latest
		$.mGData = false;

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
    	// 0.4.04 changed to mSession not class as mSession is null if no FIT created
    	// test maybe unnecessary as in discard aleady
    	// previous version called mFitControl.discardTest() which doesn't exist
    	//if ($.mFitControl.mSession != null) { discardTest(); }
    	discardTest();
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
		if( Attention has :backlight ) {
    		Attention.backlight(true);
		}
    }

    function alert(type)
	{
		if( Attention has :playTone ) {
    		if($.soundSet) { Attention.playTone(type);  }
    	}
    	if (Attention has :vibrate) {
    		if($.vibeSet) { Attention.vibrate([new Attention.VibeProfile(100,400)]); }
    	}
    }

    function resetTest() {
    	Sys.println("TestControl: resetTest()");
    	// don't call this as useful to see old data before starting a new test
    	//$.mSensor.mHRData.initForTest();
    	testTimer.stop();
    	// reseting utcStart here overwrites when we about test but have enough samples
		//utcStart = 0;
		mWaitDump = false;
    }

    function discardTest() {
    	// called from HRVBehaviourDelegate
    	Sys.println("discardTest() called");
    	resetTest(); // may not be necessary as handled by state machine
    	//0.4.04 test mSession not mFitControl for null
    	//if ($.mFitControl.mSession != null) {
    	$.mFitControl.discardFITrec();
    	//}
    }

(:oldResults) // moved to storage
    function saveTest() {
    	Sys.println("TestControl: saveTest() called");

    	// seconds in day = 86400
    	// make whole number of days (still seconds since UNIX epoch)
    	// This ignores possiblity of 32 bit integar of time wrapping on testday and epoch
    	// should change to use time functions available
		var testDayutc = utcStart - (utcStart % 86400);

		// next slot in cycle, can overwrite multiple times in a day and keep last ones
		// Check whether we are creating another set of results on the same day by inspecting previous entry
		var previousEntry = ($.resultsIndex + NUM_RESULT_ENTRIES - 1) % NUM_RESULT_ENTRIES;
		var previousIndex = previousEntry * DATA_SET_SIZE;
		var currentIndex = $.resultsIndex * DATA_SET_SIZE;

		var x = $.results[previousIndex + TIME_STAMP_INDEX];
		// convery to day units
		var previousSavedutc = 	x - (x % 86400);
		x = $.results[currentIndex + TIME_STAMP_INDEX];
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
   			$.resultsIndex = ($.resultsIndex + 1 ) % NUM_RESULT_ENTRIES;
   			Sys.println("SaveTest: pointer now "+$.resultsIndex);
   		}

		Sys.println("utcStart, index, testdayutc, previous entry utc = "+utcStart+", "+index+", "+testDayutc+", "+previousSavedutc);

		$.results[index + TIME_STAMP_INDEX] = utcStart;
		$.results[index + AVG_PULSE_INDEX] = $.mSampleProc.avgPulse;
		$.results[index + MIN_II_INDEX] = $.mSampleProc.minIntervalFound;
		$.results[index + MAX_II_INDEX] = $.mSampleProc.maxIntervalFound;
		$.results[index + MAX_DIFF_INDEX] = $.mSampleProc.minDiffFound;
		$.results[index + MAX_DIFF_INDEX] = $.mSampleProc.maxDiffFound;
		$.results[index + RMSSD_INDEX] = $.mSampleProc.mRMSSD;
		$.results[index + LNRMSSD_INDEX] = $.mSampleProc.mLnRMSSD;

		$.results[index + SDNN_INDEX] = $.mSampleProc.mSDNN;
		$.results[index + SDSD_INDEX] = $.mSampleProc.mSDSD;
		$.results[index + NN50_INDEX] = $.mSampleProc.mNN50;
		$.results[index + PNN50_INDEX] = $.mSampleProc.mpNN50;
		$.results[index + NN20_INDEX] = $.mSampleProc.mNN20;
		$.results[index + PNN20_INDEX] = $.mSampleProc.mpNN20;

    	// better write results to memory!!
    	mStorage.storeResults();
    	// save intervals as well so we can reload and display
    	mStorage.saveIntervalsToStore();
    	mStorage.saveStatsToStore();

    	// FIT FILE SESSION RESULTS HERE
    	$.mFitControl.saveFITrec(); // also sets mSession to null

    }

// core functionality moved to storage
(:newResults)
    function saveTest() {
    	Sys.println("TestControl: saveTest()");
    	
    	//0.6.3
    	// trying to popView's here doesn't work if buried in menus. Need to stop views being pushed
    	
     	// FIT FILE SESSION RESULTS HERE
    	$.mFitControl.saveFITrec(); // also sets mSession to null
    	
    	// prepare results and save
    	mStorage.prepareSaveResults( utcStart);

    	// 0.6.2 now generate widget type data
    	var _stats = [ $.mSampleProc.mRMSSD, $.mSampleProc.vEBeatCnt, $.mSampleProc.mNN50];
		$.mCircColSel = GG.generateResults( _stats);
		$.mGData = true;
		_stats = null;
		
		//v1.0.3 on large devices we trigger saving
		mWaitDump = false; // don't wait for dump to complete on small devices
		fDumpSetup();
		
		//0.6.3 switch to new view
		Ui.switchToView($.getView(GLANCE_VIEW ), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);

    } // end save test


(:LargeExclude) // small devices
	function fDumpSetup() {return;}

(:SmallExclude) // large devices
	function fDumpSetup() {
	
		// no samples!
		if ($.mSampleProc == null) { mWaitDump = false; return;}
			
		mStorage.PrintStats();

		Sys.println("Dumping intervals");
		
		// if no data then exit
		if (!Dump.sizeBlocks()) {return;}
	
		// setup timer for test dump
		dumpTimer = new Timer.Timer();
		dumpTimer.start(method(:DumpTiEnded),100,true); // repeat
		// setup other variables
		mWaitDump = true; // hold state machine until strings output
		mBlk = 0; // walker for array
		mDType = 0; // intervals then flags
    }

(:SmallExclude) // large devices
	// Dump timer has triggered so we need to chek progress and write next block if needed
	// if reached end turn off timer and allow s/m to progress
	// to separate intervals and flags going to have to do in two halves
	// first write will be intervals, second block of flags
	function DumpTiEnded() {
		// see which type we are writing - end only when done second set of data
		var mDone;
		
		// failsafe if spurious tick
		if (mWaitDump == false) {return;}
		
		if (mDType == 0) {
			// returns true if completed array dump
			mDone = Dump.writeStrings( mDType, mBlk);
			mBlk++;
			if (mDone) { mBlk = 0; mDType = 1; }
		} else {
			mDone = Dump.writeStrings( mDType, mBlk);
			mBlk++;
			if (mDone) { 
				// end state code
				dumpTimer.stop();
				mWaitDump = false;
				Dump.DumpHist(); 
				Dump.DumpHRV();
			}
		}
	}
    
	// called by startTest() to initial test timers etc
    function start() {
		Sys.println("start() ENTERED");
		// Set up test type and timer up or down.

		resetTest();
		//Sys.println("TestControl: start() - clearing stats and interval buffer");
    	//$.mSampleProc.resetSampleBuffer();
		$.mSensor.mHRData.initForTest();

		mManualTestStopTime = 0;
		testTimer.stop();	// This is in case user has changed test type while waiting

    	var testType = $.testTypeSet;

    	if(TYPE_MANUAL == testType){
 			// kick off a timer for max period of testing allowed
 			// going to stop a manual test at the time set by user OR when Start pressed again
 			// note value here is in elapsed seconds
 			mManualTestStopTime = $.mManualTimeSet;
			testTimer.start(method(:timerEnded),$.mMaxTimerTimeSet*1000,false); // false
    	} else {
    		// kick off a timer for period of test
    		timerTime = $.timerTimeSet;
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
