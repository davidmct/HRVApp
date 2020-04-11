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

  			var mTestSelected = $._mApp.testTypeSet;		
		    var customMenu = new BasicCustomMenu(35,Graphics.COLOR_WHITE,
		    	{
		        :focusItemHeight=>45,
		        :foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Test"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Manual, "Manual", (TYPE_MANUAL== mTestSelected)) );
		    customMenu.addItem(new CustomItem(:Timer, "Timer", (TYPE_TIMER== mTestSelected)) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_LEFT );    		
        }
     	else if( id.equals("source")) {
			// optical/registered strap or unknown/disabled
  			var mExtStrap = $._mApp.mSensorTypeExt;		
		    var customMenu = new BasicCustomMenu(35,Graphics.COLOR_WHITE,
		    	{
		        :focusItemHeight=>45,
		        :foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Source"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Internal, "Internal", mExtStrap == SENSOR_INTERNAL) );
		    customMenu.addItem(new CustomItem(:Search, "Search", mExtStrap == SENSOR_SEARCH) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_LEFT );    		
        }
        else if ( id.equals("load") ) {
        	// you can't do this whilst testing! Otherwise screws data
        	if ( $._mApp.mTestControl.mTestState >= TS_TESTING) {
        		$._mApp.mTestControl.alert(TONE_ERROR);
        		return;
        	} else {
	        	Sys.println("MainMenuDelegate: loading old intervals and switching to Poincare");
	        	var success = $._mApp.mStorage.loadIntervalsFromStore();
	        	if (success) {	        	
			  		if( $._mApp.viewNum != POINCARE_VIEW) {
						Ui.switchToView($._mApp.getView(POINCARE_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
					}
				} else { // failed to load data
	        		$._mApp.mTestControl.alert(TONE_ERROR);
	        		return;				
				}				
			}          
        }        
        else if( id.equals("settings") ) {
        	// create long sub-menus
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Settings")});
	        menu.addItem(new Ui.MenuItem("Timer", null, "timer", null));
	        menu.addItem(new Ui.MenuItem("Colours", null, "colour", null));
	        menu.addItem(new Ui.MenuItem("Fit Output", null, "fitOutput", null));
	        menu.addItem(new Ui.MenuItem("Sound", null, "sound", null));
	        menu.addItem(new Ui.MenuItem("Vibration", null, "vibration", null));
	        menu.addItem(new Ui.MenuItem("Reset", null, "reset", null));
	        Ui.pushView(menu, new SettingsMenuDelegate(), Ui.SLIDE_LEFT );
        }
        else if( id.equals("about"))  {
        	// build simple menu with version from system file
        	// Generate a new Menu for mainmenu
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("About")});
	        // get app version
	        var mAppVer = $._mApp.versionSet;
	        var mySettings = Sys.getDeviceSettings();
	        var mID = mySettings.uniqueIdentifier;
	        if (mID == null) {mID = "";}
	        Sys.println("Device indentifier = "+mID);
	        menu.addItem(new Ui.MenuItem(mAppVer, null, "test", null));
	        menu.addItem(new Ui.MenuItem(mID, null, "deviceID", null));
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