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
		x = mApp.isWaiting;
		Sys.println(" x is set to  "+x);
		Sys.println("app is " + mApp);
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
		timestampSet = Ui.loadResource(Rez.Strings.Timestamp);
		appNameSet = Ui.loadResource(Rez.Strings.AppName);
		versionSet = Ui.loadResource(Rez.Strings.Version);

		greenTimeSet = Ui.loadResource(Rez.Strings.GreenTime).toNumber();
		soundSet = Ui.loadResource(Rez.Strings.Sound).toNumber();
		vibeSet = Ui.loadResource(Rez.Strings.Vibe).toNumber();
		testTypeSet = Ui.loadResource(Rez.Strings.TestType).toNumber();
		timerTimeSet = Ui.loadResource(Rez.Strings.TimerTime).toNumber();
		mMaxTimerTimeSet = Ui.loadResource(Rez.Strings.MaxTimerTime).toNumber();
		autoStartSet = Ui.loadResource(Rez.Strings.AutoStart).toNumber();
		autoTimeSet = Ui.loadResource(Rez.Strings.AutoTime).toNumber();
		mMaxAutoTimeSet = Ui.loadResource(Rez.Strings.MaxAutoTime).toNumber();
		
		Sys.println("autoTimeSet = " + autoTimeSet);
        Sys.println("mMaxAutoTimeSet = " + mMaxAutoTimeSet);
        Sys.println("autoStartSet = " + autoStartSet);
        
		// ColSet are index into colour map
		bgColSet = Ui.loadResource(Rez.Strings.BgCol).toNumber();
		lblColSet = Ui.loadResource(Rez.Strings.LblCol).toNumber();
		txtColSet = Ui.loadResource(Rez.Strings.TxtCol).toNumber();
		hrvColSet = Ui.loadResource(Rez.Strings.HrvCol).toNumber();
		avgHrvColSet = Ui.loadResource(Rez.Strings.AvgHrvCol).toNumber();
		pulseColSet = Ui.loadResource(Rez.Strings.PulseCol).toNumber();
		avgPulseColSet = Ui.loadResource(Rez.Strings.AvgPulseCol).toNumber();

		inhaleTimeSet = Ui.loadResource(Rez.Strings.inhaleTime).toNumber();
		exhaleTimeSet = Ui.loadResource(Rez.Strings.exhaleTime).toNumber();
		relaxTimeSet = Ui.loadResource(Rez.Strings.relaxTime).toNumber();
	}

	function readProperties() {
		// On very first use of app don't read in properties!
		var value;
		
		// FORCE NOT OVER WRITE
		value = getProperty(INITIAL_RUN);
		if (mDebugging == true) {value = null;}
			
		if (value == null) {
			setProperty(INITIAL_RUN, true);
		} else {
	    	value = getProperty(GREEN_TIME);
			if(null != value) {
				// ensure a reasonable minimum
				if(10 > value){
					value = 10;
				}
	    		greenTimeSet = value;
	    	}
	    	value = getProperty(SOUND);
			if(null != value) {
	    		soundSet = value;
	    	}
	    	value = getProperty(VIBE);
			if(null != value) {
	    		vibeSet = value;
	    	}
	    	value = getProperty(TEST_TYPE);
			if(null != value) {
	    		testTypeSet = value;
	    	}
	    	value = getProperty(TIMER_TIME);
			if(null != value) {
	    		timerTimeSet = value;
	    	}
	    	value = getProperty(AUTO_START);
			if(null != value) {
	    		autoStartSet = value;
	    	}
	    	value = getProperty(AUTO_TIME);
			if(null != value) {
	    		autoTimeSet = value;
	    	}
	    	value = getProperty(BG_COL);
			if(null != value) {
	    		bgColSet = value;
	    	}
	    	value = getProperty(LABEL_COL);
			if(null != value) {
	    		lblColSet = value;
	    	}
	    	value = getProperty(TEXT_COL);
			if(null != value) {
	    		txtColSet = value;
	    	}
	    	//value = getProperty(HRV_COL);
			//if(null != value) {
	    	//	hrvColSet = value;
	    	//}
	    	//value = getProperty(AVG_HRV_COL);
			//if(null != value) {
	    	//	avgHrvColSet = value;
	    	//}
	    	//value = getProperty(PULSE_COL);
			//if(null != value) {
	    	//	pulseColSet = value;
	    	//}
	    	//value = getProperty(AVG_PULSE_COL);
			//if(null != value) {
	    	//	avgPulseColSet = value;
	    	//}
	
	    	value = getProperty(INHALE_TIME);
			if(null != value) {
	    		inhaleTimeSet = value;
	    	}
	    	value = getProperty(EXHALE_TIME);
			if(null != value) {
	    		exhaleTimeSet = value;
	    	}
	    	value = getProperty(RELAX_TIME);
			if(null != value) {
	    		relaxTimeSet = value;
	    	}
		}
	}

	function resetResults() {
		// not sure this will work as scope TBD!!!
		// results defined in HRVApp
		results = new [150];

		for(var i = 0; i < 150; i++) {
			results[i] = 0;
		}
	}
	
	function loadResults() {
		// currently references a results array in HRVApp
		for(var i = 0; i < 30; i++) {
			var ii = i * 5;
			var result = getProperty(RESULTS + i);
			if(null != result) {
				results[ii + 0] = result[0];
				results[ii + 1] = result[1];
				results[ii + 2] = result[2];
				results[ii + 3] = result[3];
				results[ii + 4] = result[4];
			}
		}
	}

    function saveTest()
    {
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

		results[index + 0] = utcStart;
		results[index + 1] = hrv;
		results[index + 2] = avgPulse;

		// Calculate averages
		for(var i = 0; i < 30; i++) {

			var ii = i * 5;

			if(epoch <= results[ii]) {

				sumHrv += results[ii + 1];
				sumPulse += results[ii + 2];
				count++;
			}
		}
		results[index + 3] = sumHrv / count;
		results[index + 4] = sumPulse / count;

		// Print values to file in csv format with ISO 8601 date & time
		var date = Calendar.info(startMoment, 0);
    	System.println(format("$1$-$2$-$3$T$4$:$5$:$6$,$7$,$8$,$9$,$10$",[
    		date.year,
    		date.month,
    		date.day,
    		date.hour,
    		date.min.format("%02d"),
    		date.sec.format("%02d"),
    		hrv,
    		avgPulse,
    		sumHrv / count,
    		sumPulse / count]));

		isNotSaved = false;
    	isSaved = true;
    }

	function saveProperties() {
		// Save settings to memory
    	if(timestampSet != getProperty(TIMESTAMP)) {
    		setProperty(TIMESTAMP, timestampSet);
    	}
    	if(appNameSet != getProperty(APP_NAME)) {
    		setProperty(APP_NAME, appNameSet);
    	}
		if(versionSet != getProperty(VERSION)) {
    		setProperty(VERSION, versionSet);
    	}

		if(greenTimeSet != getProperty(GREEN_TIME)) {
    		setProperty(GREEN_TIME, greenTimeSet);
    	}
		if(soundSet != getProperty(SOUND)) {
    		setProperty(SOUND, soundSet);
    	}
		if(vibeSet != getProperty(VIBE)) {
    		setProperty(VIBE, vibeSet);
    	}
		if(testTypeSet != getProperty(TEST_TYPE)) {
    		setProperty(TEST_TYPE, testTypeSet);
    	}
		if(timerTimeSet != getProperty(TIMER_TIME)) {
    		setProperty(TIMER_TIME, timerTimeSet);
    	}
		if(autoStartSet != getProperty(AUTO_START)) {
    		setProperty(AUTO_START, autoStartSet);
    	}
		if(autoTimeSet != getProperty(AUTO_TIME)) {
    		setProperty(AUTO_TIME, autoTimeSet);
    	}
		if(bgColSet != getProperty(BG_COL)) {
    		setProperty(BG_COL, bgColSet);
    	}
		if(lblColSet != getProperty(LABEL_COL)) {
    		setProperty(LABEL_COL, lblColSet);
    	}
		if(txtColSet != getProperty(TEXT_COL)) {
    		setProperty(TEXT_COL, txtColSet);
    	}
		if(hrvColSet != getProperty(HRV_COL)) {
    		setProperty(HRV_COL, hrvColSet);
    	}
		if(avgHrvColSet != getProperty(AVG_HRV_COL)) {
    		 setProperty(AVG_HRV_COL, avgHrvColSet);
    	}
		if(pulseColSet != getProperty(PULSE_COL)) {
    		setProperty(PULSE_COL, pulseColSet);
    	}
		if(avgPulseColSet != getProperty(AVG_PULSE_COL)) {
    		setProperty(AVG_PULSE_COL, avgPulseColSet);
    	}

    	if(inhaleTimeSet != getProperty(INHALE_TIME)) {
    		setProperty(INHALE_TIME, inhaleTimeSet);
    	}
    	if(exhaleTimeSet != getProperty(EXHALE_TIME)) {
    		setProperty(EXHALE_TIME, exhaleTimeSet);
    	}
    	if(relaxTimeSet != getProperty(RELAX_TIME)) {
    		setProperty(RELAX_TIME, relaxTimeSet);
    	}
	}

	function saveResults() {
	    // Save results to memory
    	for(var i = 0; i < 30; i++) {
			var ii = i * 5;
			var result = getProperty(RESULTS + i);
			if(null == result || results[ii] != result[0]) {
				setProperty(RESULTS + i, [
					results[ii + 0],
					results[ii + 1],
					results[ii + 2],
					results[ii + 3],
					results[ii + 4]]);
			}
		}
	}
	
	
	
}

 