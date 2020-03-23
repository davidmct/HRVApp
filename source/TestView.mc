using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class TestView extends Ui.View {

	hidden var app;
	hidden var mTestViewLayout;
	
    function initialize() {
    	View.initialize();
    	app = App.getApp();
    }
    
    function onLayout(dc) {
		mTestViewLayout = Rez.Layouts.TestViewLayout(dc);
		//Sys.println("TestView: onLayout() called ");
		if ( mTestViewLayout != null ) {
			setLayout (mTestViewLayout);
		} else {
			Sys.println("layout null");
		}
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {

    	if(app.isClosing) {
			app.onStop( null );
			popView(SLIDE_RIGHT);
		}
    }
   
   // could be common function as in ResultsView 
   hidden function updateLayoutField(fieldId, fieldValue, fieldColour, fieldJust) {
        var drawable = findDrawableById(fieldId);
        //Sys.println("TestView: updateLayoutField() called " + drawable );
        if (drawable != null) {
        	//Sys.println("TestView: updateLayoutField() setting colour/Just ");
            drawable.setColor(fieldColour);
            drawable.setJustification(fieldJust);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
    }

    //! Update the view
    function onUpdate(dc) {
		if(mDebugging) {
			//Sys.println("TestView:onUpdate() called");
			//Sys.println("ANT pulse: " + app.mSensor.mHRData.livePulse.toString());
		}
		

    	// HRV
		var hrv = app.mSensor.mHRData.hrv;

		// Timer
		var timerTime = app.utcStop - app.utcStart;
		var testType = app.testTypeSet;

		if(TYPE_TIMER == testType) {
			timerTime = app.timerTimeSet;
		}
		else if(TYPE_MANUAL == testType) {
			timerTime = app.mManualTimeSet;
		}

		// Pulse
		var pulse = app.mSensor.mHRData.livePulse;

		// Message
    	var msgTxt ="";
    	var testTime = app.timeNow() - app.utcStart;

		if(app.isFinished) {
			pulse = app.mSensor.mHRData.avgPulse;
			testTime = app.utcStop - app.utcStart;

			if(MIN_SAMPLES > app.mSensor.mHRData.dataCount) {
				msgTxt = "Not enough data";
			}
			else if(app.isSaved) {
				msgTxt = "Result saved";
			}
			else {
				msgTxt = "Finished";
			}
    	}
    	else if(app.isTesting) {
    		//var cycleTime = (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			var cycle = 1 + testTime % (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			if(cycle <= app.inhaleTimeSet) {
				msgTxt = "Inhale through nose " + cycle;
			}
			else if(cycle <= app.inhaleTimeSet + app.exhaleTimeSet) {
				msgTxt = "Exhale out mouth " + (cycle - app.inhaleTimeSet);
			}
			else {
				msgTxt = "Relax " + (cycle - (app.inhaleTimeSet + app.exhaleTimeSet));
			}

			if(TYPE_MANUAL != testType) {
				timerTime -= testTime;
			}
			else {
				timerTime = testTime;
			}
    	}
    	else if(app.mSensor.mHRData.isStrapRx) {
			if(TYPE_TIMER == testType) {
				msgTxt = "Timer test ready";
			}
			else if(TYPE_MANUAL == testType) {
				msgTxt = "Manual test ready";
			}
    	}
    	else {
    		msgTxt = "Searching for HRM";
    	}

    	// Strap & pulse indicators
    	var strapCol = app.txtColSet;
    	var pulseCol = app.txtColSet;
    	var strapTxt = "STRAP";
    	var pulseTxt = "PULSE";

    	if(!app.mSensor.mHRData.isChOpen) {
			pulse = 0;
			strapTxt = "SAVING";
			pulseTxt = "BATTERY";
		}
		else if(!app.mSensor.mHRData.isStrapRx) {
	    		strapCol = RED;
	    		pulseCol = RED;
    	}
    	else {
    		strapCol = GREEN;
    		if(!app.mSensor.mHRData.isPulseRx) {
	    		pulseCol = RED;
	    	}
	    	else {
	    		pulseCol = GREEN;
	    	}
    	}
    	
    	var mLabelColour = mapColour( app.lblColSet);
		var mJust = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueColour = mapColour( app.txtColSet);
		
		updateLayoutField("ViewTitle", null, mLabelColour, mJust);
		updateLayoutField("ViewResultLbl", null, mLabelColour, mJust);
		updateLayoutField("ViewPulseLbl", null, mLabelColour, mJust);
		updateLayoutField("ViewTimerLbl", null, mLabelColour, mJust);
		updateLayoutField("ViewStrapTxt", strapTxt, mapColour(strapCol), mJust);	
		updateLayoutField("ViewPulseTxt", pulseTxt, mapColour(pulseCol), mJust);	
					
		updateLayoutField( "ViewMsgTxt", msgTxt, mValueColour, mJust);
		updateLayoutField( "ViewResultTxt", app.mSensor.mHRData.hrv.toString(), mValueColour, mJust);
		updateLayoutField( "ViewPulseVal", app.mSensor.mHRData.avgPulse.toString(), mValueColour, mJust);
		updateLayoutField( "ViewTimerVal", app.timerFormat(timerTime), mValueColour, mJust);
   		
   		View.onUpdate(dc);
   		//return true;
		
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

}