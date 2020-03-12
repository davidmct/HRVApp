using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Graphics;

class MainMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("test")) {
     		//build test type menu
     		//var app = App.getApp();
     		//var mTestSelected = app.testTypeSet;
     		//var toggleMenu = new Ui.Menu2({:title=>"Test"});
            //toggleMenu.addItem(new Ui.ToggleMenuItem("TimerT", {:enabled=>"Timer Toggle: on", :disabled=>"Timer Toggle: off"}, "timer", (TYPE_TIMER == mTestSelected ), {:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
            //toggleMenu.addItem(new Ui.ToggleMenuItem("ManualT", {:enabled=>"Manual Toggle: on", :disabled=>"Manual Toggle: off"}, "manual", (TYPE_MANUAL== mTestSelected), {:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
            //toggleMenu.addItem(new Ui.ToggleMenuItem("AutoT", {:enabled=>"Auto Toggle: on", :disabled=>"Auto Toggle: off"}, "Auto", (TYPE_AUTO== mTestSelected), {:alignment=>WatchUi.MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT}));
            //WatchUi.pushView(toggleMenu, new TestTypeMenuDelegate(), Ui.SLIDE_LEFT );
  

  			//var obj;
  			//obj = Rez.Drawables.MenuForeground_id;
  			var app = App.getApp();
  			var mTestSelected = app.testTypeSet;		
		    var customMenu = new BasicCustomMenu(35,Graphics.COLOR_WHITE,
		    	{
		        :focusItemHeight=>45,
		        :foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Test"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Timer, "Timer", (TYPE_TIMER == mTestSelected )) );
		    customMenu.addItem(new CustomItem(:Manual, "Manual", (TYPE_MANUAL== mTestSelected)) );
		    customMenu.addItem(new CustomItem(:Auto, "Auto", (TYPE_AUTO== mTestSelected)) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_LEFT );    		
        }
        else if( id.equals("settings") ) {
        	// create long sub-menus

            Ui.pushView(new Rez.Menus.SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if( id.equals("about"))  {
        	// build simple menu with version from system file
        	// Generate a new Menu for mainmenu
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("About")});
	        // get app version
	        var mAppVer = Ui.loadResource(Rez.Strings.Version);
	        menu.addItem(new Ui.MenuItem(mAppVer, null, "test", null));
	        Ui.pushView(menu, new EmptyMenuDelegate(), Ui.SLIDE_LEFT );
        }
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
    
}