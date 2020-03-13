using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {

	function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if ( id.equals("timer")) {
            Ui.pushView(new Rez.Menus.TimerMenu(), new TimerMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("auto"))  {
            Ui.pushView(new Rez.Menus.AutoMenu(), new AutoMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("breathe"))  {
            Ui.pushView(new Rez.Menus.BreatheMenu(), new BreatheMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("colour"))   {
            Ui.pushView(new Rez.Menus.ColorMenu(), new ColorMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("green"))  {
            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().greenTimeSet)),
            	new GreenTimeDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("sound"))  {
            Ui.pushView(new Rez.Menus.YesNoMenu(), new ChoiceMenuDelegate(method(:setSound)), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("vibration"))  {
            Ui.pushView(new Rez.Menus.YesNoMenu(), new ChoiceMenuDelegate(method(:setVibe)), Ui.SLIDE_LEFT);
        }
        else if (id.equals("reset")) {
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Results", null, "results", null));
	        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
	        Ui.pushView(menu, new ResetMenuDelegate(), Ui.SLIDE_LEFT );
        }
    }

    function setSound(value) {
    	var app = App.getApp();
		app.soundSet = value;
    }

    function setVibe(value) {
    	var app = App.getApp();
		app.vibeSet = value;
    }
    
        function onBack() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
}

class GreenTimeDelegate extends Ui.NumberPickerDelegate {

    function onNumberPicked(duration) {

		var app = App.getApp();
		app.greenTimeSet = duration.value().toNumber();
	}
	
	function initialize() {
		NumberPickerDelegate.initialize();
	}
}