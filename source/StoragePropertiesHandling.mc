using Toybox.System as Sys;
using Toybox.Application.Properties as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;

enum {
	// Settings memory locations
	TIMESTAMP = 0,
	APP_NAME = 1,
	VERSION = 2,
	FIT_STATE = 5,
	SOUND = 6,
	VIBE = 7,
	TEST_TYPE = 8,
	TIMER_TIME = 9,
	MANUAL_TIME = 10,
	MAX_MANUAL_TIME = 11,
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
	
	// Samples needed for stats min
	MIN_SAMPLES = 20

}

class HRVStorageHandler {

// if initial run then we should clear store
// Storage.clearValues();
// then save default set of properties

	var mApp;
	
	hidden var timestampSetTxt;
	hidden var appNameSetTxt;
	hidden var versionSetTxt;
	hidden var mFitWriteEnabled;
	hidden var soundSetTxt;
	hidden var vibeSetTxt;
	hidden var testTypeSetTxt;
	hidden var timerTimeSetTxt;
	hidden var mMaxTimerTimeSetTxt;
	hidden var mManualTimeSetTxt;
      
		// ColSet are index into colour map
	hidden var bgColSetTxt;
	hidden var lblColSetTxt;
	hidden var txtColSetTxt;
	hidden var hrvColSetTxt;
	hidden var avgHrvColSetTxt;
	hidden var pulseColSetTxt;
	hidden var avgPulseColSetTxt;

	hidden var inhaleTimeSetTxt;
	hidden var exhaleTimeSetTxt;
	hidden var relaxTimeSetTxt;

	// setup storage functions	
    function initialize() {
    	mApp = App.getApp();
    	// create buffers here? use function so external can call parts
    	
    	// load up resource strings
    	timestampSetTxt = Rez.Strings.Timestamp;
		appNameSetTxt = Rez.Strings.AppName;
		versionSetTxt = Rez.Strings.Version;
		mFitWriteEnabled = Rez.Strings.FitFileWrite;
		soundSetTxt = Rez.Strings.Sound;
		vibeSetTxt = Rez.Strings.Vibe;
		testTypeSetTxt = Rez.Strings.TestType;
		timerTimeSetTxt = Rez.Strings.TimerTime;
		mMaxTimerTimeSetTxt = Rez.Strings.MaxTimerTime;
		mManualTimeSetTxt = Rez.Strings.ManualTime;
      
		// ColSet are index into colour map
		bgColSetTxt = Rez.Strings.BgCol;
		lblColSetTxt = Rez.Strings.LblCol;
		txtColSetTxt = Rez.Strings.TxtCol;
		hrvColSetTxt = Rez.Strings.HrvCol;
		avgHrvColSetTxt = Rez.Strings.AvgHrvCol;
		pulseColSetTxt = Rez.Strings.PulseCol;
		avgPulseColSetTxt = Rez.Strings.AvgPulseCol;

		inhaleTimeSetTxt = Rez.Strings.inhaleTime;
		exhaleTimeSetTxt = Rez.Strings.exhaleTime;
		relaxTimeSetTxt = Rez.Strings.relaxTime;
    }

	// message from Garmin that settings have been changed on mobile - called from main app
	function onSettingsChangedStore() {
		// should probably stop any test and reload settings

	}
	// use Property and store for CIA 2.4 on
	// Property.getValue(name as string);
	//Property.setValue("mystetting", mySetting);
	
	// if (Toybox.Application has :Storage) {
	// use Storage and Property methods
	//} else {
	// use Application.AppBase methods
	// app.getProperty() and app.setProperty()
	//}

// date settings from Garmin are in UTC so use Gregorian.utcInfo() when working with these in place of Gregorian.info()

	
	// This should be factory default settings and should write values back to store
	function resetSettings() {
		// Retrieve default settings from file
		mApp.timestampSet = Ui.loadResource(TimestampSetTxt);
		mApp.appNameSet = Ui.loadResource(AppNameSetTxt);
		mApp.versionSet = Ui.loadResource(VersionSetTxt);
		mApp.mFitWriteEnabled = Ui.loadResource(FitFileWriteSetTxt).toNumber();
		mApp.soundSet = Ui.loadResource(SoundSetTxt).toNumber();
		mApp.vibeSet = Ui.loadResource(VibeSetTxt).toNumber();
		mApp.testTypeSet = Ui.loadResource(TestTypeSetTxt).toNumber();
		mApp.timerTimeSet = Ui.loadResource(TimerTimeSetTxt).toNumber();
		mApp.mMaxTimerTimeSet = Ui.loadResource(MaxTimerTimeSetTxt).toNumber();
		mApp.mManualTimeSet = Ui.loadResource(ManualTimeSetTxt).toNumber();
      
		// ColSet are index into colour map
		mApp.bgColSet = Ui.loadResource(BgColSetTxt).toNumber();
		mApp.lblColSet = Ui.loadResource(LblColSetTxt).toNumber();
		mApp.txtColSet = Ui.loadResource(TxtColSetTxt).toNumber();
		mApp.hrvColSet = Ui.loadResource(HrvColSetTxt).toNumber();
		mApp.avgHrvColSet = Ui.loadResource(AvgHrvColSetTxt).toNumber();
		mApp.pulseColSet = Ui.loadResource(PulseColSetTxt).toNumber();
		mApp.avgPulseColSet = Ui.loadResource(AvgPulseColTxt).toNumber();

		mApp.inhaleTimeSet = Ui.loadResource(inhaleTimeTxt).toNumber();
		mApp.exhaleTimeSet = Ui.loadResource(exhaleTimeTxt).toNumber();
		mApp.relaxTimeSet = Ui.loadResource(relaxTimeTxt).toNumber();
		
		// need to write back
	}

	function readProperties() {	
		if (Toybox.Application has :Storage) {
			_CallReadPropStorage();
		} else {
			_CallReadPropProperty();
		}
	}	
	
		

	function _CallReadPropProperty() {	
		// On very first use of app don't read in properties!
		var value;
		
		// FORCE NOT OVER WRITE
		value = mApp.getProperty(INITIAL_RUN);
		if (mDebugging == true) {value = null;}
			
		if (value == null) {
			mApp.setProperty(INITIAL_RUN, true);
		} else {
	    	value = mApp.getProperty(FIT_STATE);
			if(null != value) {
	    		mApp.mFitWriteEnabled = value;
	    	}
	    	value = mApp.getProperty(SOUND);
			if(null != value) {
	    		mApp.soundSet = value;
	    	}
	    	value = mApp.getProperty(VIBE);
			if(null != value) {
	    		mApp.vibeSet = value;
	    	}
	    	value = mApp.getProperty(TEST_TYPE);
			if(null != value) {
	    		mApp.testTypeSet = value;
	    	}
	    	value = mApp.getProperty(TIMER_TIME);
			if(null != value) {
	    		mApp.timerTimeSet = value.toNumber();
	    	}
	    	value = mApp.getProperty(MANUAL_TIME);
			if(null != value) {
	    		mApp.mManualTimeSet = value.toNumber();
	    	}
	    	value = mApp.getProperty(MAX_MANUAL_TIME);
			if(null != value) {
	    		mApp.mMaxTimerTimeSet = value.toNumber();
	    	}	    	
	    	value = mApp.getProperty(BG_COL);
			if(null != value) {
	    		mApp.bgColSet = value;
	    	}
	    	value = mApp.getProperty(LABEL_COL);
			if(null != value) {
	    		mApp.lblColSet = value;
	    	}
	    	value = mApp.getProperty(TEXT_COL);
			if(null != value) {
	    		mApp.txtColSet = value;
	    	}
	
	    	value = mApp.getProperty(INHALE_TIME);
			if(null != value) {
	    		mApp.inhaleTimeSet = value.toNumber();
	    	}
	    	value = mApp.getProperty(EXHALE_TIME);
			if(null != value) {
	    		mApp.exhaleTimeSet = value.toNumber();
	    	}
	    	value = mApp.getProperty(RELAX_TIME);
			if(null != value) {
	    		mApp.relaxTimeSet = value.toNumber();
	    	}
		}
	}
	
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		
		mApp.timestampSet = Property.getValue(TimestampTxt);
		mApp.appNameSet = Property.getValue(AppNameTxt);
		mApp.versionSet = Property.getValue(VersionTxt);
		mApp.mFitWriteEnabled = Property.getValue(FitFileWriteTxt).toNumber();
		mApp.soundSet = Property.getValue(SoundTxt).toNumber();
		mApp.vibeSet = Property.getValue(VibeTxt).toNumber();
		mApp.testTypeSet = Property.getValue(TestTypeTxt).toNumber();
		mApp.timerTimeSet = Property.getValue(TimerTimeTxt).toNumber();
		mApp.mMaxTimerTimeSet = Property.getValue(MaxTimerTimeTxt).toNumber();
		mApp.mManualTimeSet = Property.getValue(ManualTimeTxt).toNumber();
      
		// ColSet are index into colour map
		mApp.bgColSet = Property.getValue(BgColTxt).toNumber();
		mApp.lblColSet = Property.getValue(LblColTxt).toNumber();
		mApp.txtColSet = Property.getValue(TxtColTxt).toNumber();
		mApp.hrvColSet = Property.getValue(HrvColTxt).toNumber();
		mApp.avgHrvColSet = Property.getValue(AvgHrvColTxt).toNumber();
		mApp.pulseColSet = Property.getValue(PulseColTxt).toNumber();
		mApp.avgPulseColSet = Property.getValue(AvgPulseColTxt).toNumber();

		mApp.inhaleTimeSet = Property.getValue(inhaleTimeTxt).toNumber();
		mApp.exhaleTimeSet = Property.getValue(exhaleTimeTxt).toNumber();
		mApp.relaxTimeSet = Property.getValue(relaxTimeTxt).toNumber();	
	
	}

	function resetResults() {
		// not sure this will work as scope TBD!!!
		// results defined in HRVApp
		mApp.results = new [150];

		for(var i = 0; i < 150; i++) {
			mApp.results[i] = 0;
		}
	}
	
	function loadResults() {
		// currently references a results array in HRVApp
		for(var i = 0; i < 30; i++) {
			var ii = i * 5;
			var result = mApp.getProperty(RESULTS + i);
			if(null != result) {
				mApp.results[ii + 0] = result[0];
				mApp.results[ii + 1] = result[1];
				mApp.results[ii + 2] = result[2];
				mApp.results[ii + 3] = result[3];
				mApp.results[ii + 4] = result[4];
			}
		}
	}

    function saveTest()
    {
		var testDay = mApp.utcStart - (utcStart % 86400);
		var epoch = testDay - (86400 * 29);
		var index = ((testDay / 86400) % 30) * 5;
		var sumHrv = 0;
		var sumPulse = 0;
		var count = 0;

		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 3600) % 30) * 5;
		// REMOVE FOR PUBLISH
		//index = ((timeNow() / 60) % 30) * 5;

		mApp.results[index + 0] = mApp.utcStart;
		mApp.results[index + 1] = mApp.hrv;
		mApp.results[index + 2] = mApp.avgPulse;

		// Calculate averages
		for(var i = 0; i < 30; i++) {

			var ii = i * 5;

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
    	System.println(format("$1$-$2$-$3$T$4$:$5$:$6$,$7$,$8$,$9$,$10$",[
    		date.year,
    		date.month,
    		date.day,
    		date.hour,
    		date.min.format("%02d"),
    		date.sec.format("%02d"),
    		mApp.hrv,
    		mApp.avgPulse,
    		sumHrv / count,
    		sumPulse / count]));

		mApp.isNotSaved = false;
    	mApp.isSaved = true;
    }

	function saveProperties() {
		// Save settings to memory
    	if(mApp.timestampSet != mApp.getProperty(TIMESTAMP)) {
    		mApp.setProperty(TIMESTAMP, mApp.timestampSet);
    	}
    	if(mApp.appNameSet != mApp.getProperty(APP_NAME)) {
    		mApp.setProperty(APP_NAME, mApp.appNameSet);
    	}
		if(mApp.versionSet != mApp.getProperty(VERSION)) {
    		mApp.setProperty(VERSION, mApp.versionSet);
    	}
		if(mApp.mFitWriteEnabled != mApp.getProperty(FIT_STATE)) {
    		mApp.setProperty(FIT_STATE, mApp.mFitWriteEnabled);
    	}
		if(mApp.soundSet != mApp.getProperty(SOUND)) {
    		mApp.setProperty(SOUND, mApp.soundSet);
    	}
		if(mApp.vibeSet != mApp.getProperty(VIBE)) {
    		mApp.setProperty(VIBE, mApp.vibeSet);
    	}
		if(mApp.testTypeSet != mApp.getProperty(TEST_TYPE)) {
    		mApp.setProperty(TEST_TYPE, mApp.testTypeSet);
    	}
		if(mApp.timerTimeSet != mApp.getProperty(TIMER_TIME)) {
    		mApp.setProperty(TIMER_TIME, mApp.timerTimeSet.toString());
    	}
		if(mApp.mManualTimeSet != mApp.getProperty(MANUAL_TIME)) {
    		mApp.setProperty(TIMER_TIME, mApp.mManualTimeSet.toString());
    	}
 		if(mApp.mMaxTimerTimeSet != mApp.getProperty(MAX_MANUAL_TIME)) {
    		mApp.setProperty(TIMER_TIME, mApp.mMaxTimerTimeSet.toString());
    	}   	
		if(mApp.bgColSet != mApp.getProperty(BG_COL)) {
    		mApp.setProperty(BG_COL, mApp.bgColSet);
    	}
		if(mApp.lblColSet != mApp.getProperty(LABEL_COL)) {
    		mApp.setProperty(LABEL_COL, mApp.lblColSet);
    	}
		if(mApp.txtColSet != mApp.getProperty(TEXT_COL)) {
    		mApp.setProperty(TEXT_COL, mApp.txtColSet);
    	}
		if(mApp.hrvColSet != mApp.getProperty(HRV_COL)) {
    		mApp.setProperty(HRV_COL, mApp.hrvColSet);
    	}
		if(mApp.avgHrvColSet != mApp.getProperty(AVG_HRV_COL)) {
    		 mApp.setProperty(AVG_HRV_COL, mApp.avgHrvColSet);
    	}
		if(mApp.pulseColSet != mApp.getProperty(PULSE_COL)) {
    		mApp.setProperty(PULSE_COL, mApp.pulseColSet);
    	}
		if(mApp.avgPulseColSet != mApp.getProperty(AVG_PULSE_COL)) {
    		mApp.setProperty(AVG_PULSE_COL, mApp.avgPulseColSet);
    	}

    	if(mApp.inhaleTimeSet != mApp.getProperty(INHALE_TIME)) {
    		mApp.setProperty(INHALE_TIME, mApp.inhaleTimeSet.toString());
    	}
    	if(mApp.exhaleTimeSet != mApp.getProperty(EXHALE_TIME)) {
    		mApp.setProperty(EXHALE_TIME, mApp.exhaleTimeSet.toString());
    	}
    	if(mApp.relaxTimeSet != mApp.getProperty(RELAX_TIME)) {
    		mApp.setProperty(RELAX_TIME, mApp.relaxTimeSet.toString());
    	}
	}

	function saveResults() {
	    // Save results to memory
    	for(var i = 0; i < 30; i++) {
			var ii = i * 5;
			var result = mApp.getProperty(RESULTS + i);
			if(null == result || mApp.results[ii] != result[0]) {
				mApp.setProperty(RESULTS + i, [
					mApp.results[ii + 0],
					mApp.results[ii + 1],
					mApp.results[ii + 2],
					mApp.results[ii + 3],
					mApp.results[ii + 4]]);
			}
		}
	}
	
	
	
}

 