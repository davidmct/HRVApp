using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class AutoMenuDelegate extends Ui.Menu2InputDelegate {

   function onSelect(item) {
        var id = item.getId();
        var app = App.getApp();
        
        Sys.println("app.autoTimeSet = " + app.autoTimeSet);
        Sys.println("app.mMaxAutoTimeSet = " + app.mMaxAutoTimeSet);
        Sys.println("app.autoStartSet = " + app.autoStartSet);
                    
     	if( id.equals("duration")) {
     		// Picker set to initial value and max
     		Ui.pushView(new NumberPicker(app.autoTimeSet, app.mMaxAutoTimeSet), new AutoDurationPickerDelegate(), Ui.SLIDE_IMMEDIATE);
        }
        else if( id.equals("schedule"))  {
			// was Ui.NUMBER_PICKER_TIME_OF_DAY which is seconds since midnight
			Ui.pushView(new NumberPicker(app.autoStartSet, app.mMaxAutoTimeSet), new AutoStartPickerDelegate(), Ui.SLIDE_IMMEDIATE);       	
        }
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
}

class AutoDurationPickerDelegate extends Ui.PickerDelegate {

    function initialize() {
        PickerDelegate.initialize();
    }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		var app = App.getApp();
		Sys.println(" AutoDuration: "+values);
		app.autoTimeSet = values[0].toNumber();

        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

}

class AutoStartPickerDelegate extends Ui.PickerDelegate {

	//function onNumberPicked(duration) {

		//var app = App.getApp();
		//app.autoStartSet = duration.value().toNumber();
   function initialize() {
        PickerDelegate.initialize();
    }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		var app = App.getApp();
		app.autoStartSet = values[0].toNumber();

        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

}