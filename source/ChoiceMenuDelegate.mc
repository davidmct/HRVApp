using Toybox.Application as App;
using Toybox.WatchUi as Ui;


class ChoiceMenu2Delegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	hidden var mFunc;
	
	function onSelect(item) {
        var id = item.getId();
                    
     	if( id.equals("optOne")) {
     		mFunc.invoke("optOne");
     		Ui.popView(WatchUi.SLIDE_DOWN);
        }
        else if( id.equals("optTwo"))  {
			mFunc.invoke("optTwo"); 
			Ui.popView(WatchUi.SLIDE_DOWN);      	
        }
    }
    
    function initialize(func) { mFunc = func; Menu2InputDelegate.initialize(); }
}
