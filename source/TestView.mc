using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class TestView extends Ui.View {

	hidden var app;
	hidden var mTestViewLayout;
	var mLabelColour;
	var oldLblCol;
	var mJust = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
	var mValueColour;
	var oldValCol;
	
	var strapTxt;
	var strapCol;
	var pulseTxt;
	var pulseCol;
	var msgTxt;
	var hrv = 0;
	var avgPulse = 0;
	var timer = "0:00";	
	
	// layout ID cache
	var mViewTitleID;
	var mViewResultLblID;
	var mViewPulseLblID;
	var mViewTimerLblID;
	
	var mViewStrapTxtID;	
	var mViewPulseTxtID;	
				
	var mViewMsgTxtID;
	var mViewResultTxtID;
	var mViewPulseValID;
	var mViewTimerValID;		
	
    function initialize() {
    	View.initialize();
    	app = App.getApp();
    	oldLblCol = 20;
    	oldValCol = 20;
    }
    
	// function onShow() { getModel().setObserver(self.method(:onNotify));}
	// function onHide() {getModel().setObserver(null);}
	// function onNotify(symbol, object, params) {
	// test :symbol_x
	// }
	// can call onNotify with onNotify(:State_x, self, array);  
	  
	function onNotify(symbol, object, params) {
		// [strapTxt, strapCol, pulseTxt, pulseCol, msgTxt, hrv, avgPulse, timer]
		strapTxt = params[0];
		pulseTxt = params[1];
		strapCol = params[2];
		pulseCol = params[3];
		msgTxt = params[4];
		hrv = params[5];
		avgPulse = params[6];
		timer = params[7];	
	}	
    
    function onLayout(dc) {
		mTestViewLayout = Rez.Layouts.TestViewLayout(dc);
		//Sys.println("TestView: onLayout() called ");
		if ( mTestViewLayout != null ) {
			setLayout (mTestViewLayout);
		} else {
			Sys.println("layout null");
		}
	
		mLabelColour = mapColour( app.lblColSet);
		mValueColour = mapColour( app.txtColSet);
		oldLblCol = app.lblColSet;
		oldValCol = app.txtColSet;
		
		strapCol = app.txtColSet;
    	pulseCol = app.txtColSet;
    	strapTxt = "STRAP";
    	pulseTxt = "PULSE";

		Sys.println("onLayout: starting field update");		
		mViewTitleID = getLayoutFieldIDandInit("ViewTitle", null, mLabelColour, mJust);
		mViewResultLblID = getLayoutFieldIDandInit("ViewResultLbl", null, mLabelColour, mJust);
		mViewPulseLblID = getLayoutFieldIDandInit("ViewPulseLbl", null, mLabelColour, mJust);
		mViewTimerLblID = getLayoutFieldIDandInit("ViewTimerLbl", null, mLabelColour, mJust);
		
		mViewStrapTxtID = getLayoutFieldIDandInit("ViewStrapTxt", strapTxt, mLabelColour, mJust);	
		mViewPulseTxtID = getLayoutFieldIDandInit("ViewPulseTxt", pulseTxt, mLabelColour, mJust);	
					
		mViewMsgTxtID = getLayoutFieldIDandInit("ViewMsgTxt", msgTxt, mValueColour, mJust);
		mViewResultTxtID = getLayoutFieldIDandInit("ViewResultTxt", hrv.toString(), mValueColour, mJust);
		mViewPulseValID = getLayoutFieldIDandInit("ViewPulseVal", avgPulse.toString(), mValueColour, mJust);
		mViewTimerValID = getLayoutFieldIDandInit("ViewTimerVal", timer, mValueColour, mJust);			
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    	// have colours changed?
    	if ((app.lblColSet != oldLblCol) || (app.txtColSet != oldValCol)) {
    		Sys.println("Updating colours in onShow() TestView()");
    		oldLblCol = app.lblColSet;
    		oldValCol = app.txtColSet;    	
	    	// update colours if they have changed
	        mLabelColour = mapColour( app.lblColSet);
			mValueColour = mapColour( app.txtColSet);
			mViewTitleID.setColor( mLabelColour);
			mViewResultLblID.setColor( mLabelColour);
			mViewPulseLblID.setColor( mLabelColour);
			mViewTimerLblID.setColor( mLabelColour);					
			mViewMsgTxtID.setColor( mValueColour);
			mViewResultTxtID.setColor( mValueColour);
			mViewPulseValID.setColor( mValueColour);
			mViewTimerValID.setColor( mValueColour);	
		}
		app.mTestControl.setObserver(self.method(:onNotify));
				
    	// might need to go in test controller
    	if(app.mTestControl.mState.isClosing) {
			app.onStop( null );
			popView(SLIDE_RIGHT);
		}
    }
   
   // could be common function as in ResultsView 

   hidden function getLayoutFieldIDandInit(fieldId, fieldValue, fieldColour, fieldJust) {
        var drawable = findDrawableById(fieldId);
        if (drawable != null) {
            drawable.setColor(fieldColour);
            drawable.setJustification(fieldJust);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
        return drawable;
   }
   hidden function updateLayoutField(drawable, fieldValue, fieldColour) {
        if (drawable != null) {
            drawable.setColor(fieldColour);
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
		    	
    	// optimisation....
    	// We should cache drawable ID in on layout
    	// The lablels are fixed and can be done in layout
    	// Would need to change colours if these variables got changed
    	// dynamic fields updated using cached ID. Ideally only on change but these should be frequent as HR
    	// could use a call back to update based on model changes (Model-View-Controller pattern)
    	// All of the test logic above should be else where and call an update function here
    	// function onShow() { getModel().setObserver(self.method(:onNotify));}
    	// function onHide() {getModel().setObserver(null);}
    	// function onNotify(symbol, object, params) {
    	// test :symbol_x
    	// }
    	// can call onNotify with onNotify(:State_x, self, array);
    	//Sys.println("onUpdate: update fields " +strapCol+" "+pulseCol);
    	
		updateLayoutField(mViewStrapTxtID, strapTxt, mapColour(strapCol));	
		updateLayoutField(mViewPulseTxtID, pulseTxt, mapColour(pulseCol));					
		updateLayoutField(mViewMsgTxtID, msgTxt, mValueColour);
		updateLayoutField(mViewResultTxtID, hrv.toString(), mValueColour);
		updateLayoutField(mViewPulseValID, avgPulse.toString(), mValueColour);
		updateLayoutField(mViewTimerValID, timer, mValueColour);
//		updateLayoutField( "ViewResultTxt", app.mSensor.mHRData.hrv.toString(), mValueColour, mJust);
//		updateLayoutField( "ViewPulseVal", app.mSensor.mHRData.avgPulse.toString(), mValueColour, mJust);
//		updateLayoutField( "ViewTimerVal", app.timerFormat(timerTime), mValueColour, mJust);
   		
   		View.onUpdate(dc);
   		//return true;
		
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	app.mTestControl.setObserver(null);
    }

}