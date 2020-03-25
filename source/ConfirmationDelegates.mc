using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class SaveDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES) {
            App.getApp().mTestControl.saveTest();
        }
        else {
        	App.getApp().mTestControl.discardTest();
        }
    }
    
    function initialize() { ConfirmationDelegate.initialize();  }	
}

class SettingsDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES) {
        	// push original settings in to Properties
            App.getApp().mStorage.resetSettings();
        }
    }
    function initialize() { ConfirmationDelegate.initialize();}	
}

class ResultsDelegate extends Ui.ConfirmationDelegate {

    function onResponse(value) {
        if(value == Ui.CONFIRM_YES ) {
            App.getApp().mStorage.resetResults();
        }
    }
    function initialize() { ConfirmationDelegate.initialize(); }	    
}