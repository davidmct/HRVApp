using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;


// Show time in test and current RMSSD and interval
// also max/min difference between RR intervals 

class CurrentValueView extends Ui.View {

	var timer = "";
	var timeLimit = "";
	hidden var myTextArea;
	hidden var mTitleLoc = [50, 12]; // %
	hidden var mTitleLocS = [0,0];	
	hidden var mTitleLabels = ["Current"];
	
	// x, y, width, height
	hidden var mMessageLoc = [10, 17, 80, 30]; // %
	hidden var mMesssgeLocS = new [mMessageLoc.size()];	
	
	// coordinates of labels as %
	// split to 1D array to save memory
	hidden var mLabelSetX = [ 28, 72, 50];
	hidden var mLabelSetY = [ 47, 47, 68]; // 68 was 65
	
	// coordinates of  value cordinates as %
	// rMSSD, INterval, DeltaMin, DeltaMax
	hidden var mLabelValueLocX = [ 28, 72, 28, 72];
	hidden var mLabelValueLocY = [ 57, 57, 78, 78]; //78 was 75
		
	// label values
	hidden var mLabels = [ "rMSSD", "Interval", "Min/Max RR delta" ];
	
	// scaled variables
	hidden var mLabelSetXS = new [ mLabelSetX.size()];
	hidden var mLabelSetYS = new [ mLabelSetY.size()];
	
	hidden var mLabelValueLocXS = new [ mLabelValueLocX.size()];
	hidden var mLabelValueLocYS = new [ mLabelValueLocY.size()];
		
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_MEDIUM;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;
	
	function initialize() { View.initialize();}
	
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
	
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
		$._mApp.mTestControl.setObserver2(self.method(:onNotify));
    }
    
    function onNotify(symbol, params) {
		// [ timer, timer limit]
		timer = params[0];
		timeLimit = params[1];	
	}

    //! Update the view
    function onUpdate(dc) {

		var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);		
		var mMessage = "";
		
		dc.setColor(Gfx.COLOR_TRANSPARENT, mapColour($._mApp.bgColSet));
		dc.clear();
		
		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
		
		mMessage = "Running for "+timer+" out of "+timeLimit;
		
		// 0.4.2 - select which text area to use
		var myTextArea;
		if (Ui.WatchUi has :TextArea) {
			Sys.println("UI has TextArea");
			myTextArea = new Ui.TextArea({
	            :text=>mMessage,
	            :color=>mValueColour,
	            :backgroundColor=>mapColour($._mApp.bgColSet),
	            :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],
	            :locX=>mMesssgeLocS[0],
	            :locY=>mMesssgeLocS[1],
	            :width=>mMesssgeLocS[2],
	            :height=>mMesssgeLocS[3],
	            :justification=>Gfx.TEXT_JUSTIFY_CENTER
	        });					
		} else {
			Sys.println("UI does not have TextArea");
			myTextArea = new Ui.Text({
	            :text=>mMessage,
	            :color=>mValueColour,
	            :backgroundColor=>mapColour($._mApp.bgColSet),
	            :font=>Gfx.FONT_XTINY,
	            :locX=>mMesssgeLocS[0],
	            :locY=>mMesssgeLocS[1],
	            :width=>mMesssgeLocS[2],
	            :height=>mMesssgeLocS[3],
	            :justification=>Gfx.TEXT_JUSTIFY_CENTER
	        });		
	        
	        // now we need to pick font		
	        // :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],

	        if ($._mApp.mDeviceType == RES_240x240) {
	        	myTextArea.setFont(Gfx.FONT_SMALL);
	        } else if ( $._mApp.mDeviceType == RES_260x260 ) {
	        	myTextArea.setFont(Gfx.FONT_SMALL);
	        } else if ( $._mApp.mDeviceType == RES_280x280 ) {
	        	myTextArea.setFont(Gfx.FONT_SMALL);
	        }

		}
	    Sys.println("FIX CURRENT VIEW TEXTAREA FONTS");	
	    	
		//myTextArea = new Ui.TextArea({
        //    :text=>mMessage,
        //    :color=>mValueColour,
        //    :font=>[Gfx.FONT_MEDIUM, Gfx.FONT_SMALL, Gfx.FONT_TINY, Gfx.FONT_XTINY],
        //    :locX=>mMesssgeLocS[0],
        //    :locY=>mMesssgeLocS[1],
        //    :width=>mMesssgeLocS[2],
        //    :height=>mMesssgeLocS[3],
        //    :justification=>Gfx.TEXT_JUSTIFY_CENTER
        //});
        myTextArea.draw(dc);	
        
		dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
		        
        // draw rest of labels
  		for (var i=0; i < mLabelSetX.size(); i++) {
			dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabels[i], mJust);			
		}      
        
        // draw values
		dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);
		dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, $._mApp.mSampleProc.mRMSSD.format("%d"), mJust);
		dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $._mApp.mSampleProc.getCurrentEntry().format("%d"), mJust);
		dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $._mApp.mSampleProc.minDiffFound.format("%d"), mJust);
		dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, $._mApp.mSampleProc.maxDiffFound.format("%d"), mJust);		
		
		//Sys.println("Current view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
		//	", "+System.getSystemStats().freeMemory.toString()+
		//	", "+System.getSystemStats().totalMemory.toString()			
		//	);	
		
		//View.onUpdate(dc);
   		return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {

    }

}