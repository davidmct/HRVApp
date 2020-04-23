using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// display a summary of the current test data eg rMSSD
class SummaryView extends Ui.View {

	hidden var viewToShow;
	
	// title location %
	hidden var mTitleLoc = [50,10];
	hidden var mTitleLabels = ["Stats #1", "Stats #2"];
	
	// coordinates of first and second set of labels as %
	// split to 1D array to save memory
	hidden var mLabelSetX = [ 35, 65, 35, 65, 35, 35 ];
	hidden var mLabelSetY = [ 23, 23, 43, 43, 65, 75 ];
	
	// coordinates of  value cordinates as %
	hidden var mLabelValueLocX = [ 35, 65, 35, 65, 35, 65 ];
	hidden var mLabelValueLocY = [ 32, 32, 53, 53, 75, 75 ];
		
	// label values
	hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "SDSD", "SDNN", "" ];
	hidden var mLabel2Labels = [ "NN50","pNN50", "NN20", "pNN20", "", "" ];

	// x%, y%, width/height
	hidden var mRectHorizWH = 64;
	hidden var mRectHorizX = 19;
	hidden var mRectHorizY = [ 19, 39, 61, 82 ];

	hidden var mRectVertWH = 64;
	hidden var mRectVertY = 19;	
	hidden var mRectVertX = [ 19, 50, 82 ];
	
	// scaled variables
	hidden var mTitleLocS = [0,0];	
	hidden var mLabelSetXS = [ 0, 0, 0, 0, 0, 0 ];
	hidden var mLabelSetYS = [ 0, 0, 0, 0, 0, 0 ];
	
	hidden var mLabelValueLocXS = [ 0, 0, 0, 0, 0, 0 ];
	hidden var mLabelValueLocYS = [ 0, 0, 0, 0, 0, 0 ];
	
	hidden var mRectHorizWHS = 0;
	hidden var mRectHorizXS = 0;
	hidden var mRectHorizYS = [ 0, 0, 0, 0 ];

	hidden var mRectVertWHS = 0;
	hidden var mRectVertYS = 0;	
	hidden var mRectVertXS = [ 0, 0, 0 ];
	
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_TINY;
	hidden var mTitleFont = Gfx.FONT_MEDIUM;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
	
	hidden var mScaleY;
	hidden var mScaleX;

	//var mSummaryLayout;

	function initialize() { 
		viewToShow = 0;
		View.initialize();
	}
	
	function onLayout(dc) {
		//mSummaryLayout = Rez.Layouts.SummaryViewLayout(dc);
		//Sys.println("SummaryView: onLayout() called ");
		//if ( mSummaryLayout != null ) {
		//	setLayout (mSummaryLayout);
		//} else {
		//	Sys.println("Summary View layout null");
		//}
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

	}
		
    //! Restore the state of the app and prepare the view to be shown
    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This include
    //! loading resources into memory.
    function onShow() {
    	//Sys.println("ResultView: onShow() called ");   	
	
		//return true;
    }
      
    //! Update the view
    function onUpdate(dc) { 
    	//Sys.println("SummaryView: onUpdate() called");
		
		var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		dc.setColor( Gfx.COLOR_TRANSPARENT, mapColour($._mApp.bgColSet));
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);

		for (var i=0; i < mRectHorizYS.size(); i++) {
			dc.drawRectangle(mRectHorizXS, mRectHorizYS[i], mRectHorizWHS, 2);
		}
		for (var i=0; i < mRectVertXS.size(); i++) {
			dc.drawRectangle(mRectVertXS[i], mRectVertYS, 2, mRectVertWHS);
		}
		
		if (viewToShow == 0 || viewToShow == 1) {
			// draw 1st set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
			for (var i=0; i < mLabelSetX.size(); i++) {
				dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabel1Labels[i], mJust);			
			}
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, $._mApp.mSampleProc.mRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $._mApp.mSampleProc.mLnRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $._mApp.mSampleProc.avgPulse.format("%d"), mJust);
			
			// next two are floats
			var trunc = ($._mApp.mSampleProc.mSDSD*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			var str = "";
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}
			dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, str, mJust);			
			
			trunc = ($._mApp.mSampleProc.mSDNN*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}	
			dc.drawText( mLabelValueLocXS[4], mLabelValueLocYS[4], mValueFont, str, mJust);										
		} else {
			// draw second set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[1], mJust);
			for (var i=0; i < mLabelSetXS.size(); i++) {
				dc.drawText( mLabelSetXS[i], mLabelSetYS[i], mLabelFont, mLabel2Labels[i], mJust);			
			}
			
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mLabelValueLocXS[0], mLabelValueLocYS[0], mValueFont, $._mApp.mSampleProc.mNN50.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[1], mLabelValueLocYS[1], mValueFont, $._mApp.mSampleProc.mpNN50.format("%.0f"), mJust);
			dc.drawText( mLabelValueLocXS[2], mLabelValueLocYS[2], mValueFont, $._mApp.mSampleProc.mNN20.format("%d"), mJust);
			dc.drawText( mLabelValueLocXS[3], mLabelValueLocYS[3], mValueFont, $._mApp.mSampleProc.mpNN20.format("%.0f"), mJust);				
		}
		
		// change every 4 seconds
    	viewToShow = (viewToShow + 1) % 4;
    	Sys.println("viewToShow : "+viewToShow);
    	
    	Sys.println("Summary view memory used, free, total: "+System.getSystemStats().usedMemory.toString()+
			", "+System.getSystemStats().freeMemory.toString()+
			", "+System.getSystemStats().totalMemory.toString()			
			);	
			
   		//View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    	// free up all the arrays
		 mTitleLabels = null;
		 mLabelSetX = null;
		 mLabelSetY = null;	
		 mLabelValueLocX = null;
		 mLabelValueLocY = null;
		 mLabel1Labels = null;
		 mLabel2Labels = null;
		 mRectHorizY = null;
		 mRectVertX = null;	
		 mTitleLocS = null;	
		 mLabelSetXS = null;
		 mLabelSetYS = null;	
		 mLabelValueLocXS = null;
		 mLabelValueLocYS = null;
		 mRectHorizYS = null;
		 mRectVertXS = null;   
    }
}