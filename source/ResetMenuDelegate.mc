using Toybox.WatchUi as Ui;
using Toybox.Application as App;
using Toybox.Graphics;

class ResetMenuDelegate extends Ui.Menu2InputDelegate {

    function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("s")) {
 			var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "1", null));
	        menu.addItem(new Ui.MenuItem("No", null, "2", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetSettings)), Ui.SLIDE_IMMEDIATE ); 
        }
        else if (id.equals("r")) {
         	var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "1", null));
	        menu.addItem(new Ui.MenuItem("No", null, "2", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetResults)), Ui.SLIDE_IMMEDIATE );
        }
    }
    
    function setResetSettings(value) {
		if (value == 1) { 
			var oldSensor = $._mApp.mSensorTypeExt;
            $._mApp.mStorage.resetSettings();
            //0.4.04
            // this may have changed sensor type !!
            $._mApp.mTestControl.fCheckSwitchType( :SensorType, oldSensor);   
        }	
    }
    
    function setResetResults(value) {
		if (value == 1) { 
            $._mApp.mStorage.resetResults();
            // and push to memory
            $._mApp.mStorage.storeResults();
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