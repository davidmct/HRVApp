using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ColourMenuDelegate extends Ui.Menu2InputDelegate {

   function onSelect(item) {
        var id = item.getId();
        var app = App.getApp();
                  
     	if( id.equals("background")) {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Background")});
	        menu.addItem(new Ui.MenuItem("White", null, "white", null));
	        menu.addItem(new Ui.MenuItem("Black", null, "black", null));
	        Ui.pushView(menu, new ChoiceMenu2Delegate(method(:setBackground)), Ui.SLIDE_IMMEDIATE );
        }
        else if( id.equals("labels"))  {
			// was Ui.NUMBER_PICKER_TIME_OF_DAY which is seconds since midnight
			Ui.pushView(new Rez.Menus.ColorListMenu(), new ColorListMenuDelegate(method(:setLabel)), Ui.SLIDE_IMMEDIATE);       	
        } else if( id.equals("text"))  {
			// was Ui.NUMBER_PICKER_TIME_OF_DAY which is seconds since midnight
			Ui.pushView(new Rez.Menus.ColorListMenu(), new ColorListMenuDelegate(method(:setText)), Ui.SLIDE_IMMEDIATE);     	
        }
    }
    function initialize() {
    	Menu2InputDelegate.initialize();
    }

    function setBackground(value) {
    	if(value == true) {
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

class ChoiceMenu2Delegate extends Ui.Menu2InputDelegate {

	hidden var app = App.getApp();
	hidden var mFunc;
	
	function onSelect(item) {
        var id = item.getId();
                    
     	if( id.equals("white")) {
     		mFunc.invoke(true);
        }
        else if( id.equals("black"))  {
			mFunc.invoke(false);       	
        }
    }
    function initialize(func) { mFunc = func; Menu2InputDelegate.initialize(); }
}