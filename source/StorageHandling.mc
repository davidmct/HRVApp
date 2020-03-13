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

	var x;
	var mApp;
	
    function initialize() {
    	mApp = App.getApp();
		x = mApp.isWaiting;
		Sys.println(" x is set to  "+x);
		Sys.println("app is " + mApp);
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

	// message from Garmin that settings have been changed on mobile
	function onSettingsChanged() {
	
	
	}

}

 