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
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSaveSettings)), Ui.SLIDE_LEFT ); 
			//Ui.pushView(new Ui.Confirmation("Reset settings?"), new SettingsDelegate(), Ui.SLIDE_LEFT);
        }
        else if (id.equals("results")) {
         	var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSaveResults)), Ui.SLIDE_LEFT );
			//Ui.pushView(new Ui.Confirmation("Clear results?"), new ResultsDelegate(), Ui.SLIDE_LEFT);
        }
    }
    
    function setSaveSettings(value) {
		if (value == "optOne") { 
            App.getApp().mStorage.resetSettings();
        }	
    }
    
    function setSaveResults(value) {
		if (value == "optOne") { 
            App.getApp().mStorage.resetResults();
        }	
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(Ui.SLIDE_DOWN);
    } 
    
}