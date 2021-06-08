using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

(:UseJson)
class StatsView extends Ui.View {

	hidden var viewToShow;
	
	// title location %
	//hidden var mTitleLoc = [50,10];
	hidden var mTitleLabels = ["Stats #1", "Stats #2", "Stats #3"];
	
	// coordinates of first and second set of labels as %
	// split to 1D array to save memory
	//hidden var mLabelSetX = [ 35, 65, 35, 65, 35, 65 ];
	//hidden var mLabelSetY = [ 24, 24, 44, 44, 66, 66 ];
	
	// coordinates of  value cordinates as %
	//hidden var mLabelValueLocX = [ 35, 65, 35, 65, 35, 65 ];
	//hidden var mLabelValueLocY = [ 32, 32, 53, 53, 75, 75 ];
		
	// label values
	//hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "SDSD", "SDNN", "Ectopic" ];
	//hidden var mLabel2Labels = [ "NN50","pNN50", "NN20", "pNN20", "Long", "Short" ];
	//hidden var mLabel3Labels = [ "II","#II", "L_%", "L-ms", "S_%", "S-ms" ];

	//1.0.0
	hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "Ectopic", "II", "#II" ];
	hidden var mLabel2Labels = [ "SDSD", "SDNN", "NN50", "pNN50", "NN20", "pNN20" ];
	hidden var mLabel3Labels = [ "Long", "Short", "L_%", "S_%", "L-ms", "S-ms" ];	
	
	// font missing %, _, (, ), #

	// x%, y%, width/height
	//hidden var mRectHorizWH = 64;
	//hidden var mRectHorizX = 19;
	//hidden var mRectHorizY = [ 19, 39, 61, 82 ];

	//hidden var mRectVertWH = 64;
	//hidden var mRectVertY = 19;	
	//hidden var mRectVertX = [ 19, 50, 82 ];
	
	// scaled variables
	//hidden var mTitleLocS = [0,0];	
	//hidden var mLabelSetXS = new [ mLabelSetX.size() ];
	//hidden var mLabelSetYS = new [ mLabelSetY.size() ];
	
	//hidden var mLabelValueLocXS = new [ mLabelValueLocX.size() ];
	//hidden var mLabelValueLocYS = new [ mLabelValueLocY.size() ];
	
	//hidden var mRectHorizWHS = 0;
	//hidden var mRectHorizXS = 0;
	//hidden var mRectHorizYS = new [ mRectHorizY.size() ];

	//hidden var mRectVertWHS = 0;
	//hidden var mRectVertYS = 0;	
	//hidden var mRectVertXS = new [ mRectVertX.size() ];
	
	hidden var mLabelFont = null; // 0.6.4 Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_TINY;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	//hidden var mScaleY;
	//hidden var mScaleX;
	//hidden var gg;
	
	// layout of screen
	hidden var mScreen;

	function initialize(viewNum) { 
		viewToShow = viewNum;
		//gg = $._m$.	
		View.initialize();
	}
	
	function onLayout(dc) {
		// load JSON
		mScreen = Ui.loadResource(Rez.JsonData.jsonStatsDisp);
	}
		
    //! Restore the state of the app and prepare the view to be shown
    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
    }
      
    //! Update the view
    function onUpdate(dc) { 
    	//Sys.println("StatsView: onUpdate() called");
    	
    	if ($.mDeviceType == RES_240x240) {
			//Sys.println("device is 240x240");
			if (mLabelFont == null) {	
				mLabelFont = Ui.loadResource(Rez.Fonts.smallFont);
				//Sys.println("smallFont loaded");
			}
		} else {
			mLabelFont = Gfx.FONT_XTINY;
		}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < 4; i++) {
			dc.drawRectangle(mScreen[31], mScreen[26+i], mScreen[30], 2);
		}
		for (var i=0; i < 3; i++) {
			dc.drawRectangle(mScreen[32+i], mScreen[36], 2, mScreen[35]);
		}
		
		if (viewToShow == 1 ) {
			// draw 1st set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mScreen[0], mScreen[1], mTitleFont, mTitleLabels[0], mJust);
			for (var i=0; i < 6; i++) {		
				dc.drawText( mScreen[2+i*2], mScreen[3+i*2], mLabelFont, mLabel1Labels[i], mJust);		
			}
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);	

			//0.4.3 set to 0.1f from %d for rMSSD - does it fit?		
			dc.drawText( mScreen[14], mScreen[15], mValueFont, $.mSampleProc.mRMSSD.format("%.1f"), mJust);
			dc.drawText( mScreen[16], mScreen[17], mValueFont, $.mSampleProc.mLnRMSSD.format("%d"), mJust);
			dc.drawText( mScreen[18], mScreen[19], mValueFont, $.mSampleProc.avgPulse.format("%d"), mJust);
			dc.drawText( mScreen[20], mScreen[21], mValueFont, $.mSampleProc.vEBeatCnt.format("%d"), mJust);
			
			var mTmp = $.mSampleProc.getCurrentEntry(); 						
			dc.drawText( mScreen[22], mScreen[23], mValueFont, mTmp[0].format("%d"), mJust);
			dc.drawText( mScreen[24], mScreen[25], mValueFont, $.mSampleProc.getNumberOfSamples().format("%d"), mJust);
											
		} else if (viewToShow == 2) {
			// draw second set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mScreen[0], mScreen[1], mTitleFont, mTitleLabels[1], mJust);
			for (var i=0; i < 6; i++) {		
				dc.drawText( mScreen[2+i*2], mScreen[3+i*2], mLabelFont, mLabel2Labels[i], mJust);		
			}
			
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);

			// next two are floats
			var trunc = ($.mSampleProc.mSDSD*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			var str = "";
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}
			dc.drawText( mScreen[14], mScreen[15], mValueFont, str, mJust);			
			
			trunc = ($.mSampleProc.mSDNN*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}	
			dc.drawText( mScreen[16], mScreen[17], mValueFont, str, mJust);	

			dc.drawText( mScreen[18], mScreen[19], mValueFont, $.mSampleProc.mNN50.format("%d"), mJust);
			dc.drawText( mScreen[20], mScreen[21], mValueFont, $.mSampleProc.mpNN50.format("%.0f"), mJust);
			dc.drawText( mScreen[22], mScreen[23], mValueFont, $.mSampleProc.mNN20.format("%d"), mJust);
			dc.drawText( mScreen[24], mScreen[25], mValueFont, $.mSampleProc.mpNN20.format("%.0f"), mJust);	
		
		} else if (viewToShow == 3) {
			// draw third set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mScreen[0], mScreen[1], mTitleFont, mTitleLabels[2], mJust);
			for (var i=0; i < 6; i++) {		
				dc.drawText( mScreen[2+i*2], mScreen[3+i*2], mLabelFont, mLabel3Labels[i], mJust);		
			}	
			
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mScreen[14], mScreen[15], mValueFont, $.mSampleProc.vLongBeatCnt.format("%d"), mJust);
			dc.drawText( mScreen[16], mScreen[17], mValueFont, $.mSampleProc.vShortBeatCnt.format("%d"), mJust);									
			dc.drawText( mScreen[18], mScreen[19], mValueFont, ($.mSampleProc.mpLongMax*100).format("%d"), mJust);
			dc.drawText( mScreen[20], mScreen[21], mValueFont, ($.mSampleProc.mpShortMax*100).format("%d"), mJust);
			dc.drawText( mScreen[22], mScreen[23], mValueFont, $.mSampleProc.mLongMax.format("%d"), mJust);	
			dc.drawText( mScreen[24], mScreen[25], mValueFont, $.mSampleProc.mShortMax.format("%d"), mJust);				

		}		
		// change every 6 seconds
    	//viewToShow = (viewToShow + 1) % 6;
    	//Sys.println("viewToShow : "+viewToShow);
    	
    	//Sys.println("Summary view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	
			
   		//View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    	mLabelFont = null;
    }
}


// display a summary of the current test data eg rMSSD
(:notUseJson)
class StatsView extends Ui.View {

	hidden var viewToShow;
	
	// title location %
	hidden var mTitleLoc = [50,10];
	hidden var mTitleLabels = ["Stats #1", "Stats #2", "Stats #3"];
	
	// coordinates of first and second set of labels as %
	// split to 1D array to save memory
	hidden var mLabelSetX = [ 35, 65, 35, 65, 35, 65 ];
	hidden var mLabelSetY = [ 24, 24, 44, 44, 66, 66 ];
	
	// coordinates of  value cordinates as %
	hidden var mLabelValueLocX = [ 35, 65, 35, 65, 35, 65 ];
	hidden var mLabelValueLocY = [ 32, 32, 53, 53, 75, 75 ];
		
	// label values
	hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "SDSD", "SDNN", "Ectopic" ];
	hidden var mLabel2Labels = [ "NN50","pNN50", "NN20", "pNN20", "Long", "Short" ];
	hidden var mLabel3Labels = [ "II","#II", "L_%", "L-ms", "S_%", "S-ms" ];

	// x%, y%, width/height
	hidden var mRectHorizWH = 64;
	hidden var mRectHorizX = 19;
	hidden var mRectHorizY = [ 19, 39, 61, 82 ];

	hidden var mRectVertWH = 64;
	hidden var mRectVertY = 19;	
	hidden var mRectVertX = [ 19, 50, 82 ];
	
	// scaled variables
	hidden var mTitleLocS = [0,0];	
	hidden var mLabelSetXS = new [ mLabelSetX.size() ];
	hidden var mLabelSetYS = new [ mLabelSetY.size() ];
	
	hidden var mLabelValueLocXS = new [ mLabelValueLocX.size() ];
	hidden var mLabelValueLocYS = new [ mLabelValueLocY.size() ];
	
	hidden var mRectHorizWHS = 0;
	hidden var mRectHorizXS = 0;
	hidden var mRectHorizYS = new [ mRectHorizY.size() ];

	hidden var mRectVertWHS = 0;
	hidden var mRectVertYS = 0;	
	hidden var mRectVertXS = new [ mRectVertX.size() ];
	
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_TINY;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;
	hidden var gg;

	function initialize(viewNum) { 
		viewToShow = viewNum;
		//gg = $._mAp$.
		View.initialize();
	}
	
	(:release)
	function fBuildJson() {}
	(:debug)
	function fBuildJson() {
		
		// build JSON string
		var mStr = "<jsonData id="+"jsonStatsDisp"+mScaleY+">[";
		
		// concatenate
		mStr = mStr + mTitleLocS[0].toString()+","+mTitleLocS[1].toString()+",";
		for( var i=0; i < mLabelSetXS.size(); i++) {
			mStr = mStr + mLabelSetXS[i].toString() +","+mLabelSetYS[i].toString()+",";
		}
		
		for( var i=0; i < mLabelValueLocXS.size(); i++) {
			mStr = mStr + mLabelValueLocXS[i].toString() +","+mLabelValueLocYS[i].toString()+",";
		}
		
		for( var i=0; i < mRectHorizYS.size(); i++) {
			mStr = mStr + mRectHorizYS[i].toString()+",";	
		}	
		
		mStr = mStr + mRectHorizWHS.toString()+",";
		mStr = mStr + mRectHorizXS.toString()+",";
		
		for( var i=0; i < mRectVertX.size(); i++) {
			mStr = mStr + mRectVertXS[i].toString()+",";		
		}	
		
		mStr = mStr+ mRectVertWHS.toString()+"," + mRectVertYS.toString();	
		
		// end string
		mStr = mStr+"]</jsonData>";
		
		Sys.println( mStr);
	}
	
	function onLayout(dc) {

		mScaleY = dc.getHeight();
		mScaleX = dc.getWidth();
		
		// convert % to numbers based on screen size
		mTitleLocS = [ (mTitleLoc[0]*mScaleX)/100, (mTitleLoc[1]*mScaleY)/100];	
		
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
		
		for( var i=0; i < mRectVertX.size(); i++) {
			mRectVertXS[i] = (mRectVertX[i] * mScaleX)/100;		
		}	
		mRectVertWHS = (mRectVertWH * mScaleX)/100;
		mRectVertYS = (mRectVertY * mScaleX)/100;	
		
		fBuildJson();

	}
		
    //! Restore the state of the app and prepare the view to be shown
    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
    }
      
    //! Update the view
    function onUpdate(dc) { 
    	//Sys.println("StatsView: onUpdate() called");
    	
    	if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, $.mBgColour);
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}
		for (var i=0; i < mRectVertXS.size(); i++) {
			dc.drawRectangle(mRectVertXS[i], mRectVertYS, 2, mRectVertWHS);
		}
		
		if (viewToShow == 1 ) {
			// draw 1st set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
			for (var i=0; i < mLabelSetX.size(); i++) {
				dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabel1Labels[i], mJust);			
			}
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);	
			//0.4.3 set to 0.1f from %d for rMSSD - does it fit?		
			dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, $.mSampleProc.mRMSSD.format("%.1f"), mJust);
			dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $.mSampleProc.mLnRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $.mSampleProc.avgPulse.format("%d"), mJust);
			
			// next two are floats
			var trunc = ($.mSampleProc.mSDSD*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			var str = "";
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}
			dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, str, mJust);			
			
			trunc = ($.mSampleProc.mSDNN*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}	
			dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mValueFont, str, mJust);		
			
			dc.drawText( mLabelValueLocXS[5], mLabelValueLocYS[5], mValueFont, $.mSampleProc.vEBeatCnt.format("%d"), mJust);
											
		} else if (viewToShow == 2) {
			// draw second set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[1], mJust);
			for (var i=0; i < mLabelSetXS.size(); i++) {
				dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabel2Labels[i], mJust);			
			}
			
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, $.mSampleProc.mNN50.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $.mSampleProc.mpNN50.format("%.0f"), mJust);
			dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $.mSampleProc.mNN20.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, $.mSampleProc.mpNN20.format("%.0f"), mJust);	
			dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mValueFont, $.mSampleProc.vLongBeatCnt.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[5], mLabelValueLocYS[5], mValueFont, $.mSampleProc.vShortBeatCnt.format("%d"), mJust);									
		} else if (viewToShow == 3) {
			// draw third set of labels and values
			// x, y, font, text, just
			dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[2], mJust);
			for (var i=0; i < mLabelSetXS.size(); i++) {
				dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabel3Labels[i], mJust);			
			}
			var mTmp = $.mSampleProc.getCurrentEntry(); 
			dc.setColor( $.mValueColour, Gfx.COLOR_TRANSPARENT);				
			dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, mTmp[0].format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $.mSampleProc.getNumberOfSamples().format("%d"), mJust);
			//dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $.mSampleProc.minDiffFound.format("%d"), mJust);
			//dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $.mSampleProc.maxDiffFound.format("%d"), mJust);	
			dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, ($.mSampleProc.mpLongMax*100).format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, $.mSampleProc.mLongMax.format("%d"), mJust);	
			dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mValueFont, ($.mSampleProc.mpShortMax*100).format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[5], mLabelValueLocYS[5], mValueFont, $.mSampleProc.mShortMax.format("%d"), mJust);				

		}		
		// change every 6 seconds
    	//viewToShow = (viewToShow + 1) % 6;
    	//Sys.println("viewToShow : "+viewToShow);
    	
    	//Sys.println("Summary view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	
			
   		//View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}