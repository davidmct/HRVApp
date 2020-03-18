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
     		Ui.pushView(new NumberPicker(app.timerTimeSet, 5959, 1), new SecondsPickerDelegate(self.method(:setTimerTime)), Ui.SLIDE_IMMEDIATE);
       	}
    }
    function setTimerTime(value) { app.timerTimeSet = value;}
}