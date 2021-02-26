using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Application.Storage as Store;
using Toybox.Application.Properties; // as Property;
using Toybox.WatchUi as Ui;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:notAuthCode)
module AuthCode {
	// Trial mode variables!!
	var mTrialMode;
	var mTrialStarted;
	var mAuthorised;
	var mTrailPeriod;
	var mTrialStartDate; 
	var mAuthID = null;
	var mTrialMessage;

	function init() {}
	function UpdateTrialState() {}

}

(:AuthCode)
module AuthCode {

	// Trial mode variables!!
	var mTrialMode;
	var mTrialStarted;
	var mAuthorised;
	var mTrailPeriod;
	var mTrialStartDate; 
	var mAuthID;
	var mTrialMessage;

	function init() {
	//Modification for 0.4.4 - remove properties which are not settings and use storage
		// load trial variables
		// 1st test for first time by failure to read!
		var test;
		test = Store.getValue("pTrialMode");
		
		if (test == null) {
			// failed to read so need to initialise
			Store.setValue("pTrialMode", false);
			Store.setValue("pTrialStarted", false);
			Store.setValue("pAuthorised", false);
			Store.setValue("pTrailPeriod", 30);
			Store.setValue("pTrialStartDate", 0);
		}

		mTrialMode = Store.getValue("pTrialMode");
		mTrialStarted = Store.getValue("pTrialStarted");
		mAuthorised = Store.getValue("pAuthorised");
		mTrailPeriod = Store.getValue("pTrailPeriod");
		mTrialStartDate = Store.getValue("pTrialStartDate");
		
		Properties.setValue("pDeviceID", mDeviceID);
		// code to authenticate device with given DeviceID
		mAuthID = Properties.getValue("pAuthID");   	
	
	
	
	}

(:storageMethod)   
    function saveTrialWithStorage() {		
		// save trial variables
		Store.setValue("pTrialMode", mTrialMode);
		Store.setValue("pTrialStarted", mTrialStarted);
		Store.setValue("pAuthorised", mAuthorised );
		Store.setValue("pTrialStartDate", mTrialStartDate);
		      
    }
    
(:exTrialParamProperty)   
// pre 0.4.4 code 
    function saveTrialWithStorage() {		
		// save trial variables
		Properties.setValue("pTrialMode", mTrialMode);
		Properties.setValue("pTrialStarted", mTrialStarted);
		Properties.setValue("pAuthorised", mAuthorised );
		Properties.setValue("pTrialStartDate", mTrialStartDate);
		      
    }
 
 (:preCIQ24)   
    function saveTrialNoStorage() {
 
    }    
 
 	function checkAuth(AuthorisationID, DeviceIdentification) {		
 		// Need an algo based on device ID that checks against Device Identification
 		// DeviceIndentication is a hex string
 		var numArray = new [ DeviceIdentification.length()];
 		numArray = DeviceIdentification.toUtf8Array();  // toCharArray 
 		//Sys.println( "numArray = "+numArray);
 		
 		return true; // fake success
 	}
 	 
    function UpdateTrialState() {
 		//Sys.println("Trial properties: "+mTrialMode+","+mTrialStartDate+","+mTrialStarted+","+mAuthorised+","+mTrailPeriod);  
 		Sys.println("UpdateTrialState() called");
 		mTrialMessage = true;
 		Sys.println("updateTrial State #1 mAuthorised = "+mAuthorised); 		
 		if (checkAuth(mAuthID, mDeviceID) == true) {
 			mAuthorised = true;
 			mTrialMessage = false;
 		}
 		Sys.println("updateTrial State #2 after check mAuthorised = "+mAuthorised);
 		
 		if (mAuthorised) {
 			// good to go
 			mTrialMode = false;
 			mTrialStarted = false;
 			mTrialMessage = false;
 		} else if (!mTrialStarted && mTrialMode) {
    		// initialise trial and save properties
    		// SHOULD use tineMow() common function...
    		var mWhen = new Time.Moment(Time.now().value()); 
    		mTrialStartDate = mWhen.value()+System.getClockTime().timeZoneOffset;
    		Sys.println("Start date = "+mTrialStartDate ); 
    		mTrialStarted = true;
    	} else if ( mTrialStarted && mTrialMode ) {
    		// started and in trial mode

    	}
    	
  		// update properties store
    	if (Toybox.Application has :Storage) {
			saveTrialWithStorage();				
		} else {
			saveTrialNoStorage();
		}
    	Sys.println("exit updateTrial State mAuthorised = "+mAuthorised);
    }
    
    function getTrialDaysRemaining() {
    	// days remaining or null if trials not supported or 0 to disable app
    	//return null;
    	
  		var daysToGo;  	
     	if (mAuthorised) {
 			// good to go
 			Sys.println("getTrailDaysRemaining() called, returned : null");
 			return null;
 		} else if (!mTrialStarted && mTrialMode) {
    		// initialise trial and save properties
    		Sys.println("getTrailDaysRemaining() called, returned default : 30"); 
    		return 30;
    	} else if ( mTrialStarted && mTrialMode ) {
    		// started and in trial mode 	
    		var mWhenNow = new Time.Moment(Time.now().value()); 
    		var timeDiff = mWhenNow.value() + System.getClockTime().timeZoneOffset - mTrialStartDate;  
    		// add on a day TEST CODE
    		//timeDiff += 86400;  		  	
    		daysToGo = 30 - timeDiff / 86400;
	
    		Sys.println("getTrailDaysRemaining() called, returned :"+daysToGo.toNumber());
    		return daysToGo.toNumber();
    	} else {
    		return 30;
    	}
    }
 
 	function allowTrialMessage() {
 		// return false if you want no reminders
 		Sys.println("allowTrialMessage() called");
 		return mTrialMessage;
 	}

}