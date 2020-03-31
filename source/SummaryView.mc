using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

// display a summary of the current test data eg rMSSD
class SummaryView extends Ui.View {

	var mSummaryLayout;

	function initialize() { View.initialize();}
	
	function onLayout(dc) {
		mSummaryLayout = Rez.Layouts.SummaryViewLayout(dc);
		//Sys.println("SummaryView: onLayout() called ");
		if ( mSummaryLayout != null ) {
			setLayout (mSummaryLayout);
		} else {
			Sys.println("layout null");
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
    
//    hidden function updateLayoutField(fieldId, fieldValue, fieldColour, fieldJust) {
//       var drawable = findDrawableById(fieldId);
        //Sys.println("ResultView: updateLayoutField() called " + drawable );
//        if (drawable != null) {
        	//Sys.println("ResultView: updateLayoutField() setting colour/Just ");
//            drawable.setColor(fieldColour);
//            drawable.setJustification(fieldJust);
//            if (fieldValue != null) {
//            	drawable.setText(fieldValue);
//            }
//        }
//    }
    
    hidden function updateLayoutField(fieldId, fieldValue, fieldColour) {
        var drawable = findDrawableById(fieldId);
        if (drawable != null) {
            drawable.setColor(fieldColour);
            if (fieldValue != null) {
            	drawable.setText(fieldValue);
            }
        }
    }
    
    
    //! Update the view
    function onUpdate(dc) { 
    	//Sys.println("SummaryView: onUpdate() called");
		
		var mLabelColour = mapColour( $._mApp.lblColSet);
		// oddly doing this in layout now works!!
//		var mLabelJust = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
//		var mValueJust = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		//Sys.println("SummaryView: update fields of layout: labelCol: "+ mLabelColour + " Value colour " + mValueColour);
		
		// should be able to set justification in layout!!
		updateLayoutField("ViewTitle", null, mLabelColour);
		updateLayoutField("rMSSD", null, mLabelColour);
		updateLayoutField("Ln_HRV", null, mLabelColour);		
		updateLayoutField("avgPulse", null, mLabelColour);		
		updateLayoutField("SDSD", null, mLabelColour);	
		updateLayoutField("NN50", null, mLabelColour);	
		updateLayoutField("pNN50", null, mLabelColour);	
		updateLayoutField("NN20", null, mLabelColour);
		updateLayoutField("pNN20", null, mLabelColour);	
		updateLayoutField("SDANN", null, mLabelColour);		
					
		updateLayoutField( "rMSSD_Value", $._mApp.mSampleProc.mRMSSD.format("%d"), mValueColour);
		updateLayoutField( "Ln_HRV_Value", $._mApp.mSampleProc.mLnRMSSD.format("%d"), mValueColour);		
		updateLayoutField( "avgPulse_Value", $._mApp.mSampleProc.avgPulse.format("%d"), mValueColour);
		updateLayoutField( "SDSD_Value", $._mApp.mSampleProc.mSDSD.format("%d"), mValueColour);
		updateLayoutField( "SDANN_Value", $._mApp.mSampleProc.mSDANN.format("%d"), mValueColour);
		updateLayoutField( "NN50_Value", $._mApp.mSampleProc.mNN50.format("%d"), mValueColour);		
		updateLayoutField( "pNN50_Value", $._mApp.mSampleProc.mpNN50.format("%d"), mValueColour);
		updateLayoutField( "NN20_Value", $._mApp.mSampleProc.mNN20.format("%d"), mValueColour);		
		updateLayoutField( "pNN20_Value", $._mApp.mSampleProc.mpNN20.format("%d"), mValueColour);		
			
   		View.onUpdate(dc);
   		//return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
}