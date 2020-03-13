using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class SaveDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES) {
            App.getApp().saveTest();
        }
        else {
        	App.getApp().discardTest();
        }
    }
    function initialize() { ConfirmationDelegate.initialize();  }	
}

class SettingsDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES) {
            App.getApp().resetSettings();
        }
    }
    function initialize() { ConfirmationDelegate.initialize();}	
}

class ResultsDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES ) {
            App.getApp().resetResults();
        }
    }
    function initialize() { ConfirmationDelegate.initialize(); }	    
}