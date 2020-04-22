using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class ChoiceMenu2Delegate extends Ui.Menu2InputDelegate {

	hidden var mFunc;
	
	function onSelect(item) {
        var id = item.getId();
                    
     	if( id.equals("optOne")) {
     		mFunc.invoke(1);
     		Ui.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        else if( id.equals("optTwo"))  {
			mFunc.invoke(2); 
			Ui.popView(WatchUi.SLIDE_IMMEDIATE);      	
        }
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }  
    
    function initialize(func) { mFunc = func; Menu2InputDelegate.initialize(); }
}
