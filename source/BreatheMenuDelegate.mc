using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class BreatheMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	
	function onSelect(item) {
        var id = item.getId();
                    
     	if( id.equals("inhale")) {
     		Ui.pushView(new NumberPicker(app.inhaleTimeSet, 9999, 1), new BreathePickerDelegate(:setIhaleTimer), Ui.SLIDE_IMMEDIATE);
        }
        else if( id.equals("exhale"))  {
			Ui.pushView(new NumberPicker(app.exhaleTimeSet, 9999, 1), new BreathePickerDelegate(:setExhaleTimer), Ui.SLIDE_IMMEDIATE);       	
        }
        else if( id.equals("exhale"))  {
			Ui.pushView(new NumberPicker(app.relaxTimeSet, 9999, 1), new BreathePickerDelegate(:setRelaxTimer), Ui.SLIDE_IMMEDIATE);       	
        }
        
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }
    
    function setInhaleTimer(value) { app.inhaleTimeSet = value;}
    function setExhaleTimer(value) { app.exhaleTimeSet = value;}
    function setRelaxTimer(value) { app.relaxTimeSet = value;}

}

class BreathePickerDelegate extends Ui.PickerDelegate {
	hidden var mFunc;
    function initialize(func) { mFunc = func; PickerDelegate.initialize(); }

    function onCancel() { Ui.popView(WatchUi.SLIDE_IMMEDIATE); }

    function onAccept(values) {
		var mValue = values[1].toNumber() + values[0].toNumber() * 100;
		mFunc.invoke( mValue);
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}