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
		var mId = item.getId();
		
		if( mId == :Manual) {
            $._mApp.testTypeSet = TYPE_MANUAL;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Timer)).setSelected(false);           
        }
        else if( mId == :Timer)  {
            $._mApp.testTypeSet = TYPE_TIMER;
            item.setSelected(true);
            mSrcMenu.getItem(mSrcMenu.findItemById(:Manual)).setSelected(false);   
        }
        
        // this should turn item blue...
        Sys.println("calling request update in TestTypeMenuDelegate");       
        requestUpdate();
    }
    
}