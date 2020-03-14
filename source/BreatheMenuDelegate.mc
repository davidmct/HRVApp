using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class BreatheMenuDelegate extends Ui.Menu2InputDelegate {

	function onSelect(item) {
        var id = item.getId();
        var app = App.getApp();
                    
     	if( id.equals("inhale")) {
     		Ui.pushView(new NumberPicker(app.inhaleTimeSet, 9999, 1), new InhalePickerDelegate(), Ui.SLIDE_IMMEDIATE);
        }
        else if( id.equals("exhale"))  {
			Ui.pushView(new NumberPicker(app.exhaleTimeSet, 9999, 1), new ExhalePickerDelegate(), Ui.SLIDE_IMMEDIATE);       	
        }
        else if( id.equals("exhale"))  {
			Ui.pushView(new NumberPicker(app.relaxTimeSet, 9999, 1), new RelaxPickerDelegate(), Ui.SLIDE_IMMEDIATE);       	
        }
        
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
}

class InhalePickerDelegate extends Ui.PickerDelegate {

    function initialize() { PickerDelegate.initialize(); }

    function onCancel() { Ui.popView(WatchUi.SLIDE_IMMEDIATE); }

    function onAccept(values) {
		var app = App.getApp();
		app.inhaleTimeSet = values[1].toNumber() + values[0].toNumber() * 100;
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class ExhalePickerDelegate extends Ui.PickerDelegate {

    function initialize() { PickerDelegate.initialize(); }

    function onCancel() { Ui.popView(WatchUi.SLIDE_IMMEDIATE); }

    function onAccept(values) {
		var app = App.getApp();
		app.exhaleTimeSet = values[1].toNumber() + values[0].toNumber() * 100;
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class RelaxPickerDelegate extends Ui.PickerDelegate {

    function initialize() { PickerDelegate.initialize(); }

    function onCancel() { Ui.popView(WatchUi.SLIDE_IMMEDIATE); }

    function onAccept(values) {
		var app = App.getApp();
		app.app.relaxTimeSet = values[1].toNumber() + values[0].toNumber() * 100;
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}