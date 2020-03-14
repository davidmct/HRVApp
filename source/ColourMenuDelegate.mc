using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class ColourMenuDelegate extends Ui.Menu2InputDelegate {

   function onSelect(item) {
        var id = item.getId();
        var app = App.getApp();
                  
     	if( id.equals("background")) {
     		// Picker set to initial value and max
     		Ui.pushView(new Rez.Menus.BackgroundMenu(), new ChoiceMenuDelegate(method(:setBackground)), Ui.SLIDE_IMMEDIATE);
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

    	var app = App.getApp();

    	if(value) {

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

    function setLabel(value) {

    	var app = App.getApp();
		app.lblColSet = value;
    }

    function setText(value) {

    	var app = App.getApp();
		app.txtColSet = value;
    }
}