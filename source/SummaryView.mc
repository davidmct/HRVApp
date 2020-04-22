using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// display a summary of the current test data eg rMSSD
class SummaryView extends Ui.View {

	hidden var viewToShow;
	
	hidden var mTitleLoc = [50,13];
	hidden var mTitleLabels = ["Stats #1", "Stats #2"];
	
	// coordinates of first set of labels as %
	hidden var mLabel1Set = [ [27,32], [52, 32], [77, 32], [27, 50], [77, 68], [0,0] ];
	// coordinates of first set of labels as %
	hidden var mLabel2Set = [ [52, 50], [77, 50], [27, 68], [52, 68], [0,0], [0,0] ];	
	// coordinates of  value cordinates
	hidden var mLabelValueLoc = [ [27,39], [52, 39], [77, 39], [27, 57], [77, 75], [0,0] ];
	// label values
	hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "SDSD", "SDNN", "" ];
	hidden var mLabel2Labels = [ "NN50","pNN50", "NN20", "pNN20", "", "" ];

	// x, y, width/height
	hidden var mRectHoriz = [ [14, 27, 75], [14, 46, 75], [14, 63, 75], [14, 80, 75]];
	hidden var mRectVert = [ [14, 27, 54], [40, 27, 54], [64, 27, 54] ];
	
	hidden var mLabelFont = Gfx.FONT_XTINY;
	hidden var mValueFont = Gfx.FONT_TINY;
	hidden var mRectColour = Gfx.COLOR_RED;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;

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
		
		dc.setColor( mapColour($._mApp.bgColSet), mapColour($._mApp.bgColSet));
		dc.clear();
		
		// draw lines
		dc.setColor( mRectColour, Gfx.COLOR_TRANSPARENT);
		
		for (var i=0; i < mRectHoriz.size(); i++) {
			dc.drawRectangle(mRectHoriz[i][0], mRectHoriz[i][1], mRectHoriz[i][2], 2);
		}
		for (var i=0; i < mRectVert.size(); i++) {
			dc.drawRectangle(mRectVert[i][0], mRectVert[i][1], 2, mRectVert[i][2]);
		}
				
		if (viewToShow == 0) {
			// draw 1st set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLoc[0], mTitleLoc[1], mLabelFont, mTitleLabels[0], mJust);
			for (var i=0; i < mLabel1Set.size(); i++) {
				dc.drawText( mLabel1Set[i][0], mLabel1Set[i][1], mLabelFont, mLabel1Labels[i], mJust);			
			}
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);
			
			dc.drawText( mLabelValueLoc[0][0], mLabelValueLoc[0][1], mValueFont, $._mApp.mSampleProc.mRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLoc[1][0], mLabelValueLoc[1][1], mValueFont, $._mApp.mSampleProc.mLnRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLoc[2][0], mLabelValueLoc[2][1], mValueFont, $._mApp.mSampleProc.avgPulse.format("%d"), mJust);
			
			// next two are floats
			var trunc = ($._mApp.mSampleProc.mSDSD*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			var str = "";
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}
			dc.drawText( mLabelValueLoc[3][0], mLabelValueLoc[3][1], mValueFont, str, mJust);			
			
			trunc = ($._mApp.mSampleProc.mSDNN*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}	
			dc.drawText( mLabelValueLoc[4][0], mLabelValueLoc[4][1], mValueFont, str, mJust);										
		} else {
			// draw second set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLoc[0], mTitleLoc[1], mLabelFont, mTitleLabels[0], mJust);
			for (var i=0; i < mLabel2Set.size(); i++) {
				dc.drawText( mLabel2Set[i][0], mLabel2Set[i][1], mLabelFont, mLabel2Labels[i], mJust);			
			}
			
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);
			
			dc.drawText( mLabelValueLoc[0][0], mLabelValueLoc[0][1], mValueFont, $._mApp.mSampleProc.mNN50.format("%d"), mJust);
			dc.drawText( mLabelValueLoc[1][0], mLabelValueLoc[1][1], mValueFont, $._mApp.mSampleProc.mpNN50.format("%.0f"), mJust);
			dc.drawText( mLabelValueLoc[2][0], mLabelValueLoc[2][1], mValueFont, $._mApp.mSampleProc.mNN20.format("%d"), mJust);
			dc.drawText( mLabelValueLoc[3][0], mLabelValueLoc[3][1], mValueFont, $._mApp.mSampleProc.mpNN20.format("%.0f"), mJust);				
		}
		
		// change every 4 seconds
    	viewToShow = (viewToShow + 1) % 4;
			
   		//View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}