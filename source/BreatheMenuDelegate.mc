using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class BreatheMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {

        if(item == :MiInhale) {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().inhaleTimeSet)),
            	new InhaleTimeDelegate(), Ui.SLIDE_LEFT);
        }
        else if(item == :MiExhale) {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().exhaleTimeSet)),
            	new ExhaleTimeDelegate(), Ui.SLIDE_LEFT);
        }
        else if(item == :MiRelax) {

            Ui.pushView(new Ui.NumberPicker(Ui.NUMBER_PICKER_TIME,
            	new Time.Duration(App.getApp().relaxTimeSet)),
            	new RelaxTimeDelegate(), Ui.SLIDE_LEFT);
        }
    }
    function initialize() {
    	MenuInputDelegate.initialize();
    }
}

class InhaleTimeDelegate extends Ui.NumberPickerDelegate {

    function onNumberPicked(duration) {

		var app = App.getApp();
		app.inhaleTimeSet = duration.value().toNumber();
	}
	function initialize() {
		NumberPickerDelegate.initialize();
	}	
}

class ExhaleTimeDelegate extends Ui.NumberPickerDelegate {

    function onNumberPicked(duration) {

		var app = App.getApp();
		app.exhaleTimeSet = duration.value().toNumber();
	}
	function initialize() {
		NumberPickerDelegate.initialize();
	}	
}

class RelaxTimeDelegate extends Ui.NumberPickerDelegate {

    function onNumberPicked(duration) {

		var app = App.getApp();
		app.relaxTimeSet = duration.value().toNumber();
	}
	function initialize() {
		NumberPickerDelegate.initialize();
	}	
}