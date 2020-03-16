using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class ResultView extends Ui.View {

	hidden var app;

	function initialize() { app=App.getApp(); View.initialize();}
	
	function onLayout(dc) {
		View.setLayout(Rez.Layouts.ResultsViewLayout(dc));
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    	app.updateSeconds();
    	app.resetGreenTimer();
    }

    //! Update the view
    function onUpdate(dc) {
		var time = 0;
		var pulse = 0;
		var expected = 0;
		
		View.onUpdate(dc);

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
		
		var labelView = View.findDrawableById("timeY");
		labelView.color = mLabelColour;
		labelView.justification = mLabelJust;
		labelView = View.findDrawableById("pulseY");
		labelView.color = mLabelColour;
		labelView.justification = mLabelJust;
		labelView = View.findDrawableById("hrvY");
		labelView.color = mLabelColour;
		labelView.justification = mLabelJust;
		labelView = View.findDrawableById("samplesY");
		labelView.color = mLabelColour;
		labelView.justification = mLabelJust;
		labelView = View.findDrawableById("expectedY");
		labelView.color = mLabelColour;
		labelView.justification = mLabelJust;
		
		// update variables in view
		var valueView;
		valueView = View.findDrawableById("timeValue");
        valueView.text = app.timerFormat(time).toString();
        valueView.color = mValueColour;
        valueView.justification = mValueJust;
        valueView = View.findDrawableById("pulseValue");    
		valueView.text = app.avgPulse.toString();
        valueView.color = mValueColour;
        valueView.justification = mValueJust;
        valueView = View.findDrawableById("hrvValue");    
		valueView.text = app.hrv.toString();   
        valueView.color = mValueColour;
        valueView.justification = mValueJust;	     
        valueView = View.findDrawableById("samplesValue");    
		valueView.text = app.dataCount.toString();  
        valueView.justification = mValueJust;
        valueView.color = mValueColour;      
        valueView = View.findDrawableById("expectedValue");    
		valueView.text = expected.toString();   
        valueView.justification = mValueJust;
        valueView.color = mValueColour;     
    }

    function onHide() {
    }
}