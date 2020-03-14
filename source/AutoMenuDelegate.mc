using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class AutoMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	
   	function onSelect(item) {
        var id = item.getId();
        
        Sys.println("app.autoTimeSet = " + app.autoTimeSet);
        Sys.println("app.mMaxAutoTimeSet = " + app.mMaxAutoTimeSet);
        Sys.println("app.autoStartSet = " + app.autoStartSet);
                    
     	if( id.equals("duration")) {
     		// Picker set to initial value and max
     		Ui.pushView(new NumberPicker(app.autoTimeSet, 9999, 1), new AutoPickerDelegate(:setAutoTime), Ui.SLIDE_IMMEDIATE);
        }
        else if( id.equals("schedule"))  {
			// was Ui.NUMBER_PICKER_TIME_OF_DAY which is seconds since midnight
			Ui.pushView(new NumberPicker(app.autoStartSet, 9999, 1), new AutoPickerDelegate(:setStartTime), Ui.SLIDE_IMMEDIATE);       	
        }
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
    
    function setAutoTime(value) { app.autoTimeSet = value;}
    function setStartTime(value) { app.autoStartSet = value;}   
}

class AutoPickerDelegate extends Ui.PickerDelegate {
	hidden var mFunc;
	
    function initialize(func) { mFunc = func; PickerDelegate.initialize();  }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		// need to combine two factories
		var mNum;
		mNum = values[1].toNumber() + values[0].toNumber() * 100;
		mFunc.invoke( mNum);
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
