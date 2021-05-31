using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.System as Sys;

class TimerMenuDelegate extends Ui.Menu2InputDelegate {
		
    function initialize() { Menu2InputDelegate.initialize(); }
    
    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("d")) {    
     		// Picker set to initial value and max
     		//Sys.println("TimerMenuDelegate: timerTimeSet value : " + $.timerTimeSet);
            var upLim = (MAX_TIME-1) * 100 + 59; // only allow up to max time minus one second
     		Ui.pushView(new NumberPicker($.timerTimeSet, upLim, 1), new SecondsPickerDelegate(self.method(:setTimerTime)), Ui.SLIDE_IMMEDIATE);
       	}
    }
    function setTimerTime(value) { $.timerTimeSet = value;}
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }   
}