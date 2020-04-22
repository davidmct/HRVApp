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
	hidden var mLabelSet = [ [35,23], [65, 23], [35, 43], [65, 43], [35, 65], [35, 75] ];

	// coordinates of  value cordinates as %
	hidden var mLabelValueLoc = [ [35, 32], [65, 32], [35, 53], [65, 53], [35, 75], [65,75] ];
	// label values
	hidden var mLabel1Labels = [ "rMSSD", "Ln(HRV)", "avgBPM", "SDSD", "SDNN", "" ];
	hidden var mLabel2Labels = [ "NN50","pNN50", "NN20", "pNN20", "", "" ];

	// x%, y%, width/height
	hidden var mRectHoriz = [ [19, 19, 64], [19, 39, 64], [19, 61, 64], [19, 82, 64]];
	hidden var mRectVert = [ [19, 19, 64], [50, 19, 64], [82, 19, 64] ];
	
	hidden var mTitleLocS = [0,0];	
	hidden var mLabelSetS = [ [0,0], [0,0], [0,0], [0,0], [0,0], [0,0] ];
	hidden var mLabelValueLocS = [ [0,0], [0,0], [0,0], [0,0], [0,0], [0,0] ];
	hidden var mRectHorizS = [ [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0] ];
	hidden var mRectVertS = [ [0, 0, 0], [0, 0, 0], [0, 0, 0] ];
	
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
		
		Sys.println("mLabel1SetS.size() "+mLabelSetS.size());
		
		for( var i=0; i < mLabelSetS.size(); i++) {
			mLabelSetS[i][0] = (mLabelSet[i][0] * mScaleX)/100;	
			mLabelSetS[i][1] = (mLabelSet[i][1] * mScaleY)/100;
		}
				
		for( var i=0; i < mLabelValueLocS.size(); i++) {
			mLabelValueLocS[i][0] = (mLabelValueLoc[i][0] * mScaleX)/100;	
			mLabelValueLocS[i][1] = (mLabelValueLoc[i][1] * mScaleY)/100;
		}	
								
		for( var i=0; i < mRectHorizS.size(); i++) {
			mRectHorizS[i][0] = (mRectHoriz[i][0] * mScaleX)/100;	
			mRectHorizS[i][1] = (mRectHoriz[i][1] * mScaleY)/100;
			mRectHorizS[i][2] = (mRectHoriz[i][2] * mScaleX)/100;			
		}
		
		for( var i=0; i < mRectVertS.size(); i++) {
			mRectVertS[i][0] = (mRectVert[i][0] * mScaleX)/100;	
			mRectVertS[i][1] = (mRectVert[i][1] * mScaleY)/100;
			mRectVertS[i][2] = (mRectVert[i][2] * mScaleY)/100;			
		}		
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
		
		for (var i=0; i < mRectHorizS.size(); i++) {
			dc.drawRectangle(mRectHorizS[i][0], mRectHorizS[i][1], mRectHorizS[i][2], 2);
		}
		for (var i=0; i < mRectVert.size(); i++) {
			dc.drawRectangle(mRectVertS[i][0], mRectVertS[i][1], 2, mRectVertS[i][2]);
		}
				
		if (viewToShow == 0 || viewToShow == 1) {
			// draw 1st set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[0], mJust);
			for (var i=0; i < mLabelSet.size(); i++) {
				dc.drawText( mLabelSetS[i][0], mLabelSetS[i][1], mLabelFont, mLabel1Labels[i], mJust);			
			}
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mLabelValueLocS[0][0], mLabelValueLocS[0][1], mValueFont, $._mApp.mSampleProc.mRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLocS[1][0], mLabelValueLocS[1][1], mValueFont, $._mApp.mSampleProc.mLnRMSSD.format("%d"), mJust);
			dc.drawText( mLabelValueLocS[2][0], mLabelValueLocS[2][1], mValueFont, $._mApp.mSampleProc.avgPulse.format("%d"), mJust);
			
			// next two are floats
			var trunc = ($._mApp.mSampleProc.mSDSD*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			var str = "";
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}
			dc.drawText( mLabelValueLocS[3][0], mLabelValueLocS[3][1], mValueFont, str, mJust);			
			
			trunc = ($._mApp.mSampleProc.mSDNN*10).toNumber().toFloat()/10; // truncate to 1 decimal places
			if (trunc > 100.0) { str = trunc.format("%.0f"); } else {str = trunc.format("%.1f");}	
			dc.drawText( mLabelValueLocS[4][0], mLabelValueLocS[4][1], mValueFont, str, mJust);										
		} else {
			// draw second set of labels and values
			// x, y, font, text, just
			dc.setColor( mLabelColour, Gfx.COLOR_TRANSPARENT);
			dc.drawText( mTitleLocS[0], mTitleLocS[1], mTitleFont, mTitleLabels[1], mJust);
			for (var i=0; i < mLabelSet.size(); i++) {
				dc.drawText( mLabelSetS[i][0], mLabelSetS[i][1], mLabelFont, mLabel2Labels[i], mJust);			
			}
			
			dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);			
			dc.drawText( mLabelValueLocS[0][0], mLabelValueLocS[0][1], mValueFont, $._mApp.mSampleProc.mNN50.format("%d"), mJust);
			dc.drawText( mLabelValueLocS[1][0], mLabelValueLocS[1][1], mValueFont, $._mApp.mSampleProc.mpNN50.format("%.0f"), mJust);
			dc.drawText( mLabelValueLocS[2][0], mLabelValueLocS[2][1], mValueFont, $._mApp.mSampleProc.mNN20.format("%d"), mJust);
			dc.drawText( mLabelValueLocS[3][0], mLabelValueLocS[3][1], mValueFont, $._mApp.mSampleProc.mpNN20.format("%.0f"), mJust);				
		}
		
		// change every 4 seconds
    	viewToShow = (viewToShow + 1) % 4;
    	Sys.println("viewToShow : "+viewToShow);
			
   		//View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}