using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics;
using Toybox.System as Sys;

using HRVStorageHandler as mStorage;
using GlanceGen as GG;

class ResetMenuDelegate extends Ui.Menu2InputDelegate {

    function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
        
 		var menu = new Ui.Menu2({:title=>"Reset"});
        menu.addItem(new Ui.MenuItem("Yes", null, "1", null));
        menu.addItem(new Ui.MenuItem("No", null, "2", null));    
     	
     	//if( id.equals("s")) {
 	    //    Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetSettings)), Ui.SLIDE_IMMEDIATE ); 
        //}
        //else if (id.equals("r")) {
 	    //    Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetResults)), Ui.SLIDE_IMMEDIATE );
        //}
        //else if (id.equals("t")) {
 	    //    Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setTEST)), Ui.SLIDE_IMMEDIATE );
        //}
        
        var _lbl = :setResetSettings;
        if( id.equals("s")) {
        	_lbl = :setResetSettings;
        }
        else if (id.equals("r")) {
 	        _lbl= :setResetResults;
        }
        else if (id.equals("t")) {
        	_lbl = :setTEST;
        }
 	    Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(_lbl)), Ui.SLIDE_IMMEDIATE );
    }
    
    function setResetSettings(value) {
		if (value == 1) { 
			//var oldSensor = $.mSensorTypeExt;
            mStorage.resetSettings();
            //0.4.04
            // this may have changed sensor type !!
            //$.mTestControl.fCheckSwitchType( :SensorType, oldSensor);   
        }	
    }
    
    function setTEST(value) {
    	if (value == 1) {
    		$.mTestMode = true;
    		Sys.println("T-mode");
    	} else {
    		$.mTestMode = false;
    	}
    }	
    
    function setResetResults(value) {
		if (value == 1) { 
            mStorage.resetResults();
            // and push to memory
            mStorage.storeResults();
			GG.resetResGL(true);
            // and push to memory
            //0.6.4 - already saved in memory by reset above
            //GG.storeResGL();
        }	
    }
 
//0.4.3 - leave for class   
//    function onBack() {
//        Ui.popView(Ui.SLIDE_IMMEDIATE);
//   }

//0.4.04 - should only be called on CheckMenuItem 
// Leave for class to deal with
//    function onDone() {
//        Ui.popView(Ui.SLIDE_IMMEDIATE);
//    } 
    
}