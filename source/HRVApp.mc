using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.System as Sys;
using Toybox.Sensor;
//using AuthCode as Auth;

using HRVStorageHandler as mStorage;

// Things still to fix
// Check old textArea code has right font size in Current and test views
//8b. Look at frequency domain processing
//9. Trial mode currently disabled
//13. When using optical should call it PRV not HRV
//17. Check download and setting online properties works

// v1.0.3 NOT DONE YET
// Added ability to select which zone max to use to scale plots 1..5
// Possible user range selection on poincare full and II chart. max bpm and min bpm
// maybe avriable buffer length depending on memory - and hence max time???

// 1.0.2 in dev
// Added dump of history and HRV to log file
// Bug fixed was saving MAX_DIFF in History twice
// fixed bug on backlight turn on for Venu2S - doesn't exist. test for capability

// 1.0.0 / 1.0.1 as .0 not published
// Memory optimisation... remove some constants
// Reorder STATS view data to be more logical
// Colour #II purple if >= storage length
// Fixed reset glance data bug (trying to write null as data fails though in API should be OK
// Change first load to storage not property
// fix bug: after menu reset of results mGData left true causing blank display on dial view

//0.7.2
// Added Forerunner 945LTE

//0.7.1
// Bug Fixes: 
	// Trial fix for settings crash when app not running: Reorder initialisation to read properties etc in onStart() not initialize()
	// Fixed overlong timer on manual test. Auto and manual max now 6 mins @ 160 BPM
	// Fixed bug on duration entry - now limited to 5:59 (max buffer length)
	// Reduced memory usage on 4.x.x devices as OS seems to take more
	// If interval buffer fills then it will stop capturing samples but run the test to completion. Some displays will stop updating
// New functionality:
	// User device HR zone 1 max HR and resting to scale charts using "Auto scale"
	// Auto scale:
		//II:  when true - use data range in II. When false use 
		//Poincare: when true max set by constants in Poincare.
		//False = zone based scale. Used resting HR to max Zone 1 as set on watch for default activity

//0.7.0
// tried to fix startup crash

// 0.6.8
// added Descent Mk2s
// Setting LnRMSD mult from connectseems to crash watch
// Need to change trends screen plot point if background is white

// 0.6.7
// added enduro, venu2 and venu2S

// 0.6.6
// Turn off Strap if on and CIQ >=3.2
// Fixed trend draw bug
// Note: trends are drawn after 3 days for a week, 28 for month and 45 for long term

//0.6.5
// Adding second history screen with HRV data plot over as many days as fits on screen along with trend lines
// Remove (I) indicator as now not needed and changed to FIT status
// Added ability to select Ln(RMSSD) or RMSSD on test view via setting. Also changed range of scale factor.
// Fixed bug in glance data sortedDays. Used Count as gap in days but needed real days count as well for trend .. to put in Widget
// Turn on backlight when HRV trend results shown
// Threshold now stored as integer to stop language issues giving wrong values
// 

// 0.6.4
// Made sensor selection exclusive on CIQ > 3.2
// Added VenuSQ
// adjusted font for all 240x240 devices on all screens
// Fixed rendering alignment issues on history view graphs

//0.6.3 Changes
// Memory optimisations to fit new functionality
// Added new HRV trend functions
// Stop menu load during test on memory limited devices (otherwise no memory for save)
// Fixed memory leak on menu pop
// Fixed very first run issue on history graph
// Fixed text size on Approach
// Removed D2 support except Air as ANT+ code needed to support beat to beat intervals

// 0.5.5
// New algorithm for threshold detection using forward and backward average make group delay 0

//0.4.7 
// Added plot of beats over last N sammples
// Added missed and skipped beat detection
// Can I add payment link to settings???
// Need to UPDATE
// 1. Menu system for setting thresholds - DONE
// 2. FIT file update using new variables _ PARTIAL. added fit structure
// 3. Update stats pages with new variables for beats -DONE
// 4. Do I add double/missed to History display and store??
// 5. Sample processing itself
// 6. Beat display chart - DONE. Needs full testing
// 7. Restructure ,menus to save memory - move settings up a level DONE. Little saving
// 8. Can anything be moved to JSON data? MOSTLY DONE
//		-colours and mColourNumbersString good candiates but would need to hard code values. can remove enum as well
//		- also possibly history maps and then threshold (needed on save and menu operation
// 9. Check memory use during runs and what is consuming most data

//0.4.5 
// Fixed sensor switch bug
// new poincare view

//0.4.4
// Change debug method for time critical parts

// 0.4.3
// Added ability to set colour and name on history via settings and aligned menu system
// need to change MainMenuDelegate to have which history item to select and then use existing menu create of list of options.
// select only one item but none is OK. This currently uses HistoryMenuDelegate so would need an intermediate menu
// Colours not yet setable for history item but should be extension of ColourMenuDelegate
// Ensure Ln(rMSSD) doesn't go negative
// devSumSq to float to make sure doesn't go over range of integer
// DONE

// 0.4.2
// Removed property causing random errors
// 

//v0.4.xx+ revisions post initial release
//1. Look at all strings to resources (check saves memory) - aids language translation if needed (may not help)
//2. Frequency based parameters - need to research
//3. See if we can use settings to select which parameters to display in history. Need to map to dictionary

// ADDED in 0.4.1
//4. See if I can add FIT write status on current view - use white to show enabled and red to show active
//5. Add summary field to FIT that shows which sensor acquired data ie int or ext
 
// 0.4.05
// Fixed bug in FIT close on excape when not enough samples
// Added FIT write indicator
 
// Optimisations:
// - check no string assignment in loops. Use Lang.format()
// - any more local vars rather than global
// - reduce dictionaries 
// - -g option on compiler to see code generated
// - use function if any code repeated
// - don't use enums as fail on bit wise
// - don't use classes when you can use static functions or inline code
// - avoid try etc and replace with if/global var
// - eliminate classes where possible
// - build file for removing device specifics from code (maintenance a challenge)
// - could have jungle file with screen size constants as literals
// - reduce length of resource id's
// - don't declare string resources you don't need
// - precalculate values used a lot and load as needed
// - use JSON data resources (resources file) which can store values, dictionaries, arrays etc and 
//   load using var thing = Ui.loadResoruce(Rez.JsonData.xxx);
//   <resources> jsonData id ="xxx"> what ever </jsonData>
//   

var mDebugging = false;
//var mDebuggingANT = false;
var mDumpIntervals = true;
var mDumpHist = true; //also HRV list

// access App variables and classes
//var _mApp;

using Toybox.Lang;

//class myException extends Lang.Exception {
//    function initialize(message) {
//    	Sys.println(message);
//        Exception.initialize();
//		//Exception.printStackTrace;
//    }
//}

// Settings variables
//var timestampSet;
var appNameSet;
var mTestMode = false; // add functions for testing

var soundSet;
var vibeSet;
var testTypeSet;
var timerTimeSet;
var mManualTimeSet;
var mMaxTimerTimeSet;
var bgColSet;
var lblColSet;
var txtColSet;
// History labels
var Label1ColSet;
var Label3ColSet;
var Label2ColSet;

// actual values of colour based on ColSet index
// saves lots of UI resource loads and func calls
var mLabelColour;
var mValueColour;
var mBgColour;
var mHRColour;
var Label1Colour;		
var Label2Colour;
var Label3Colour;
//0.4.3 
//add variables for history text index
var mHistoryLabel1;
var mHistoryLabel2;
var mHistoryLabel3;	

//0.4.6
var mNumberBeatsGraph;

//0.6.0
var mLogScale = LOG_SCALE;

var mMenuTitleSize;
//var mDeviceID = null;

// Results array variable
var results;
//var mHistorySelectFlags;
// write pointer into results array
var resultsIndex;

// View trackers
var viewNum;
var lastViewNum;

var mFitWriteEnabled;   
//var mStorage;
var mTestControl;
var mIntervalSampleBuffer; // buffer in app space for intervals

// MAX_TIME * MAX_BPM = 6 minutes * 160 at the moment
// need to change if time changes
var mMaxBuf = MAX_BUF; 

var mSampleProc; // instance of sample processor
var mFitControl;

// % permitted deviation from average for ectopic beats
var vUpperThresholdSet; // long % over
var vLowerThresholdSet; // short period under %

// if true then display rMSSD otherwise LN version
var mRM = false;

// The device type
var mDeviceType;
//var customFont; // load in init if low res. saves load in every view

//var mApp;
var mSensor;
var mAntID;
//var mAuxHRAntID; // found sensor ID
// true if external unknown strap ie not enabled in watch
// 1 = true, 0 = false and INTERNAL_SENSOR
var mSensorTypeExt;

// Auto scale when true - use data range in II or max set by constants in Poincare
// False = zone based. resting to max Zone 1
var mBoolScale;

var glanceData = new [12];
var mGData = false;
//var mArcCol = [Gfx.COLOR_DK_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_DK_GREEN, Gfx.COLOR_GREEN];
var mArcCol = [0xff0000, 0xffff00, 0x00ff00, 0x0055ff];
// colour of arrow display
var mCircColSel;

// 0.7.1
var mRestingHR_II;
var mZone1TopHR_II;
		
class HRVAnalysis extends App.AppBase {
  
    // ensure second update
    hidden var _uiTimer;
    const UI_UPDATE_PERIOD_MS = 1000;

(:storageMethod) 
    function initializeWithStorage() {
		//mAntID = Properties.getValue("pAuxHRAntID");
		//mAuxHRAntID = mAntID; // default
		
		$.mFitWriteEnabled = Properties.getValue("pFitWriteEnabled"); 
		$.mTestMode = Store.getValue("pTest"); 
		Sys.println("T:"+$.mTestMode);
		
		mSensorTypeExt = SENSOR_INTERNAL;
		//mSensorTypeExt = Properties.getValue("pSensorSelect");	
		
		//Auth.init();		      
    }   
    
    function initialize() {	
    	AppBase.initialize();
    }
    
    //! Return the initial view of your application here
    function getInitialView() {
    		    
    	if (mDebugging) { Sys.println("HRVApp: getInitialView() called"); }   	
    	viewNum = 0;
		lastViewNum = 0;
		return [ new TestView(), new HRVBehaviourDelegate() ];
    }
    
    function scaleRangeHR() {
    	// get resting heart rate
		var restingHR = UserProfile.getProfile().restingHeartRate;
		var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
		
		// average resting is 3.2.0 feature so remove
		//Sys.println("Resting HR = "+profile.restingHeartRate+", avg ="+profile.averageRestingHeartRate);
		
		// set floor on fixed scaling for II - provide a little headroom of 5bpm as mine varies below watch value 5%
		
		// RANGE CHECK restingHeart rate and zone 1 to make sure sensible		
		//mRestingHR_II = ( profile.restingHeartRate == null ? SLOW_II : (60000 / (profile.restingHeartRate * 0.95)).toNumber());
		var mTemp = 60000;
		if (restingHR == null) {
			$.mRestingHR_II = SLOW_II;
		} else if (restingHR == 0) {
			$.mRestingHR_II = SLOW_II;
		} else {
			$.mRestingHR_II = (mTemp.toFloat() / (restingHR.toFloat() * 0.95)).toNumber();
		}
		
		//mRestingHR_II = ( restingHR == null ? SLOW_II : (60000 / (restingHR.toFloat() * 0.95)).toNumber());
		
		if (zones != null && zones[1] != null) {
			$.mZone1TopHR_II = (mTemp.toFloat() / (zones[1] * 1.05)).toNumber();
		} else {		
			$.mZone1TopHR_II = FAST_II;
		}
		
		//profile = null;
		restingHR = null;
		zones = null;
		mTemp = null;
				
		Sys.println("Floor HR ms = "+$.mRestingHR_II+" BPM: "+60000/$.mRestingHR_II);
		Sys.println("Top HR ms = "+$.mZone1TopHR_II+" BPM: "+60000/$.mZone1TopHR_II);   
    
    }
    
    //! onStart() is called on application start up
    function onStart(state) {
        Sys.println("HRVApp INIT for version: "+Ui.loadResource(Rez.Strings.AppVersion));
        //$._m$.pp.getApp();

		Sys.println("Small memory="+SMALL);
        
        // Retrieve device type
		mDeviceType = Ui.loadResource(Rez.Strings.Device).toNumber();
		
		// defensive programming to ensure all variables initialised
		
		// This fails on some devices occasionally!!
// REMOVED in v1.0.0		
		//Sys.println("first="+Properties.getValue("firstLoadEver"));
		
		//if (Properties.getValue("firstLoadEver") == true) {
		//	// this also resets flag
		//	mStorage.resetSettings();
		//	Sys.println("First run reset");
		//}
		
		//Sys.println("first="+Properties.getValue("firstLoadEver"));
// END OF REMOVED CODE

// revised version using storage v1.0.0
		var mFirst = true;
		
		try {
			// should return null if not in store
			mFirst = Store.getValue("FS");		
		} catch (e) {
			// should fall through to finally with mFirst = true
			Sys.println("FL err");
		} finally {
			if ((mFirst == null)|| (mFirst == true)) {
				 mStorage.resetSettings();
				 Sys.println("FL");
				 Storage.setValue("FS", false);
			} else {
				Sys.println("!FL");
			}
		}
// END Revised code
	        
        //mStorage = new HRVStorageHandler(self);
        // ensure we have all parameters setup before needed
        mStorage.readProperties();  
                
        mTestControl = new TestController();
        mSampleProc = new SampleProcessing();
       
        mFitControl = null; // no FIT created yet
               
		//A unique alphanumeric device identifier.
		//The value is unique for every app, but is stable on a device across uninstall and reinstall. 
		//Any use of this value for tracking user information must be in compliance with international privacy law.
		//0.7.1 removed as not used except for trial mode etc
		//var mySettings = Sys.getDeviceSettings();
        
        //mDeviceID = mySettings.uniqueIdentifier;
        //mDeviceID = null;
             
		if (Toybox.Application has :Storage) {
			initializeWithStorage();				
		} else {
			//initializeNoStorage();
		}
		
		//Sys.println("HRVApp: Initial ANT ID set to : " + mAntID);
		Sys.println("HRVApp: SensorType = "+mSensorTypeExt);
		//Sys.println("Is app in trial mode? "+AppBase.isTrial());
		//Sys.println("Trial properties: "+mTrialMode+","+mTrialStartDate+","+mTrialStarted+","+mAuthorised+","+mTrailPeriod);
    			
		//Auth.UpdateTrialState();
		
		//Menu title size
		mMenuTitleSize = Ui.loadResource(Rez.Strings.MenuTitleSize).toNumber();	
		// Retrieve device type
		//mDeviceType = Ui.loadResource(Rez.Strings.Device).toNumber();

   		// Start up HR sensor. Create the sensor object and open it
	   	mSensor = new SensorHandler(mAntID, mSensorTypeExt);

	   	Sys.println("HRVApp: onStart() Sensor set to "+mSensorTypeExt);
	   	
	   	// now setup sensors as have created data structures
	   	mSensor.SetUpSensors();
	    
	    //if (mDebugging) {
	    //	Sys.println("HRVApp: sensor created: " + mSensor);
	    //	Sys.println("HRVApp: Sensor channel open? " + mSensor.mHRData.isChOpen);
	    //}

		// 0.4.9 Don't do this unless needed
		// Retrieve saved results from memory
		// create and clear buffer - only one set per day
		//mStorage.resetResults();
		
		// 0.4.9 Don't do this unless needed
		//restore previous results from properties/store		
		//mStorage.retrieveResults();
		
		// initialise for testing
		mTestControl.resetTest();
		
		// strictly speaking no need to create FIT contributor unless we want to write
		// however we then lose all the functions
		mFitControl = new HRVFitContributor();

    	// Init view variables
		viewNum = TEST_VIEW;
		lastViewNum = TEST_VIEW;
		
		// No glance data available
		mGData = false;
		
		//0.7.1 - work out HR range of user for defined range on scales
		scaleRangeHR();

		// Init timers
		_uiTimer = new Timer.Timer();
		_uiTimer.start(method(:updateScreen), UI_UPDATE_PERIOD_MS, true);	
		
		// create views .. rather than every time view is called
		// only issue might be initialisation each time
		//mPoincare_view = new PoincareView();	
		//mStatsView = new StatsView();
		//mHistoryView = new HistoryView();
		//mTestView = new TestView();
    }
    
    //var _cnt = 0;
    //! A wrapper function to allow the timer to request a screen update
    function updateScreen() {
    	// drive teststate transitions outside UI
    	mTestControl.StateMachine(:UpdateUI);
    	
    	// Update FIT data
    	mFitControl.compute();
    	   	
    	// output any debug if present
    	$.FlushMsg();
    	
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
		if (mDumpHist == true) {DumpHist(); DumpHRV();}
		
		//0.6.3 No point saving interval strings to storage as not separate from app. Already in Interval Array 
		//mStorage.saveIntervalStrings();
		
		Sys.println("Closing sensors");
		if (mSensor != null) {
			mSensor.CloseSensors();
			mSensor = null;
		} 
		
		Sys.println("App stopped");
    }
    
   	// App running and Garmin Mobile has changed settings
	function onSettingsChanged() {
		Sys.println("Settings changed on connect");
		// DO NOTHING AT MOMENT - next restart will impact
		// update any things depending on storage functions
		
		//0.4.04
		// read in changed data
		// check old state of sensor and test type
		//var oldSensor = mSensorTypeExt;
		var oldTestType = testTypeSet;
		var oldFitWrite = $.mFitWriteEnabled;
 
		// reload properties
		mStorage.onSettingsChangedStore();
		
		// check whether we need to switch
		//$.mTestControl.fCheckSwitchType( :SensorType, oldSensor);    
        // if type has changed then force restart of state machine  
        $.mTestControl.fCheckSwitchType( :TestType, oldTestType); 
        // and if write state has changed!!
        $.mTestControl.fCheckSwitchType( :FitType, oldFitWrite); 
        			
		// restart start machine
		mTestControl.StateMachine(:RestartControl);
		
		Ui.requestUpdate();
	}

	
	function writeStrings(_type, _mNumBlocks, _mRemainder) {
	    // Block size for dump to debug of intervals
  		var BLOCK_SIZE = 40;
		var mString;
		var base;
		var mSp;
		var separator = ",";
	
		mString = ( _type == 0 ? "II:," : "Flags:,");

		for (var i=0; i < _mNumBlocks; i++) {
			base = i*BLOCK_SIZE;
			var j;
			for (j=0; j< BLOCK_SIZE; j++) {
				mSp = mIntervalSampleBuffer[base+j];
				mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
				mString += mSp.toString()+separator;				
			}
			Sys.println(mString);
			mString = "";		
		}
		mString = "";
		// Write tail end of buffer
		base = BLOCK_SIZE * _mNumBlocks;
		for (var i=0; i < _mRemainder; i++) {	
				mSp = mIntervalSampleBuffer[base+i];
				mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
				mString += mSp.toString()+separator;						
		}	
		Sys.println(mString);
	
	}
	
	function DumpIntervals() {
		// to reduce write time group up the data
		var BLOCK_SIZE = 40;
		
		if (mSampleProc == null) { return;}
		
		var mNumEntries = mSampleProc.getNumberOfSamples();

		mStorage.PrintStats();
				
		if (mNumEntries > $.mIntervalSampleBuffer.size() - 1) {
			Sys.println("Buffer overrun - no dump");
			return;
		}
		if (mNumEntries <= 0) { return;}
		
		var mNumBlocks = mNumEntries / BLOCK_SIZE ;
		var mRemainder = mNumEntries % BLOCK_SIZE ;
		var mString = "II:, ";
		var i;
		var base;
		var mSp;		

		Sys.println("Dumping intervals");
		
		//if (mDebugging == true) {
		//	Sys.println("DumpIntervals: mNumEntries, blocks, remainder: " + mNumEntries+","+ mNumBlocks+","+ mRemainder);				
		//}
		
		// save memory by removing code lines
		// type 0 = II, 1 = flags
		writeStrings(0, mNumBlocks, mRemainder);
		
		writeStrings(1, mNumBlocks, mRemainder);
	}
	
	// put all valid History entries into LOG
	function DumpHist() {
	
		var mMsg =  "";
		// load results array from store
		// returns true if successful and $.resultsIndex != 0 
		mStorage.retrieveResults();
		if ( $.results == null || $.resultsIndex ==0) {Sys.println("no Hist dump"); return;}

		// Labels
		mMsg = "History: time; Avg HR, Min_II, Max_II, Min Diff, Max Diff, RMSSD, LogHRV, SDNN, SDSD, NN50, pNN50, NN20, pNN20";
		Sys.println(mMsg);		
		
		// dump all data -- could just do this but format unfriendly for table
		//Sys.println( $.results);
						
		// Now iterate through the non-zero time stamps
		var index = 0;
		for (var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			index = i * DATA_SET_SIZE;
			mMsg = "";
			if ($.results[index] == 0) {
				// no entry in array
				continue;
			}
			for ( var j = 0; j < DATA_SET_SIZE; j++) {
				mMsg = mMsg+ $.results[index+j]+", ";
			} 
			Sys.println(mMsg);		
		}
			
		mMsg = null;
		$.results = null;		
		return;	
			
	}		
	
	function DumpHRV() {
		var mHRV;
		var mMsg =  "";
		
		if (Toybox.Application has :Storage) {
			mHRV = Store.getValue("resultsArrayW");
		} else {
			return;
		}
		
		if (mHRV == null) { return;}
		Sys.println("Dump HRV log [date, value]:");
		
		for (var i=0; i < mHRV.size(); i += 2) {
			if (mHRV[i] == 0) { continue;}
			mMsg = mHRV[i]+ ", " + mHRV[i+1] + ", ";
			Sys.println(mMsg);	
		}
		
		mMsg = null;
		mHRV = null;
	
	}
	
}


