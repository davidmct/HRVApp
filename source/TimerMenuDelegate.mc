using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class TimerMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {

        if(item == :MiDuration) {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().timerTimeSet)),
            	new TimerTimeDelegate(), Ui.SLIDE_LEFT);
        }
    }
    function initialize() {
    	MenuInputDelegate.initialize();
    }
}

class TimerTimeDelegate extends Ui.NumberPickerDelegate {

    function onNumberPicked(duration) {

		var app = App.getApp();
		app.timerTimeSet = duration.value().toNumber();
	}
	function initialize() {
    	NumberPickerDelegate.initialize();
    }
}