using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;  


class TestView extends Ui.View {
	
	var msgTxt = "";
	var timer = timerFormat(0);	
	hidden var mBitMap;
	hidden var mBitMapLoc = [32,4];

	hidden var mTitleLoc = [61, 12]; // %
	hidden var mTitleLocS = [0,0];	
	hidden var mTitleLabels = ["HRV"];
	
	// x, y, width, height
	hidden var mMessageLoc = [10, 20, 80, 30]; // %
	hidden var mMesssgeLocS = new [mMessageLoc.size()];	
	
	// coordinates of first and second set of labels as %
	// split to 1D array to save memory
	hidden var mLabelSetX = [ 32, 76, 64, 27];
	hidden var mLabelSetY = [ 53, 66, 53, 66];
	
	// coordinates of  value cordinates as %
	// strapStatus - no label!, Ln, BPM, Timer
	hidden var mLabelValueLocX = [ 28, 75, 82, 27];
	hidden var mLabelValueLocY = [ 53, 78, 53, 78];
	
	hidden var mFitIconLocX = 50;
	hidden var mFitIconLocY = 78;
	hidden var mFitIconLocXS;
	hidden var mFitIconLocYS;	
		
	// label values
	hidden var mLabels = [ "", "Ln(HRV)", "BPM", "TIMER" ];

	// x%, y%, width/height
	hidden var mRectHorizWH = 100;
	hidden var mRectHorizX = 0;
	hidden var mRectHorizY = [ 47, 61];

	
	// scaled variables
	hidden var mLabelSetXS = new [ mLabelSetX.size()];
	hidden var mLabelSetYS = new [ mLabelSetY.size()];
	
	hidden var mLabelValueLocXS = new [ mLabelValueLocX.size()];
	hidden var mLabelValueLocYS = new [ mLabelValueLocY.size()];
	
	hidden var mRectHorizWHS = 0;
	hidden var mRectHorizXS = 0;
	hidden var mRectHorizYS = new [ mRectHorizY.size()];
		
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mStrapFont = Gfx.FONT_TINY;
	hidden var mTimerFont = Gfx.FONT_NUMBER_MILD; // for L(HRV) as well
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;
		
	
    function initialize() { View.initialize(); }
    
	// function onShow() { getModel().setObserver(self.method(:onNotify));}
	// function onHide() {getModel().setObserver(null);}
	// function onNotify(symbol, object, params) {
	// test :symbol_x
	// }
	// can call onNotify with onNotify(:State_x, self, array);  
	  
	function onNotify(symbol, params) {
		// [ msgTxt, timer]
		msgTxt = params[0];
		timer = params[1]; //timerFormat( params[1]);	
		//Sys.println("Timer from params[1] = "+timer);
	}	
    
    function onLayout(dc) {
		
		mScaleY = dc.getHeight();
		mScaleX = dc.getWidth();
		
		// convert % to numbers based on screen size
		mTitleLocS = [ (mTitleLoc[0]*mScaleX)/100, (mTitleLoc[1]*mScaleY)/100];	
		
		mMesssgeLocS[0] = (mMessageLoc[0] *mScaleX)/100;
		mMesssgeLocS[2] = (mMessageLoc[2] *mScaleX)/100;
		mMesssgeLocS[1] = (mMessageLoc[1] *mScaleY)/100;
		mMesssgeLocS[3] = (mMessageLoc[3] *mScaleY)/100;	
		
		for( var i=0; i < mLabelSetXS.size(); i++) {
			mLabelSetXS[i] = (mLabelSetX[i] * mScaleX)/100;	
			mLabelSetYS[i] = (mLabelSetY[i] * mScaleY)/100;
		}
				
		for( var i=0; i < mLabelValueLocXS.size(); i++) {
			mLabelValueLocXS[i] = (mLabelValueLocX[i] * mScaleX)/100;	
			mLabelValueLocYS[i] = (mLabelValueLocY[i] * mScaleY)/100;
		}	
								
		for( var i=0; i < mRectHorizYS.size(); i++) {
			mRectHorizYS[i] = (mRectHorizY[i] * mScaleY)/100;		
		}	
		mRectHorizWHS = (mRectHorizWH * mScaleX)/100;
		mRectHorizXS = (mRectHorizX * mScaleX)/100;
	
		$._mApp.mTestControl.setObserver(self.method(:onNotify));	
		
		var mLocX = (mBitMapLoc[0] * mScaleX)/100;
		var mLocY = (mBitMapLoc[1] * mScaleY)/100;		
		mBitMap = new Ui.Bitmap({
            :rezId=>Rez.Drawables.mHrvIcon,
            :locX=>mLocX,
            :locY=>mLocY           
        });

		mFitIconLocXS = (mFitIconLocX * mScaleX)/100;
		mFitIconLocYS = (mFitIconLocY * mScaleY)/100;	
	
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {  				
    	// might need to go in test controller
    	if($._mApp.mTestControl.mTestState == TS_CLOSE) {
			popView(SLIDE_IMMEDIATE);
		}
    }


       
    //! Update the view
    function onUpdate(dc) {
		if(mDebugging) {
			Sys.println("TestView:onUpdate() called");
			//Sys.println("Test View live pulse: " + $._mApp.mSensor.mHRData.livePulse.toString());
			//Sys.println("Test state = "+ $._mApp.mTestControl.mTestState);
		}
				    
		var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		//Sys.println(" mValueColour, mLabelColour, background : "+mLabelColour+","+mValueColour+","+mapColour($._mApp.bgColSet));

		dc.setColor( Gfx.COLOR_TRANSPARENT, mapColour($._mApp.bgColSet));
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}

		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		mBitMap.draw(dc);
		
		// 0.4.04 - select which text area to use
		//var x = 0;
		if (Ui.WatchUi has :TextArea) {
			Sys.println("UI has TextArea");
			$.f_drawTextArea(dc, msgTxt, mValueColour, mapColour($._mApp.bgColSet), 
				mMesssgeLocS[0], mMesssgeLocS[1], mMesssgeLocS[2], mMesssgeLocS[3]);		

		} else {
			Sys.println("UI has Text not area");
			$.f_drawText(dc, msgTxt, mValueColour, mapColour($._mApp.bgColSet), 
				mMesssgeLocS[0], mMesssgeLocS[1], mMesssgeLocS[2], mMesssgeLocS[3]);		

		}
		//Sys.println("FIX TEST VIEW TEXTAREA FONTS");
		
		// v0.4.01 code ..
		//var myTextArea = new Ui.TextArea({
        //    :text=>msgTxt,
        //    :color=>mValueColour,
        //    :backgroundColor=>mapColour($._mApp.bgColSet),
        //    :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],
        //    :locX=>mMesssgeLocS[0],
        //    :locY=>mMesssgeLocS[1],
        //    :width=>mMesssgeLocS[2],
        //    :height=>mMesssgeLocS[3],
        //    :justification=>Gfx.TEXT_JUSTIFY_CENTER
        //});
        //myTextArea.draw(dc);	
		
		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		// Specical case in [0] of HRM status
		// 0.4.00
		//for (var i=1; i < mLabelSetX.size(); i++) {
		//	dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabels[i], mJust);			
		//}
		
		//0.4.01 - unroll loop as only two values at moment
		dc.drawText( mLabelSetXS[1], mLabelSetYS[1], mLabelFont, mLabels[1], mJust);
		dc.drawText( mLabelSetXS[3], mLabelSetYS[3], mLabelFont, mLabels[3], mJust);
				
		//0.4.01 - draw BPM in strapFont to make larger
		dc.drawText( mLabelSetXS[2], mLabelSetYS[2], mStrapFont, mLabels[2], mJust);
		
		dc.setColor( mapColour($._mApp.mSensor.mHRData.mHRMStatusCol), Gfx.COLOR_TRANSPARENT);
		var str;
		//0.4.00
		//str = ($._mApp.mSensorTypeExt == SENSOR_INTERNAL) ? "(I) " : "(E) ";		
		//0.4.01
		str = ($._mApp.mSensorTypeExt == SENSOR_INTERNAL) ? "I_" : "E_";
		str = str+$._mApp.mSensor.mHRData.mHRMStatus;
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mStrapFont, str, mJust);
		
		// now show values
		
		dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);			
		dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mTimerFont, $._mApp.mSampleProc.mLnRMSSD.format("%d"), mJust);
		// 0.4.00 release for approval
		//dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $._mApp.mSensor.mHRData.livePulse.format("%d"), mJust);
		// 0.4.01
		var mPulse = $._mApp.mSensor.mHRData.livePulse;
		var mPulseStr;
		if ( mPulse == 0 || mPulse == null) {
			mPulseStr = "--";
		} else {
			mPulseStr = mPulse.format("%d");
		}
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, mPulseStr, mJust);
		dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mTimerFont, timer, mJust);
		
		// now draw circle based on FIT status
		var mCircleCol = mapColour($._mApp.bgColSet);
		if ( mCircleCol == Gfx.COLOR_WHITE) {
			// background is white so make black!
			mCircleCol = Gfx.COLOR_BLACK;
		} else {
			mCircleCol = Gfx.COLOR_WHITE;		
		}
		
		// draw opposite of background if FIT enabled and not writing
		// draw red if FIT enabled and writing
		// else don't draw	
		// 0.4.05
		var strDBG = $._mApp.mFitWriteEnabled + ", ";
		if ( $._mApp.mFitControl.mSession == null) { 
			strDBG = strDBG+"null"+" not recording";
		}
		if ($._mApp.mFitControl.mSession != null ) {
			strDBG = strDBG + "Session, "+$._mApp.mFitControl.mSession.isRecording();
		}
		Sys.println("FIT enabled, mSession, recording: "+strDBG);
					
		if ($._mApp.mFitWriteEnabled && $._mApp.mFitControl.mSession != null && $._mApp.mFitControl.mSession.isRecording()) {
			dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mFitIconLocXS, mFitIconLocYS, 10);		
		} else if ($._mApp.mFitWriteEnabled) {
			dc.setColor( mCircleCol, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mFitIconLocXS, mFitIconLocYS, 10);			
		}
		   		
   		//View.onUpdate(dc);
   		
   		//if(mDebugging) { Sys.println("TestView:onUpdate() exit");}
   		//return true;	
   		// TEST CODE		
		//Sys.println("Testview memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    	// don't want to send null as state machine still running
    	//$._mApp.mTestControl.setObserver(null);
    	// free up all the arrays - NO as maybe switches without a new ...
    }

}