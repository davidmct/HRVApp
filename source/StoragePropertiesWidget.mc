using Toybox.System as Sys;
using Toybox.Application as App;
//using Toybox.Application.Storage as Storage;
using Toybox.Application.Properties; // as Property;
using Toybox.WatchUi as Ui;
using Toybox.Lang;


module HRVStor {

	// message from Garmin that settings have been changed on mobile - called from main app
	function onSettingsChangedStore() {
		// should probably stop any test and reload settings
		readProperties();
		// caller will do checks on changes
	}

// date settings from Garmin are in UTC so use Gregorian.utcInfo() when working with these in place of Gregorian.info()

	function fresetPropertiesStorage() {
		// use Storage.get/setValue("", value) for storage or properties not used in settings			
		Properties.setValue("bgColSet", 3);
		Properties.setValue("lblColSet", 10);
		Properties.setValue("txtColSet", 9);		
		Properties.setValue("pLongThresholdIndex", 0.15); // nominal
		Properties.setValue("pShortThresholdIndex", 0.15); // nominal	
		Properties.setValue("pLogScale", 50.0);
	
	}
	
	// This should be factory default settings and should write values back to store
	// ideally these should align with properties defined in XML

(:discard)
	function resetSettings() {
	
		if (Toybox.Application has :Storage) {		
			fresetPropertiesStorage();				
		} 
		// now load up variables
		readProperties();
		mapIndexToColours();
	}

(:discard)
	function readProperties() {	
		if (Toybox.Application has :Storage) {
			_CallReadPropStorage();
		}
	}	

(:discard)	
	function saveProperties() {	
		
		if (Toybox.Application has :Storage) {
			_CallSavePropStorage();
			Sys.println("saveProperties() called");
		}
	}

(:discard)
	function _CallReadPropStorage() {
		//Property.getValue(name as string);
		// On very first use of app don't read in properties!
		$.appNameSet = Ui.loadResource(Rez.Strings.AppName);
		
		//Sys.println("bg, lbk, txt "+$.bgColSet+" "+$.lblColSet+" "+$.txtColSet);

		//if (Toybox.Application has :Storage) {	
		//	Sys.println("We have storage");		
		//	try {	
		//		$.bgColSet = 0;
		//		$.bgColSet =  App.Properties.getValue("bgColSet").toNumber();		 
		//	} catch (e) {
		//		// storage error - most likely not written
		//		Sys.println("ERRO LOADING values");
		//	}
		//	finally {
		//		Sys.println("Finally called");
		//	}	
		//} else {
		//	Sys.println("no storage");
		//}
		
		// ColSet are index into colour map
		$.bgColSet =  Properties.getValue("bgColSet").toNumber();
		$.lblColSet = Properties.getValue("lblColSet").toNumber();
		$.txtColSet = Properties.getValue("txtColSet").toNumber();
		
		mapIndexToColours();
					
		$.vUpperThresholdSet = Properties.getValue("pLongThresholdIndex").toFloat();
		$.vLowerThresholdSet = Properties.getValue("pShortThresholdIndex").toFloat();
		
		$.mLogScale = Properties.getValue("pLogScale").toFloat();
	}

(:discard)
	function _CallSavePropStorage() {
		// ColSet are index into colour map
		Properties.setValue("bgColSet", $.bgColSet);
		Properties.setValue("lblColSet", $.lblColSet);
		Properties.setValue("txtColSet", $.txtColSet);
		Properties.setValue("pLongThresholdIndex", $.vUpperThresholdSet );		
		Properties.setValue("pShortThresholdIndex", $.vLowerThresholdSet);
			
	}
		

}