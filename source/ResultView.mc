using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class ResultView extends Ui.View {

	hidden var app;

	function initialize() { app=App.getApp(); View.initialize();}
	
	function onLayout(dc) {
		setLayout(Rez.Layouts.ResultsViewLayout(dc));
	}
		
    //! Restore the state of the app and prepare the view to be shown
    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
    	app.updateSeconds();
    	app.resetGreenTimer();
    			var time = 0;
		var pulse = 0;
		var expected = 0;

		if(app.isTesting) {
			time = app.timeNow() - app.utcStart;
		}
		else if(app.isFinished) {
			time = app.utcStop - app.utcStart;
		}
		expected = (((1 + time) / 60.0) * app.avgPulse).toNumber();

		var mLabelColour = app.lblColSet;
		var mLabelJust = Graphics.TEXT_JUSTIFY_RIGHT || Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueJust = Graphics.TEXT_JUSTIFY_LEFT || Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueColour = app.txtColSet;
		
		updateLayoutField("timeY", null, mLabelColour, mLabelJust);
		updateLayoutField("pulseY", null, mLabelColour, mLabelJust);		
		updateLayoutField("hrvY", null, mLabelColour, mLabelJust);		
		updateLayoutField("samplesY", null, mLabelColour, mLabelJust);	
		updateLayoutField("expectedY", null, mLabelColour, mLabelJust);	

		updateLayoutField( "timeValue", app.timerFormat(time).toString(), mValueColour, mValueJust);
		updateLayoutField( "pulseValue", app.avgPulse.toString(), mValueColour, mValueJust);
		updateLayoutField( "hrvValue", app.hrv.toString(), mValueColour, mValueJust);
		updateLayoutField( "samplesValue", app.dataCount.toString(), mValueColour, mValueJust);
		updateLayoutField( "expectedValue", expected.toString(), mValueColour, mValueJust);
    }
    
    hidden function updateLayoutField(fieldId, fieldValue, fieldColour, fieldJust) {
        var drawable = findDrawableById(fieldId);
        if (drawable != null) {
            drawable.setColor(fieldColour);
            drawable.setJustification(fieldJust);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
    }
    
    //! Update the view
    function onUpdate(dc) { 
   		View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}