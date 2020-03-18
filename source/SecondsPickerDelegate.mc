using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

// modify to use mm:ss as display looks nicer
class SecondsPickerDelegate extends Ui.PickerDelegate {
	hidden var mFunc;
	
    function initialize(func) { mFunc = func; PickerDelegate.initialize();  }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		// need to combine two factories
		// seconds in [2] then minutes in [0]
		var mNum = values[2].toNumber() + values[0].toNumber() * 100 * 60;
		mFunc.invoke( mNum);
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}