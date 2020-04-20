using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// need to update this to use justification in layout!

class TestView extends Ui.View {

	hidden var mTestViewLayout;
	var mLabelColour;
	var oldLblCol;
	var mValueColour;
	var oldValCol;
	
	var msgTxt;
	var timer = timerFormat(0);	
	
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
    	oldLblCol = 20;
    	oldValCol = 20;
    }
    
	// function onShow() { getModel().setObserver(self.method(:onNotify));}
	// function onHide() {getModel().setObserver(null);}
	// function onNotify(symbol, object, params) {
	// test :symbol_x
	// }
	// can call onNotify with onNotify(:State_x, self, array);  
	  
	function onNotify(symbol, params) {
		// [ msgTxt, timer]
		msgTxt = params[0];
		timer = params[1];	
	}	
    
    function onLayout(dc) {
		mTestViewLayout = Rez.Layouts.TestViewLayout(dc);
		//if (mDebugging == true) {Sys.println("TestView: onLayout() called ");}
		if ( mTestViewLayout != null ) {
			setLayout (mTestViewLayout);
		} else {
			Sys.println("Test View layout null");
		}
	
		mLabelColour = mapColour( $._mApp.lblColSet);
		mValueColour = mapColour( $._mApp.txtColSet);
		oldLblCol = $._mApp.lblColSet;
		oldValCol = $._mApp.txtColSet;

		//if (mDebugging == true) {Sys.println("TestView: onLayout(): starting field update");}
		
		// title		
		mViewTitleID = getLayoutFieldIDandInit("ViewTitle", null, mLabelColour);
		
		// HRV label and value
		mViewResultLblID = getLayoutFieldIDandInit("ViewHRV_Lbl", null, mLabelColour);
		mViewResultTxtID = getLayoutFieldIDandInit("ViewHRV_Val", "0", mValueColour);
				
		// Pulse lable and value
		mViewPulseLblID = getLayoutFieldIDandInit("ViewPulseLbl", null, mLabelColour);
		mViewPulseValID = getLayoutFieldIDandInit("ViewPulseVal",  "0", mValueColour);
				
		// Time placement
		mViewTimerLblID = getLayoutFieldIDandInit("ViewTimerLbl", null, mLabelColour);
		mViewTimerValID = getLayoutFieldIDandInit("ViewTimerVal", timer, mValueColour);	
		
		// Status of strap
		mViewStrapTxtID = getLayoutFieldIDandInit("ViewStrapStatus", null, mapColour(RED));	
					
		mViewMsgTxtID = getLayoutFieldIDandInit("bodyText", null, mValueColour);
		
		$._mApp.mTestControl.setObserver(self.method(:onNotify));			
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    	// have colours changed?
    	if (($._mApp.lblColSet != oldLblCol) || ($._mApp.txtColSet != oldValCol)) {
    		//Sys.println("Updating colours in onShow() TestView()");
    		oldLblCol = $._mApp.lblColSet;
    		oldValCol = $._mApp.txtColSet;    	
	    	// update colours if they have changed
	        mLabelColour = mapColour( $._mApp.lblColSet);
			mValueColour = mapColour( $._mApp.txtColSet);
			mViewTitleID.setColor( mLabelColour);
			mViewResultLblID.setColor( mLabelColour);
			mViewPulseLblID.setColor( mLabelColour);
			mViewTimerLblID.setColor( mLabelColour);					
			mViewMsgTxtID.setColor( mValueColour);
			mViewResultTxtID.setColor( mValueColour);
			mViewPulseValID.setColor( mValueColour);
			mViewTimerValID.setColor( mValueColour);	
		}
				
    	// might need to go in test controller
    	if($._mApp.mTestControl.mTestState == TS_CLOSE) {
    		// stop app?????
    		//CHECK - causes two calls as one in HRV delegate
			//$._mApp.onStop( null );
			popView(SLIDE_RIGHT);
		}
    }
   
   // could be common function as in ResultsView 

   hidden function getLayoutFieldIDandInit(fieldId, fieldValue, fieldColour) {
        var drawable = findDrawableById(fieldId);
        if (drawable != null) {
            drawable.setColor(fieldColour);
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
			Sys.println("TestView:onUpdate() called");
			//Sys.println("Test View live pulse: " + $._mApp.mSensor.mHRData.livePulse.toString());
			//Sys.println("Test state = "+ $._mApp.mTestControl.mTestState);
		}
		    	
    	// All of the test logic above should be else where and call an update function here
    	// function onShow() { getModel().setObserver(self.method(:onNotify));}
    	// function onHide() {getModel().setObserver(null);}
    	// function onNotify(symbol, object, params) {
    	// test :symbol_x
    	// }
    	// can call onNotify with onNotify(:State_x, self, array);
    	
    	//Sys.println("onUpdate: update fields " +$._mApp.mSampleProc.mLnRMSSD+" "+$._mApp.mSampleProc.avgPulse);
    	
	 	updateLayoutField(mViewStrapTxtID, $._mApp.mSensor.mHRData.mHRMStatus, mapColour($._mApp.mSensor.mHRData.mHRMStatusCol));						
		updateLayoutField(mViewMsgTxtID, msgTxt, mValueColour);
		updateLayoutField(mViewResultTxtID, $._mApp.mSampleProc.mLnRMSSD.format("%d"), mValueColour);
		updateLayoutField(mViewPulseValID, $._mApp.mSensor.mHRData.livePulse.format("%d"), mValueColour);		
		updateLayoutField(mViewTimerValID, timer, mValueColour);
   		
   		View.onUpdate(dc);
   		
   		//if(mDebugging) { Sys.println("TestView:onUpdate() exit");}
   		//return true;	
   		// TEST CODE		
		Sys.println("Testview memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	// don't want to send null as state machine still running
    	//$._mApp.mTestControl.setObserver(null);
    }

}