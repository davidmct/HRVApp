using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class TestTypeMenuDelegate extends Ui.Menu2InputDelegate {
	
    function initialize() { 
    	Menu2InputDelegate.initialize();
    }

    function onBack() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }   
 
    function onSelect(item) {
		var app = App.getApp();
		
		if( item.mLabel == "Timer")  {
            app.testTypeSet = TYPE_TIMER;
        }
        else if( item.mLabel == "Manual") {
            app.testTypeSet = TYPE_MANUAL;
        }
        else if( item.mLabel == "Auto")  {
            app.testTypeSet = TYPE_AUTO;
        }

        if(item != :MiAuto && app.isWaiting) {
        	app.endTest();
        }
    }
    
}