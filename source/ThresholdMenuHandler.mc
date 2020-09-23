using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ThresholdListMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var mFunc;
	hidden var mkeySet; // 0 = upper, 1 = lower
	
	function initialize(func, keySet) { 
		mFunc = func; 
		mkeySet = keySet;
		Menu2InputDelegate.initialize(); 
	}
	        
   	function onSelect(item) {
        var id = item.getId();
        // id is dictionary entry
        var value;
        if (mkeySet == 0) {
        	value = $.mLongThresholdMap.get(id);
        } else {
        	value = $.mShortThresholdMap.get(id);
        }	
        
        mFunc.invoke( value);   
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);     
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }  
}

class ThresholdMenuDelegate extends Ui.Menu2InputDelegate {
     
	function initialize() { Menu2InputDelegate.initialize(); }  
	
	function AddThresholdItems( menu) {
		// get labels for thresholds ie key 
		// as both thresholds have the same name then can use just one for labels
        var mKeys = $.mLongThresholdMap.keys();
        var i;
        for (i = 0; i < $.mLongThresholdMap.size() ; i++) {
        	var mColName = mKeys[i].toString();
        	Sys.println("Add threshold menu item "+mColName+" index "+i);
        	menu.addItem(new Ui.MenuItem(mColName, null, mColName, null));
    	}
	}
	
   	function onSelect(item) {
        var id = item.getId();
        
        Sys.println("Threshold onselect id "+id);
                  
     	if( id.equals("upper"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Upper")});
            AddThresholdItems( menu);
	        Ui.pushView(menu, new ThresholdListMenuDelegate(self.method(:setUpper), 0), Ui.SLIDE_IMMEDIATE );
        } else if( id.equals("lower"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Lower")});
            AddThresholdItems( menu);
	        Ui.pushView(menu, new ThresholdListMenuDelegate(self.method(:setLower), 1), Ui.SLIDE_IMMEDIATE );         	
        }
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
	
    function setUpper(value) { $._mApp.vUpperThresholdSet = value; Sys.println("Upper threshold set to "+value); }
    function setLower(value) { $._mApp.vLowerThresholdSet = value; Sys.println("Lower threshold set to "+value);}
    
}



