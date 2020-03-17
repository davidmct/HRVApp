using Toybox.System as Sys;
using Toybox.Application.Properties as Property;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;

class HRVStorageHandler {

// if initial run then we should clear store
// Storage.clearValues();
// then save default set of properties

	var mApp;

	// setup storage functions	
    function initialize() {
    	mApp = App.getApp();

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

	function resetSettings() {

		// Retrieve default settings from file
		mApp.timestampSet = Ui.loadResource(Rez.Strings.Timestamp);
		mApp.appNameSet = Ui.loadResource(Rez.Strings.AppName);
		mApp.versionSet = Ui.loadResource(Rez.Strings.Version);

		mApp.greenTimeSet = Ui.loadResource(Rez.Strings.GreenTime).toNumber();
		mApp.soundSet = Ui.loadResource(Rez.Strings.Sound).toNumber();
		mApp.vibeSet = Ui.loadResource(Rez.Strings.Vibe).toNumber();
		mApp.testTypeSet = Ui.loadResource(Rez.Strings.TestType).toNumber();
		mApp.timerTimeSet = Ui.loadResource(Rez.Strings.TimerTime).toNumber();
		mApp.mMaxTimerTimeSet = Ui.loadResource(Rez.Strings.MaxTimerTime).toNumber();
		mApp.autoStartSet = Ui.loadResource(Rez.Strings.AutoStart).toNumber();
		mApp.autoTimeSet = Ui.loadResource(Rez.Strings.AutoTime).toNumber();
		mApp.mMaxAutoTimeSet = Ui.loadResource(Rez.Strings.MaxAutoTime).toNumber();
		
		Sys.println("autoTimeSet = " + mApp.autoTimeSet);
        Sys.println("mMaxAutoTimeSet = " + mApp.mMaxAutoTimeSet);
        Sys.println("autoStartSet = " + mApp.autoStartSet);
        
		// ColSet are index into colour map
		mApp.bgColSet = Ui.loadResource(Rez.Strings.BgCol).toNumber();
		mApp.lblColSet = Ui.loadResource(Rez.Strings.LblCol).toNumber();
		mApp.txtColSet = Ui.loadResource(Rez.Strings.TxtCol).toNumber();
		mApp.hrvColSet = Ui.loadResource(Rez.Strings.HrvCol).toNumber();
		mApp.avgHrvColSet = Ui.loadResource(Rez.Strings.AvgHrvCol).toNumber();
		mApp.pulseColSet = Ui.loadResource(Rez.Strings.PulseCol).toNumber();
		mApp.avgPulseColSet = Ui.loadResource(Rez.Strings.AvgPulseCol).toNumber();

		mApp.inhaleTimeSet = Ui.loadResource(Rez.Strings.inhaleTime).toNumber();
		mApp.exhaleTimeSet = Ui.loadResource(Rez.Strings.exhaleTime).toNumber();
		mApp.relaxTimeSet = Ui.loadResource(Rez.Strings.relaxTime).toNumber();
	}

	function readProperties() {
		// On very first use of app don't read in properties!
		var value;
		
		// FORCE NOT OVER WRITE
		value = mApp.getProperty(INITIAL_RUN);
		if (mDebugging == true) {value = null;}
			
		if (value == null) {
			mApp.setProperty(INITIAL_RUN, true);
		} else {
	    	value = mApp.getProperty(GREEN_TIME);
			if(null != value) {
				// ensure a reasonable minimum
				if(10 > value){
					value = 10;
				}
	    		mApp.greenTimeSet = value;
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
	    		mApp.timerTimeSet = value;
	    	}
	    	value = mApp.getProperty(AUTO_START);
			if(null != value) {
	    		mApp.autoStartSet = value;
	    	}
	    	value = mApp.getProperty(AUTO_TIME);
			if(null != value) {
	    		mApp.autoTimeSet = value;
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
	    		mApp.inhaleTimeSet = value;
	    	}
	    	value = mApp.getProperty(EXHALE_TIME);
			if(null != value) {
	    		mApp.exhaleTimeSet = value;
	    	}
	    	value = mApp.getProperty(RELAX_TIME);
			if(null != value) {
	    		mApp.relaxTimeSet = value;
	    	}
		}
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

		if(mApp.greenTimeSet != mApp.getProperty(GREEN_TIME)) {
    		mApp.setProperty(GREEN_TIME, mApp.greenTimeSet);
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
    		mApp.setProperty(TIMER_TIME, mApp.timerTimeSet);
    	}
		if(mApp.autoStartSet != mApp.getProperty(AUTO_START)) {
    		mApp.setProperty(AUTO_START, mApp.autoStartSet);
    	}
		if(mApp.autoTimeSet != mApp.getProperty(AUTO_TIME)) {
    		mApp.setProperty(AUTO_TIME, mApp.autoTimeSet);
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
    		mApp.setProperty(INHALE_TIME, mApp.inhaleTimeSet);
    	}
    	if(mApp.exhaleTimeSet != mApp.getProperty(EXHALE_TIME)) {
    		mApp.setProperty(EXHALE_TIME, mApp.exhaleTimeSet);
    	}
    	if(mApp.relaxTimeSet != mApp.getProperty(RELAX_TIME)) {
    		mApp.setProperty(RELAX_TIME, mApp.relaxTimeSet);
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

 