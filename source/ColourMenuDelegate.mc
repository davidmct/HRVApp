using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ColourMenuDelegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
     
	function initialize() { Menu2InputDelegate.initialize(); }  
	
   	function onSelect(item) {
        var id = item.getId();
                  
     	if( id.equals("background")) {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Background")});
	        menu.addItem(new Ui.MenuItem("White", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("Black", null, "optTwo", null));
	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setBackground)), Ui.SLIDE_IMMEDIATE );
        }
        else if( id.equals("labels"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Label Colour")});
            // get labels for colours ie key 
            var mKeys = $.mColourNumbersString.keys();
            var i;
            for (i = 0; i < mColourNumbersString.size() ; i++) {
            	var mColName = mKeys[i].toString();
            	var mColValue = $.mColourNumbersString.get(mColName);
            	if (mColValue != TRANSPARENT) {
            		Sys.println("Label menu item colour: " + mColName);
	        		menu.addItem(new Ui.MenuItem(mColName, null, mColName, null));
	        	}
        	}
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setLabel)), Ui.SLIDE_IMMEDIATE );
        } else if( id.equals("text"))  {
             var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Text Colour")});
            // get labels for colour keys
            var mKeys = $.mColourNumbersString.keys();
            var i;
            for (i = 0; i < mColourNumbersString.size() ; i++) {
            	var mColName = mKeys[i].toString();
            	var mColValue = $.mColourNumbersString.get(mColName);
            	if (mColValue != TRANSPARENT) {
            	    Sys.println("Label menu item colour: " + mColName);
	        		menu.addItem(new Ui.MenuItem(mColName, null, mColName, null));
	        	}
        	}
	        Ui.pushView(menu, new ColourListMenuDelegate(self.method(:setText)), Ui.SLIDE_IMMEDIATE );         	
        }
    }

    function setBackground(value) {
    	if(value == "optOne") {
    		app.bgColSet = WHITE;
    		if(WHITE == app.txtColSet) {
	    		app.txtColSet = BLACK;
	    	}
    	}
    	else {
    		app.bgColSet = BLACK;
    		if(BLACK == app.txtColSet) {
	    		app.txtColSet = WHITE;
	    	}
    	}
    }

    function setLabel(value) { app.lblColSet = value;  }
    function setText(value) { app.txtColSet = value; }
}



