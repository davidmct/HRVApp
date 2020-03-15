using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Lang;
using Toybox.System as Sys;

class SecondsPickerDelegate extends Ui.PickerDelegate {
	hidden var mFunc;
	
    function initialize(func) { mFunc = func; PickerDelegate.initialize();  }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		// need to combine two factories
		var mNum = values[1].toNumber() + values[0].toNumber() * 100;
		mFunc.invoke( mNum);
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}