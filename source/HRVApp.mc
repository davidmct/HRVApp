using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties as Property;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Attention;
using Toybox.System as Sys;
using Toybox.Sensor;

// we should be saving results to storage NOT properties
//Storage.setValue( tag, value) eg ("results_array", results); where results is an array

// home page timer placement needs fixing if >1hr...

// Things still to fix
//2. Need to make sure any Delegate Pop's view when done
//3. check initialisation of storage and properties on first run to avoid null on read
//5. Redo HRV measurements and fix graph
//6. Add poincare view - look at onPartialUpdate...
//7. History and HRV plot over time views
//8. change summary page to include rMSSD SSRR(10, 20...), skipped or double beats
//9. how to make trial version and possible payment
//10. Revise ANT/Sensor handling to provide choice between them!!
//11. Move all time functions to use libraries to avoid time wrap - 136 years so maybe no tissue
// "using-relative-layouts-and-textarea WatchUi.TextArea for scaling to fit window

var mDebugging = true;
var mDebuggingANT = false;
var mDumpIntervals = true;

// access App variables and classes
var _mApp;

using Toybox.Lang;

class myException extends Lang.Exception {
    function initialize(message) {
    	Sys.println(message);
        Exception.initialize();
    }
}

enum {
	// Device types
	EPIX = 0,
	FENIX = 1,
	FORERUNNER = 2,
	VIVOACTIVE = 3,
	FENIX6 = 4,

	// Views
	TEST_VIEW = 0,
	RESULT_VIEW = 1,
	HISTORY_VIEW = 2,
	HRVPLOT_VIEW = 3,
	POINCARE_VIEW = 4,
	NUM_VIEWS = 5
}

//enum {
	// Colors index. Arrays start at zero
const 	WHITE = 0;
const	LT_GRAY = 1;
const	DK_GRAY = 2;
const	BLACK = 3;
const	RED = 4;
const	DK_RED = 5;
const	ORANGE = 6;
const	YELLOW = 7;
const	GREEN = 8;
const	DK_GREEN = 9;
const	BLUE = 10;
const	DK_BLUE = 11;
const	PURPLE = 12;
const	PINK = 13;
const	TRANSPARENT = 14;
//}

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
	
	var mMenuTitleSize;
	var sensorType;

	// Results array variable
	var results;

	// View trackers
	var viewNum;
	var lastViewNum;

	var mFitWriteEnabled;   
    var mStorage;
    var mTestControl;
    var mIntervalSampleBuffer; // buffer in app space for intervals
    var mSampleProc; // instance of sample processor
    
    // ensure second update
    hidden var _uiTimer;
    const UI_UPDATE_PERIOD_MS = 1000;
    
    // Block size for dump to debug of intervals
    const BLOCK_SIZE = 40;
    
    function initialize() {
    	Sys.println("HRVApp INITIALISATION called");
        
        $._mApp = App.getApp();
         
        mStorage = new HRVStorageHandler();
        mTestControl = new TestController();
        mSampleProc = new SampleProcessing();
        mStorage.readProperties();  
        
        //mFitContributor = new AuxHRFitContributor(self);
             
		if (Toybox.Application has :Storage) {
			mAntID = $._mApp.Properties.getValue("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);	
			mFitWriteEnabled = $._mApp.Properties.getValue("pFitWriteEnabled"); 		
		} else {
			mAntID = $._mApp.getProperty("pAuxHRAntID");
			versionSet = Ui.loadResource(Rez.Strings.AppVersion);
			mFitWriteEnabled = $._mApp.getProperty("pFitWriteEnabled");
		}
		Sys.println("ANT ID set to : " + mAntID);
		//Menu title size
		mMenuTitleSize = Ui.loadResource(Rez.Strings.MenuTitleSize).toNumber();			
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
		device = Ui.loadResource(Rez.Strings.Device).toNumber();

// Move this to Sensor handling
// onStartSensor(mAntID) .. do we need to wrap a new class around AntHandler and AntHandler extends that
// then can have either route
// Also need menu option...
   		// Start up ANT device
	    try {
	    	//Create the sensor object and open it
	   		mSensor = new AntHandler(mAntID);
	    	//mSensor.openCh();
	    } catch(e instanceof Ant.UnableToAcquireChannelException) {
	    	System.println(e.getErrorMessage());
	   		mSensor = null;
	    }
	    
	    // set if we can find both ant and optical
	    //SensorSetup();
// end stuff to move
	    
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
		// initialise for testing
		mTestControl.resetTest();

    	// Init view variables
		viewNum = 0;
		lastViewNum = 0;

		// Init timers
		_uiTimer = new Timer.Timer();
		_uiTimer.start(method(:updateScreen), UI_UPDATE_PERIOD_MS, true);		
    }
    
    //! A wrapper function to allow the timer to request a screen update
    function updateScreen() {
    	// drive teststate transitions outside UI
    	mTestControl.UpdateTestStatus();
    	// update views
        Ui.requestUpdate();
    }
    
    //! onStop() is called when your application is exiting
    function onStop(state) {		
		if (state == null) { 		}
	
		mStorage.saveProperties();
		mTestControl.stopControl();
		_uiTimer.stop();
		
		// Dump all interval data to txt file on device
		if (mDumpIntervals == true) {DumpIntervals();}
		
		Sys.println("App stopped");
    }
    
   	// App running and Garmin Mobile has changed settings
	function onSettingsChanged() {
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
		
		Sys.println("Last view: " + lastViewNum + " current: " + viewNum);

		if(RESULT_VIEW == viewNum) {
			return new SummaryView();
		}
		else if(HISTORY_VIEW == viewNum) {
			return new HistoryView();
		}
		else if(HRVPLOT_VIEW == viewNum) {
			return new HrvPlotView();
		}
		else if(POINCARE_VIEW == viewNum) {
			return new PoincareView();
		}	
		else {
			return new TestView();
		}
	}
	
	function HRVStateChange(type) {
		if (type == null) {
			// ignore
		} 
		else if (type == :enterPressed) {
			return mTestControl.onEnterPressed();// call test controller		
		} 
		else if (type == :escapePressed) {
			return mTestControl.onEscapePressed();		
		}
		
		return true;	
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
		
		if (mDebugging == true) {
			Sys.println("DumpIntervals: mNumEntries " + mNumEntries);
			Sys.println("DumpIntervals: mNumBlocks " + mNumBlocks);	
			Sys.println("DumpIntervals: mRemainder " + mRemainder);						
		}
		
		// should propably use getSample(index) if using circular buffer
		for (i=0; i < mNumBlocks; i++) {
			base = i*BLOCK_SIZE;
			var j;
			for (j=0; j< BLOCK_SIZE; j++) {
				mString += mIntervalSampleBuffer[base+j].toString()+",";			
			}
			Sys.println(mString);		
		}
		mString = "";
		// Write tail end of buffer
		base = BLOCK_SIZE * mNumBlocks;
		for (i=0; i < mRemainder; i++) {	
			mString += mIntervalSampleBuffer[base+i].toString()+",";				
		}	
		Sys.println(mString);
	}
	
}


