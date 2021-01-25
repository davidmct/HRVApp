using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;


class ThresholdMenuDelegate extends Ui.Menu2InputDelegate {
     
	function initialize() { Menu2InputDelegate.initialize(); }  
	
	//(:oldThreshold)
	(:discard)
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
	
    //(:newThreshold)
    (:discard)
	function AddThresholdItems( menu) {
		// get labels for thresholds ie key 
		// as both thresholds have the same name then can use just one for labels
        var mThresholdStrings = Ui.loadResource(Rez.JsonData.jsonThresholdStrings);
        var i;
        for (i = 0; i < mThresholdStrings.size() ; i++) {
        	var mColName = mThresholdStrings[i];
        	Sys.println("Add threshold menu item "+mColName+" index "+i);
        	menu.addItem(new Ui.MenuItem(mColName, null, i.toString(), null));
    	}
	}    
    
    
   	function onSelect(item) {
        var id = item.getId();
        
        Sys.println("Threshold onselect id "+id);
                  
     	if( id.equals("u"))  {
            //var menu = new Ui.Menu2({:title=>"Upper"});
            //AddThresholdItems( menu);
	        //Ui.pushView(menu, new ThresholdListMenuDelegate(self.method(:setUpper), 0), Ui.SLIDE_IMMEDIATE );
	        Sys.println("Threshold upper before = "+$.vUpperThresholdSet);
	        Ui.pushView(new NumberPicker2Digit(10, $.vUpperThresholdSet*100, 40, 1), new ThresholdPickerDelegate(self.method(:setUpper)), Ui.SLIDE_IMMEDIATE);
        } else if( id.equals("l"))  {
            //var menu = new Ui.Menu2({:title=>"Lower"});
            //AddThresholdItems( menu);
	        //Ui.pushView(menu, new ThresholdListMenuDelegate(self.method(:setLower), 1), Ui.SLIDE_IMMEDIATE ); 
	        Sys.println("Threshold lower before = "+$.vLowerThresholdSet);
	        Ui.pushView(new NumberPicker2Digit(10, $.vLowerThresholdSet*100, 40, 1), new ThresholdPickerDelegate(self.method(:setLower)), Ui.SLIDE_IMMEDIATE);        	
        }
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
	
	// delegate scales to % already
    function setUpper(value) { $.vUpperThresholdSet = value; Sys.println("Upper threshold set to "+$.vUpperThresholdSet); }
    function setLower(value) { $.vLowerThresholdSet = value; Sys.println("Lower threshold set to "+$.vLowerThresholdSet); }
    
}

class ThresholdPickerDelegate extends Ui.PickerDelegate {
	hidden var mFunc;
	
    function initialize(func) { mFunc = func; PickerDelegate.initialize();  }

    function onCancel() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onAccept(values) {
		mFunc.invoke( values[0].toFloat()/100 );
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:discard)
class ThresholdListMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var mFunc;
	hidden var mkeySet; // 0 = upper, 1 = lower
	
	function initialize(func, keySet) { 
		mFunc = func; 
		mkeySet = keySet;
		Menu2InputDelegate.initialize(); 
	}
	
	(:oldThreshold)       
   	function onSelect(item) {
        var id = item.getId();
        // id is dictionary entry text value
        var value;
        if (mkeySet == 0) {
        	value = $.mLongThresholdMap.get(id); // use key to look up actual number
        } else {
        	value = $.mShortThresholdMap.get(id);
        }	
        
        mFunc.invoke( value);   
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);     
    }
    
    (:newThreshold)
    function onSelect(item) {
        var id = item.getId();
		var index = id.toNumber();
        // id is string representing a number which is entry needed
        var value;
        if (mkeySet == 0) {
            var mLongThresholdMap = Ui.loadResource(Rez.JsonData.jsonLongThresholdMap);
        	value = mLongThresholdMap[index]; // use key to look up actual number
        } else {
            var mShortThresholdMap = Ui.loadResource(Rez.JsonData.jsonShortThresholdMap);
        	value = mShortThresholdMap[index];
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
