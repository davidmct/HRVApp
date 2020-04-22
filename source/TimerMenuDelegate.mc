using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.System as Sys;

class TimerMenuDelegate extends Ui.Menu2InputDelegate {
		
    function initialize() { Menu2InputDelegate.initialize(); }
    
    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("duration")) {    
     		// Picker set to initial value and max
     		//Sys.println("TimerMenuDelegate: timerTimeSet value : " + $._mApp.timerTimeSet);
     		Ui.pushView(new NumberPicker($._mApp.timerTimeSet, 5959, 1), new SecondsPickerDelegate(self.method(:setTimerTime)), Ui.SLIDE_IMMEDIATE);
       	}
    }
    function setTimerTime(value) { $._mApp.timerTimeSet = value;}
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }   
}