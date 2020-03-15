using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ColourListMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	hidden var mFunc;
	
	function initialize(func) { mFunc = func; Menu2InputDelegate.initialize(); }
	        
   	function onSelect(item) {
        var id = item.getId();
        // id is dictionary entry
        var value = $.mColourNumbersString.get(id);
        
        if (value < 0 || value >= $.mColourNumbersString.size()) {
        	// opps
        	var mErr = new myException( "ColourListMenuDelegate: colour out of range");
        } else {
        	Sys.println("ColourListMenuDelegate: colour picked = " + value);
        	mFunc.invoke( value);   
        	Ui.popView(WatchUi.SLIDE_DOWN);     
        }
    }
}
