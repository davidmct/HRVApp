using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;  

// 0.6.3 version using JSON precalculated coordinates
(:UseJson)
class TestView extends Ui.View {
	
	hidden var msgTxt = "";
	hidden var timer = timerFormat(0);	
	hidden var mBitMap = null;
	hidden var mTitleLabels = ["HRV"];
	
	// label values
	//hidden var mLabels = [ "", "Ln(HRV)", "BPM", "TIMER", "" ];	
		
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mStrapFont = Gfx.FONT_TINY;
	hidden var mTimerFont = Gfx.FONT_NUMBER_MILD; // for L(HRV) as well
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScreen;
	
	// BUILD Print list for coords
	//hidden var mBitMapLocS = [2]; Index 0, 1
	//hidden var mTitleLocS = [2];	2,3
	//hidden var mMesssgeLocS = new [4];	4,5,6,7	
	//hidden var mFitIconLocXS; 8
	//hidden var mFitIconLocYS; 9
	//hidden var mLabelSetXS = new [ 5]; 10, 11, 12 ,13 -> 10, 11,12,13,14
	//hidden var mLabelSetYS = new [ 5]; 14,15,16,17 -> 15, 16, 17, 18, 19	
	//hidden var mLabelValueLocXS = new [ 5]; 18..22 -> 20,21,22,23,24
	//hidden var mLabelValueLocYS = new [ 5]; 23..27 -> 25,26,27,28,29	
	//hidden var mRectHorizWHS = 0; 28 -> 30
	//hidden var mRectHorizXS = 0; 29 -> 31
	//hidden var mRectHorizYS = new [ 2]; 30, 31 -> 32,33
			
	
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
		// load JSON
		mScreen = Ui.loadResource(Rez.JsonData.jsonTestD);
		$.mTestControl.setObserver(self.method(:onNotify));	
	
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {  				
    	// might need to go in test controller
    	if($.mTestControl.mTestState == TS_CLOSE) {
			popView(SLIDE_IMMEDIATE);
		}
    }

       
    //! Update the view
    function onUpdate(dc) {
		if(mDebugging) {
			//Sys.println("TestView:onUpdate() called");
			//Sys.println("Test View live pulse: " + $.mSensor.mHRData.livePulse.toString());
			//Sys.println("Test state = "+ $.mTestControl.mTestState);
		}
		
		//Sys.println(" mValueColour, mLabelColour, background : "+mLabelColour+","+mValueColour+","+mapColour($.bgColSet));

		if (mBitMap == null) {	
			mBitMap = new Ui.Bitmap({
	            :rezId=>Rez.Drawables.mHrvIcon,
	            :locX=>mScreen[0],
	            :locY=>mScreen[1]           
	        });
	    }
	    
	    if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
        
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < 2; i++) {
			dc.drawRectangle(mScreen[31], mScreen[32+i], mScreen[30], 2);
		}

		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mScreen[2], mScreen[3], mTitleFont, mTitleLabels[0], mJust);
		mBitMap.draw(dc);
		
		// 0.4.04 - select which text area to use
		//var x = 0;
		if (Ui.WatchUi has :TextArea) {
			//if (mDebugging) { Sys.println("UI has TextArea");}
			$.f_drawTextArea(dc, msgTxt, $.mValueColour, $.mBgColour, 
				mScreen[4], mScreen[5], mScreen[6], mScreen[7]);		

		} else {
			//if (mDebugging) {Sys.println("UI has Text not area");}
			$.f_drawText(dc, msgTxt, $.mValueColour, $.mBgColour, 
				mScreen[4], mScreen[5], mScreen[6], mScreen[7]);		

		}
		
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);

		var _lbl = "Ln(HRV)";
		if ( $.mRM ) {
			_lbl = "HRV";
		}
		dc.drawText( mScreen[11], mScreen[16], mLabelFont, _lbl, mJust);
		//0.4.01 - draw BPM in strapFont to make larger
		dc.drawText( mScreen[12], mScreen[17], mStrapFont, "BPM", mJust);
		dc.drawText( mScreen[13], mScreen[18], mLabelFont, "TIMER", mJust);
		
		dc.setColor( mapColour($.mSensor.mHRData.mHRMStatusCol), Gfx.COLOR_TRANSPARENT);
		
		//0.6.0 ring showing colour of sensor status
		//drawArc(x, y, r, attr, degreeStart, degreeEnd)
		dc.setPenWidth(2);
		//Sys.println("Draw arc: "+$.mSensor.mHRData.mHRMStatusCol);
		dc.drawArc(dc.getWidth()/2, dc.getHeight()/2, dc.getWidth()/2-2, Gfx.ARC_COUNTER_CLOCKWISE, 0, 360);
		dc.setPenWidth(1);
		
		var str;
		//0.4.00
		//str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "(I) " : "(E) ";		
		//0.4.01
		//str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "I_" : "E_";
		//str = str+$.mSensor.mHRData.mHRMStatus;
		//0.4.4
		str = $.mSensor.mHRData.mHRMStatus;
		dc.drawText( mScreen[20], mScreen[25], mStrapFont, str, mJust);
		
		// 0.6.5 As we've deleted E mode then remove this! Change to (FIT) in Circle code
		//0.4.4 - Separate field for I/E
		//str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "(I)" : "(E)";
		//dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);	
		//dc.drawText( mScreen[14], mScreen[19], mLabelFont, str, mJust);		
		
		// now show values		
		dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);	
		
		//0.6.5
		var _vHrv = $.mSampleProc.mLnRMSSD.format("%.1f");
		if ( $.mRM ) {
			_vHrv = $.mSampleProc.mRMSSD.format("%.1f");	
			// dc.drawText( mScreen[21], mScreen[26], mTimerFont, $.mSampleProc.mLnRMSSD.format("%d"), mJust);
		}
		dc.drawText( mScreen[21], mScreen[26], mValueFont, _vHrv, mJust);
		
		// 0.4.00 release for approval
		//dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $.mSensor.mHRData.livePulse.format("%d"), mJust);
		// 0.4.01
		var mPulse = $.mSensor.mHRData.livePulse;
		var mPulseStr;
		if ( mPulse == 0 || mPulse == null) {
			mPulseStr = "--";
		} else {
			mPulseStr = mPulse.format("%d");
		}
		dc.drawText( mScreen[22], mScreen[27], mValueFont, mPulseStr, mJust);
		dc.drawText( mScreen[23], mScreen[28], mTimerFont, timer, mJust);
		
		// now draw circle based on FIT status
		var mCircleCol = $.mBgColour;
		if ( mCircleCol == Gfx.COLOR_WHITE) {
			// background is white so make black!
			mCircleCol = Gfx.COLOR_BLACK;
		} else {
			mCircleCol = Gfx.COLOR_WHITE;		
		}
		
		// draw opposite of background if FIT enabled and not writing
		// draw red if FIT enabled and writing
		// else don't draw	
		// 0.4.1
		//if (mDebugging) {
		//	var strDBG = $.mFitWriteEnabled + ", ";
		//	if ( $.mFitControl.mSession == null) { 
		//		strDBG = strDBG+"null"+" not recording";
		//	}
		//	if ($.mFitControl.mSession != null ) {
		//		strDBG = strDBG + "Session, "+$.mFitControl.mSession.isRecording();
		//	}
		//	Sys.println("FIT enabled, mSession, recording: "+strDBG);
		//}
					
		if ($.mFitWriteEnabled && $.mFitControl.mSession != null && $.mFitControl.mSession.isRecording()) {
			dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mScreen[8], mScreen[9], 10);	
			//0.6.5 provide FIT label
			dc.drawText( mScreen[14], mScreen[19], mLabelFont, "FIT", mJust);	
		} else if ($.mFitWriteEnabled) {
			dc.setColor( mCircleCol, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mScreen[8], mScreen[9], 10);	
			dc.drawText( mScreen[14], mScreen[19], mLabelFont, "FIT", mJust);			
		}
		   		
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
    	//$.mTestControl.setObserver(null);
    	// free up all the arrays - NO as maybe switches without a new ...
    	//mLabelFont = null;
    	mBitMap = null;
    }

}


(:notUseJson)  // OLD VERSION using calculation of scaling
class TestView extends Ui.View {
	
	var msgTxt = "";
	var timer = timerFormat(0);	
	hidden var mBitMap = null;
	hidden var mBitMapLoc = [32, 6]; //4];

	hidden var mTitleLoc = [61, 12]; // %
	hidden var mTitleLocS = [0,0];	
	hidden var mTitleLabels = ["HRV"];
	
	// x, y, width, height
	hidden var mMessageLoc = [10, 20, 80, 27]; // %. 0.4.2 changed from 30->27
	hidden var mMesssgeLocS = new [mMessageLoc.size()];	
	
	// coordinates of first and second set of labels as %
	// split to 1D array to save memory
	//0.4.4 
	// Int/Ext is a dynamic label which will be set in code. Aligned above FIT write. 5th element
	hidden var mLabelSetX = [ 32, 76, 64, 27, 50];
	hidden var mLabelSetY = [ 53, 66, 53, 66, 66];
	
	// coordinates of  value cordinates as %
	// strapStatus - no label!, Ln, BPM, Timer, Int/Ext	 
	hidden var mLabelValueLocX = [ 28, 75, 82, 29, 50]; // timer was 27. now 29 0.6.0
	hidden var mLabelValueLocY = [ 53, 78, 53, 78, 66]; 
	
	// label values
	hidden var mLabels = [ "", "Ln(HRV)", "BPM", "TIMER", "" ];	
	
	hidden var mFitIconLocX = 50;
	hidden var mFitIconLocY = 78;
	hidden var mFitIconLocXS;
	hidden var mFitIconLocYS;	

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
	
	hidden var mScreen;
	
	// BUILD Print list for coords
	//hidden var mBitMapLocS = [2]; Index 0, 1
	//hidden var mTitleLocS = [2];	2,3
	//hidden var mMesssgeLocS = new [4];	4,5,6,7	
	//hidden var mFitIconLocXS; 8
	//hidden var mFitIconLocYS; 9
	//hidden var mLabelSetXS = new [ 4]; 10, 11, 12 ,13
	//hidden var mLabelSetYS = new [ 4]; 14,15,16,17	
	//hidden var mLabelValueLocXS = new [ 5]; 18..22
	//hidden var mLabelValueLocYS = new [ 5]; 23..27	
	//hidden var mRectHorizWHS = 0; 28
	//hidden var mRectHorizXS = 0; 29
	//hidden var mRectHorizYS = new [ 2]; 30, 31
			
	
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
	
		$.mTestControl.setObserver(self.method(:onNotify));	
		
		//var mLocX = (mBitMapLoc[0] * mScaleX)/100;
		//var mLocY = (mBitMapLoc[1] * mScaleY)/100;		
		//mBitMap = new Ui.Bitmap({
        //    :rezId=>Rez.Drawables.mHrvIcon,
        //    :locX=>mLocX,
        //    :locY=>mLocY           
        //});

		mFitIconLocXS = (mFitIconLocX * mScaleX)/100;
		mFitIconLocYS = (mFitIconLocY * mScaleY)/100;	
		
		// SETUP OUTPUT
		var a = (mBitMapLoc[0] * mScaleX)/100;
		var b = (mBitMapLoc[1] * mScaleY)/100;	
		
		Sys.println("Test view JSON for "+mScaleX+":\n<jsonData id="+"jsonTestD"+">[ "+
			a+", "+b+", "+
			mTitleLocS[0]+", "+mTitleLocS[1]+", "+
			mMesssgeLocS+", "+
			mFitIconLocXS+", "+mFitIconLocYS+", "+
			mLabelSetXS+", "+mLabelSetYS+", "+
			mLabelValueLocXS+", "+mLabelValueLocYS+", "+
			mRectHorizWHS+", "+
			mRectHorizXS+", "+
			mRectHorizYS+		
			"]</jsonData>");
	
	}
        
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {  				
    	// might need to go in test controller
    	if($.mTestControl.mTestState == TS_CLOSE) {
			popView(SLIDE_IMMEDIATE);
		}
    }

       
    //! Update the view
    function onUpdate(dc) {
		if(mDebugging) {
			Sys.println("TestView:onUpdate() called");
			//Sys.println("Test View live pulse: " + $.mSensor.mHRData.livePulse.toString());
			//Sys.println("Test state = "+ $.mTestControl.mTestState);
		}
		
		//Sys.println(" mValueColour, mLabelColour, background : "+mLabelColour+","+mValueColour+","+mapColour($.bgColSet));

		var mLocX = (mBitMapLoc[0] * mScaleX)/100;
		var mLocY = (mBitMapLoc[1] * mScaleY)/100;	
		if (mBitMap == null) {	
			mBitMap = new Ui.Bitmap({
	            :rezId=>Rez.Drawables.mHrvIcon,
	            :locX=>mLocX,
	            :locY=>mLocY           
	        });
	    }
        
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}

		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		mBitMap.draw(dc);
		
		// 0.4.04 - select which text area to use
		//var x = 0;
		if (Ui.WatchUi has :TextArea) {
			if (mDebugging) { Sys.println("UI has TextArea");}
			$.f_drawTextArea(dc, msgTxt, $.mValueColour, $.mBgColour, 
				mMesssgeLocS[0], mMesssgeLocS[1], mMesssgeLocS[2], mMesssgeLocS[3]);		

		} else {
			if (mDebugging) {Sys.println("UI has Text not area");}
			$.f_drawText(dc, msgTxt, $.mValueColour, $.mBgColour, 
				mMesssgeLocS[0], mMesssgeLocS[1], mMesssgeLocS[2], mMesssgeLocS[3]);		

		}
		//Sys.println("FIX TEST VIEW TEXTAREA FONTS");
		
		// v0.4.01 code ..
		//var myTextArea = new Ui.TextArea({
        //    :text=>msgTxt,
        //    :color=>mValueColour,
        //    :backgroundColor=>mapColour($.bgColSet),
        //    :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],
        //    :locX=>mMesssgeLocS[0],
        //    :locY=>mMesssgeLocS[1],
        //    :width=>mMesssgeLocS[2],
        //    :height=>mMesssgeLocS[3],
        //    :justification=>Gfx.TEXT_JUSTIFY_CENTER
        //});
        //myTextArea.draw(dc);	
		
		dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
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
		
		dc.setColor( mapColour($.mSensor.mHRData.mHRMStatusCol), Gfx.COLOR_TRANSPARENT);
		
		//0.6.0 ring showing colour of sensor status
		//drawArc(x, y, r, attr, degreeStart, degreeEnd)
		dc.setPenWidth(2);
		//Sys.println("Draw arc: "+$.mSensor.mHRData.mHRMStatusCol);
		dc.drawArc(mScaleX/2, mScaleY/2, dc.getWidth()/2-2, Gfx.ARC_COUNTER_CLOCKWISE, 0, 360);
		dc.setPenWidth(1);
		
		var str;
		//0.4.00
		//str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "(I) " : "(E) ";		
		//0.4.01
		//str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "I_" : "E_";
		//str = str+$.mSensor.mHRData.mHRMStatus;
		//0.4.4
		str = $.mSensor.mHRData.mHRMStatus;
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mStrapFont, str, mJust);
		
		//0.4.4 - Separate field for I/E
		str = ($.mSensorTypeExt == SENSOR_INTERNAL) ? "(I)" : "(E)";
		dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);	
		dc.drawText( mLabelSetXS[4], mLabelSetYS[4], mLabelFont, str, mJust);		
		
		// now show values		
		dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);			
		dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mTimerFont, $.mSampleProc.mLnRMSSD.format("%d"), mJust);
		// 0.4.00 release for approval
		//dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $.mSensor.mHRData.livePulse.format("%d"), mJust);
		// 0.4.01
		var mPulse = $.mSensor.mHRData.livePulse;
		var mPulseStr;
		if ( mPulse == 0 || mPulse == null) {
			mPulseStr = "--";
		} else {
			mPulseStr = mPulse.format("%d");
		}
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, mPulseStr, mJust);
		dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mTimerFont, timer, mJust);
		
		// now draw circle based on FIT status
		var mCircleCol = $.mBgColour;
		if ( mCircleCol == Gfx.COLOR_WHITE) {
			// background is white so make black!
			mCircleCol = Gfx.COLOR_BLACK;
		} else {
			mCircleCol = Gfx.COLOR_WHITE;		
		}
		
		// draw opposite of background if FIT enabled and not writing
		// draw red if FIT enabled and writing
		// else don't draw	
		// 0.4.1
		if (mDebugging) {
			var strDBG = $.mFitWriteEnabled + ", ";
			if ( $.mFitControl.mSession == null) { 
				strDBG = strDBG+"null"+" not recording";
			}
			if ($.mFitControl.mSession != null ) {
				strDBG = strDBG + "Session, "+$.mFitControl.mSession.isRecording();
			}
			Sys.println("FIT enabled, mSession, recording: "+strDBG);
		}
					
		if ($.mFitWriteEnabled && $.mFitControl.mSession != null && $.mFitControl.mSession.isRecording()) {
			dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mFitIconLocXS, mFitIconLocYS, 10);		
		} else if ($.mFitWriteEnabled) {
			dc.setColor( mCircleCol, Gfx.COLOR_TRANSPARENT);	
			dc.fillCircle( mFitIconLocXS, mFitIconLocYS, 10);			
		}
		   		
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
    	//$.mTestControl.setObserver(null);
    	// free up all the arrays - NO as maybe switches without a new ...
    	mBitMap = null;
    }

}