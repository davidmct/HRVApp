using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class TestTypeMenuDelegate extends Ui.Menu2InputDelegate {
	// menu we are working in
	var mSrcMenu;
    function initialize(srcMenu) {
    	mSrcMenu = srcMenu; 
    	Menu2InputDelegate.initialize();
    }

    function onBack() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }   
 
    function onSelect(item) {
		var mId = item.getId();
		
		if( mId == :Manual) {
            $._mApp.testTypeSet = TYPE_MANUAL;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Timer)).setSelected(false);           
        }
        else if( mId == :Timer)  {
            $._mApp.testTypeSet = TYPE_TIMER;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Manual)).setSelected(false);   
        }
        else if( mId == :Internal)  {
        	var oldSensor = $._mApp.mSensorTypeExt;
            $._mApp.mSensorTypeExt = SENSOR_INTERNAL;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Search)).setSelected(false);
            $._mApp.mSensor.fSwitchSensor( oldSensor);   
        }
        else if( mId == :Search)  {
            var oldSensor = $._mApp.mSensorTypeExt;
            $._mApp.mSensorTypeExt = SENSOR_SEARCH;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Internal)).setSelected(false);  
            $._mApp.mSensor.fSwitchSensor( oldSensor);  
        }
        else if( mId == :Write)  {
            $._mApp.mFitWriteEnabled = true;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:NoWrite)).setSelected(false);  
        }
        else if( mId == :NoWrite)  {
            $._mApp.mFitWriteEnabled = false;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Write)).setSelected(false);  
        }
        
        // this should turn item blue...
        Sys.println("calling request update in TestTypeMenuDelegate");       
        requestUpdate();
    }
    
}