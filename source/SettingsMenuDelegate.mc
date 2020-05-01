using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {
	
	function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if ( id.equals("timer")) {
     		var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Timer")});
	        menu.addItem(new Ui.MenuItem("Duration", null, "duration", null));
	        Ui.pushView(menu, new TimerMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
        else if ( id.equals("colour"))   {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Colour")});
	        menu.addItem(new Ui.MenuItem("Background", null, "background", null));
	        menu.addItem(new Ui.MenuItem("Text", null, "text", null));
	        menu.addItem(new Ui.MenuItem("Labels", null, "labels", null));	        
	        Ui.pushView(menu, new ColourMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
        else if ( id.equals("sound"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Sound")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSound)), Ui.SLIDE_IMMEDIATE );     
        }
        else if ( id.equals("vibration"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Vibration")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setVibe)), Ui.SLIDE_IMMEDIATE );  
        }
        else if (id.equals("reset")) {
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Results", null, "results", null));
	        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
	        Ui.pushView(menu, new ResetMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
    }

    function setSound(value) {
		if (value == 1) { $._mApp.soundSet = true;} else { $._mApp.soundSet = false;}
    }

    function setVibe(value) {
		if (value == 1) { $._mApp.vibeSet = true; } else { $._mApp.vibeSet = false;}
    } 
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
}
