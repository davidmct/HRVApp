using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// display a summary of the current test data eg rMSSD
class ResultView extends Ui.View {

	var mResultsLayout;

	function initialize() { View.initialize();}
	
	function onLayout(dc) {
		mResultsLayout = Rez.Layouts.ResultsViewLayout(dc);
		//Sys.println("ResultView: onLayout() called ");
		if ( mResultsLayout != null ) {
			setLayout (mResultsLayout);
		} else {
			Sys.println("layout null");
		}
	}
		
    //! Restore the state of the app and prepare the view to be shown
    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
    	//Sys.println("ResultView: onShow() called ");   	
	
		//return true;
    }
    
    hidden function updateLayoutField(fieldId, fieldValue, fieldColour, fieldJust) {
        var drawable = findDrawableById(fieldId);
        //Sys.println("ResultView: updateLayoutField() called " + drawable );
        if (drawable != null) {
        	//Sys.println("ResultView: updateLayoutField() setting colour/Just ");
            drawable.setColor(fieldColour);
            drawable.setJustification(fieldJust);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
    }
    
    //! Update the view
    function onUpdate(dc) { 
    	Sys.println("ResultView: onUpdate() called");
    	
    	var time = 0;
		var pulse = 0;
		var expected = 0;

		if($._mApp.mTestControl.mState.isTesting) {
			time = $._mApp.timeNow() - $._mApp.mTestControl.utcStart;
		}
		else if($._mApp.mTestControl.mState.isFinished) {
			time = $._mApp.mTestControl.utcStop - $._mApp.mTestControl.utcStart;
		}
		
		// don't need expected
		expected = (((1 + time) / 60.0) * $._mApp.mSampleProc.avgPulse).toNumber();

		var mLabelColour = mapColour( $._mApp.lblColSet);
		var mLabelJust = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueJust = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		//Sys.println("ResultView: update fields of layout: labelCol: "+ mLabelColour + " Value colour " + mValueColour);
		updateLayoutField("timeY", null, mLabelColour, mLabelJust);
		updateLayoutField("pulseY", null, mLabelColour, mLabelJust);		
		updateLayoutField("hrvY", null, mLabelColour, mLabelJust);		
		updateLayoutField("samplesY", null, mLabelColour, mLabelJust);	
		updateLayoutField("expectedY", null, mLabelColour, mLabelJust);	

		updateLayoutField( "timeValue", timerFormat(time).toString(), mValueColour, mValueJust);
		updateLayoutField( "pulseValue", $._mApp.mSampleProc.avgPulse.format("%d"), mValueColour, mValueJust);
		updateLayoutField( "hrvValue", $._mApp.mSampleProc.mLnRMSSD.format("%d"), mValueColour, mValueJust);
		updateLayoutField( "samplesValue", $._mApp.mSampleProc.dataCount.toString(), mValueColour, mValueJust);
		updateLayoutField( "expectedValue", "xx", mValueColour, mValueJust);
		
		//dc.drawText(100, 100, Graphics.FONT_MEDIUM, "WHAT IS HAPPENING", Graphics.TEXT_JUSTIFY_CENTER);
   		View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}