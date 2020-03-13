using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class AutoMenuDelegate extends Ui.Menu2InputDelegate {

   function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("duration")) {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().autoTimeSet)),
            	new AutoTimeDelegate(), Ui.SLIDE_LEFT);
        }
        else if( id.equals("schedule"))  {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME_OF_DAY,
            	new Time.Duration(App.getApp().autoStartSet)),
            	new AutoStartDelegate(), Ui.SLIDE_LEFT);
        }
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
}

class AutoTimeDelegate extends Ui.NumberPickerDelegate {

	function onNumberPicked(duration) {

		var app = App.getApp();
		app.autoTimeSet = duration.value().toNumber();
	}
	function initialize() {
    	NumberPickerDelegate.initialize();
    }
}

class AutoStartDelegate extends Ui.NumberPickerDelegate {

	function onNumberPicked(duration) {

		var app = App.getApp();
		app.autoStartSet = duration.value().toNumber();
	}
	
	function initialize() {
    	NumberPickerDelegate.initialize();
    }
}