using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.System as Sys;

class TimerMenuDelegate extends Ui.Menu2InputDelegate {

	var app = App.getApp();
		
    function initialize() { Menu2InputDelegate.initialize(); }
    
    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("duration")) {    
     		// Picker set to initial value and max
     		Ui.pushView(new NumberPicker(app.timerTimeSet, 9999, 1), new DurationPickerDelegate(), Ui.SLIDE_IMMEDIATE);
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
		// return just a number??
		//app.timerTimeSet = new Time.Duration(values.toNumber());
		var mNum;
		mNum = values[1].toNumber() + values[0].toNumber() * 100;
		Sys.println(" timerTimeSet Duration: " + values + " to "+mNum);
		app.timerTimeSet = mNum;
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

}