using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class TimerMenuDelegate extends Ui.Menu2InputDelegate {

	var app = App.getApp();
		
    function initialize() { Menu2InputDelegate.initialize(); }
    
    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("duration")) {    	
     		Ui.pushView(new NumberPicker(app.timerTimeSet), new DurationPickerDelegate(), Ui.SLIDE_IMMEDIATE);
    	}
    }
}

class DurationPickerDelegate extends Ui.PickerDelegate {

    function initialize() {
        PickerDelegate.initialize();
    }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		var app = App.getApp();
		app.timerTimeSet = values.duration.value().toNumber();

        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

}