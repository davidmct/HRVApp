using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;


// Show time in test and current RMSSD and interval

class CurrentValueView extends Ui.View {

	var mCurrentLayout;
	
	function initialize() { View.initialize();}
	
	function onLayout(dc) {
		mCurrentLayout = Rez.Layouts.CurrentViewLayout(dc);
		//Sys.println("CurrentView: onLayout() called ");
		if ( mCurrentLayout != null ) {
			setLayout (mCurrentLayout);
		} else {
			Sys.println("layout null");
		}
	}
		
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {

    }
    
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

		var mLabelColour = mapColour( $._mApp.lblColSet);
		var mValueColour = mapColour( $._mApp.txtColSet);
		
		var mMessage = "";
		
		updateLayoutField("CurrentViewTitle", null, mLabelColour);
		// text area so check
		// $._mApp.
		mMessage = "Running for ";
		// current time
		mMessage += "A:AA";
		mMessage += " out of ";
		// add max time
		mMessage +="X:XX";
		
		updateLayoutField("CurrentViewString", mMessage, mValueColour);	
			
		updateLayoutField("CurrentrMSSD_txt", null, mLabelColour);				
		updateLayoutField("CurrentInterval_txt", null, mLabelColour);	
		
		// need to sort out values			
		updateLayoutField( "CurrentrMSSD_val", $._mApp.mSampleProc.mRMSSD.format("%d"), mValueColour);
		updateLayoutField( "CurrentInterval_val", $._mApp.mSampleProc.mLnRMSSD.format("%d"), mValueColour);

		// Testing only. Draw used memory
		//var str = System.getSystemStats().usedMemory.toString();
		//dc.setColor(WHITE, BLACK);
		//dc.drawText(dc.getWidth() / 2, 0, font, str, Gfx.TEXT_JUSTIFY_CENTER);
		
		View.onUpdate(dc);
   		return true;
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

}