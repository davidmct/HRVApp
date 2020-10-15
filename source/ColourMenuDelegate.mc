using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ColourListMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var mFunc;
	
	function initialize(func) { mFunc = func; Menu2InputDelegate.initialize(); }
	        
   	function onSelect(item) {
        var id = item.getId();
        // id is dictionary entry
        var ColStringDict = Ui.loadResource(Rez.JsonData.jsonColourDict);
        var value = ColStringDict.get(id);
        
        if (value < 0 || value >= ColStringDict.size()) {
        	// opps
        	var mErr = new myException( "ColourListMenuDelegate: colour out of range");
        } else {
        	//Sys.println("ColourListMenuDelegate: colour picked = " + value);
        	mFunc.invoke( value);   
        	Ui.popView(WatchUi.SLIDE_IMMEDIATE);     
        }
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }  
}

class ColourMenuDelegate extends Ui.Menu2InputDelegate {
     
	function initialize() { Menu2InputDelegate.initialize(); }  
	
	// 0.4.3 move code to function
	function AddColourItems( menu) {
		// get labels for colours ie key
		var ColStringDict = Ui.loadResource(Rez.JsonData.jsonColourDict); 
        var mKeys = ColStringDict.keys();
        var i;
        for (i = 0; i < ColStringDict.size() ; i++) {
        	var mColName = mKeys[i].toString();
        	var mColValue = ColStringDict.get(mColName);
        	if (mColValue != 14 ) { //TRANSPARENT) {
        	    //Sys.println("Label menu item colour: " + mColName);
        		menu.addItem(new Ui.MenuItem(mColName, null, mColName, null));
        	}
    	}
	}
	
   	function onSelect(item) {
        var id = item.getId();
                  
     	if( id.equals("b")) {
            var menu = new Ui.Menu2({:title=>"Background"});
	        menu.addItem(new Ui.MenuItem("White", null, "1", null));
	        menu.addItem(new Ui.MenuItem("Black", null, "2", null));
	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setBackground)), Ui.SLIDE_IMMEDIATE );
        }
        else if( id.equals("l"))  {
            var menu = new Ui.Menu2({:title=>"Label Colour"});
            AddColourItems( menu);
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setLabel)), Ui.SLIDE_IMMEDIATE );
        } else if( id.equals("t"))  {
            var menu = new Ui.Menu2({:title=>"Text Colour"});
            AddColourItems( menu);
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setText)), Ui.SLIDE_IMMEDIATE );         	
        } else if( id.equals("h1"))  {
            var menu = new Ui.Menu2({:title=>"Hist 1"});
            AddColourItems( menu);
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setHistory1)), Ui.SLIDE_IMMEDIATE );         	
        } else if( id.equals("h2"))  {
            var menu = new Ui.Menu2({:title=>"Hist 2"});
            AddColourItems( menu);
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setHistory2)), Ui.SLIDE_IMMEDIATE );         	
        } else if( id.equals("h3"))  {
            var menu = new Ui.Menu2({:title=>"Hist 3"});
            AddColourItems( menu);
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setHistory3)), Ui.SLIDE_IMMEDIATE );         	
        }
    }

    function setBackground(value) {
    	//Sys.println("setBackground called: "+value);
    	
    	if(value == 1) {
    		$._mApp.bgColSet = 0; //WHITE;
    		//Sys.println("WHITE background set "+WHITE);
    		if(0 == $._mApp.txtColSet) {
	    		$._mApp.txtColSet = 3; //BLACK;
	    	}
    	}
    	else {
    		$._mApp.bgColSet = 3; //BLACK;
    		//Sys.println("BLACK background set "+BLACK);
    		if(3 == $._mApp.txtColSet) { //BLACK
	    		$._mApp.txtColSet = 0; //WHITE;
	    	}
    	}   	
    	//Sys.println("Colours: back, text "+$._mApp.bgColSet+" "+$._mApp.txtColSet);
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }  

    function setLabel(value) { $._mApp.lblColSet = value;  }
    function setText(value) { $._mApp.txtColSet = value; }
    //0.4.3
    function setHistory1(value) { $._mApp.mHistoryLabel1 = value;}
    function setHistory2(value) { $._mApp.mHistoryLabel2 = value;}
    function setHistory3(value) { $._mApp.mHistoryLabel3 = value;}
    
}



