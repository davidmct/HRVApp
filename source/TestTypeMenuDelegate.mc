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
    	//Sys.println("onBack() TestType");
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
    	//Sys.println("onDone() TestType");
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }   
 
    function onSelect(item) {
		var mId = item.getId();
		
		//Sys.println("onSlect() TestType");
		
		// if the test type or source changes then we need to reset state machine
		// in FIT case will need to discard any open sessions - this is done on start so OK
		
		if( mId == :Manual) {
			var oldTestType = $._mApp.testTypeSet;
            $._mApp.testTypeSet = TYPE_MANUAL;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Timer)).setSelected(false);    
            // if type has changed then force restart of state machine  
            $._mApp.mTestControl.fCheckSwitchType( :TestType, oldTestType);            
        }
        else if( mId == :Timer)  {
        	var oldTestType = $._mApp.testTypeSet;
            $._mApp.testTypeSet = TYPE_TIMER;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Manual)).setSelected(false);     
            $._mApp.mTestControl.fCheckSwitchType( :TestType, oldTestType);   
        }
        else if( mId == :Internal)  {
        	var oldSensor = $._mApp.mSensorTypeExt;
            $._mApp.mSensorTypeExt = SENSOR_INTERNAL;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Search)).setSelected(false);
            $._mApp.mTestControl.fCheckSwitchType( :SensorType, oldSensor);   
        }
        else if( mId == :Search)  {
            var oldSensor = $._mApp.mSensorTypeExt;
            $._mApp.mSensorTypeExt = SENSOR_SEARCH;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Internal)).setSelected(false);  
            $._mApp.mTestControl.fCheckSwitchType( :SensorType, oldSensor);  
        }
        else if( mId == :Write)  {
        	var oldFitWrite = $._mApp.mFitWriteEnabled;
            $._mApp.mFitWriteEnabled = true;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:NoWrite)).setSelected(false);   
            $._mApp.mTestControl.fCheckSwitchType( :FitType, oldFitWrite);  
        }
        else if( mId == :NoWrite)  {
        	var oldFitWrite = $._mApp.mFitWriteEnabled;        
            $._mApp.mFitWriteEnabled = false;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Write)).setSelected(false);  
            $._mApp.mTestControl.fCheckSwitchType( :FitType, oldFitWrite);  
        }        
        else if( mId == :autoS)  {
            $._mApp.mBoolScaleII = true;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:fixedS)).setSelected(false);  
            Sys.println("Interval Auto ON");  
        }
        else if( mId == :fixedS)  {       
            $._mApp.mBoolScaleII = false;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:autoS)).setSelected(false);   
            Sys.println("Interval Auto OFF");  
        }
        
        // this should turn item blue...
        //Sys.println("calling request update in TestTypeMenuDelegate");       
        requestUpdate();
    }
    
}