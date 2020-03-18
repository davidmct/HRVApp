using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class AutoMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	
   	function onSelect(item) {
        var id = item.getId();
                    
     	if( id.equals("duration")) {
     		// Picker set to initial value and max
     		Ui.pushView(new NumberPicker(app.autoTimeSet, 5959, 1), new SecondsPickerDelegate(self.method(:setAutoTime)), Ui.SLIDE_IMMEDIATE);
        }
        else if( id.equals("schedule"))  {
			// was Ui.NUMBER_PICKER_TIME_OF_DAY which is seconds since midnight
			Ui.pushView(new NumberPicker(app.autoStartSet, 5959, 1), new SecondsPickerDelegate(self.method(:setStartTime)), Ui.SLIDE_IMMEDIATE);       	
        }
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
    
    function setAutoTime(value) { app.autoTimeSet = value;}
    function setStartTime(value) { app.autoStartSet = value;}   
}


