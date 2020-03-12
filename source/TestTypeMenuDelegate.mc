using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class TestTypeMenuDelegate extends Ui.Menu2InputDelegate {
	// menu we are working in
	var mSrcMenu;
    function initialize(srcMenu) {
    	mSrcMenu = srcMenu; 
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
		var mId = item.getId();
		
		if( mId == :Timer ) {
            app.testTypeSet = TYPE_TIMER;
            Sys.println("Timer selected");
            item.setSelected(true);
            mSrcMenu.getItem(:Manual).setSelected(false);
        }
        else if( mId == :Manual) {
            app.testTypeSet = TYPE_MANUAL;
            item.setSelected(true);
        }
        else if( mId == :Auto)  {
            app.testTypeSet = TYPE_AUTO;
            item.setSelected(true);
        }
        
        // this should turn item blue...
        Sys.println("calling request update in TestTYpeMenuDelegate");       
        requestUpdate();
        //item.forceDraw();
        
        if(mId != :Auto && app.isWaiting) {
        	app.endTest();
        }

    }
    
}