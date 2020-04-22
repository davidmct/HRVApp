using Toybox.WatchUi as Ui;
using Toybox.Application as App;

class ResetMenuDelegate extends Ui.Menu2InputDelegate {

    function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("settings")) {
 			var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetSettings)), Ui.SLIDE_IMMEDIATE ); 
			//Ui.pushView(new Ui.Confirmation("Reset settings?"), new SettingsDelegate(), Ui.SLIDE_IMMEDIATE);
        }
        else if (id.equals("results")) {
         	var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setResetResults)), Ui.SLIDE_IMMEDIATE );
			//Ui.pushView(new Ui.Confirmation("Clear results?"), new ResultsDelegate(), Ui.SLIDE_IMMEDIATE);
        }
    }
    
    function setResetSettings(value) {
		if (value == 1) { 
            $._mApp.mStorage.resetSettings();
        }	
    }
    
    function setResetResults(value) {
		if (value == 1) { 
            $._mApp.mStorage.resetResults();
            // and push to memory
            $._mApp.mStorage.storeResults();
        }	
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    } 
    
}