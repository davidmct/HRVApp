using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.System as Sys;

class SettingsMenuDelegate extends Ui.Menu2InputDelegate {

	function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if ( id.equals("timer")) {
     		var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Timer Test")});
	        menu.addItem(new Ui.MenuItem("Duration", null, "duration", null));
	        Ui.pushView(menu, new TimerMenuDelegate(), Ui.SLIDE_LEFT );
        }
        else if ( id.equals("auto"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Auto")});
	        menu.addItem(new Ui.MenuItem("Duration", null, "duration", null));
	        menu.addItem(new Ui.MenuItem("Schedule", null, "schedule", null));
	        Ui.pushView(menu, new AutoMenuDelegate(), Ui.SLIDE_LEFT );
        }
        else if ( id.equals("breathe"))  { 
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Breathe")});
	        menu.addItem(new Ui.MenuItem("Inhale", null, "inhale", null));
	        menu.addItem(new Ui.MenuItem("Exhale", null, "exhale", null));
	        menu.addItem(new Ui.MenuItem("Relax", null, "relax", null));	        
	        Ui.pushView(menu, new BreatheMenuDelegate(), Ui.SLIDE_LEFT );
        }
        else if ( id.equals("colour"))   {
            Ui.pushView(new Rez.Menus.ColorMenu(), new ColorMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if ( id.equals("green"))  {
            Ui.pushView(new NumberPicker(App.getApp().greenTimeSet, 9999, 1), new GreenTimePickerDelegate(), Ui.SLIDE_IMMEDIATE);
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

class GreenTimePickerDelegate extends Ui.PickerDelegate {

   function initialize() {
        PickerDelegate.initialize();
    }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		var app = App.getApp();
		var mNum;
		mNum = values[1].toNumber() + values[0].toNumber() * 100;
		Sys.println("Set  Greentime Duration: " + values + " to "+mNum);
		app.greenTimeSet = mNum;

        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
