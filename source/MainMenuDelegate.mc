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
		        //:foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Test"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Manual, "Manual", (TYPE_MANUAL== mTestSelected)) );
		    customMenu.addItem(new CustomItem(:Timer, "Timer", (TYPE_TIMER== mTestSelected)) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_IMMEDIATE );    		
        }
     	else if( id.equals("source")) {
			// optical/registered strap or unknown/disabled
  			var mExtStrap = $._mApp.mSensorTypeExt;		
		    var customMenu = new BasicCustomMenu(35,Graphics.COLOR_WHITE,
		    	{
		        :focusItemHeight=>45,
		        //:foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Source"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Internal, "Internal", mExtStrap == SENSOR_INTERNAL) );
		    customMenu.addItem(new CustomItem(:Search, "Search", mExtStrap == SENSOR_SEARCH) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_IMMEDIATE );    		
        }
        else if( id.equals("fitOutput")) {
			// want to set FIT file creation
  			var mFitWrite = $._mApp.mFitWriteEnabled;		
		    var customMenu = new BasicCustomMenu(35,Graphics.COLOR_WHITE,
		    	{
		        :focusItemHeight=>45,
		        //:foreground=>new Rez.Drawables.MenuForeground_id(),
		        :title=>new DrawableMenuTitle("Fit write"),
		        :footer=>new DrawableMenuFooter()
		    	});
		    customMenu.addItem(new CustomItem(:Write, "Write", mFitWrite == true) );
		    customMenu.addItem(new CustomItem(:NoWrite, "No Write", mFitWrite == false) );				
     		Ui.pushView(customMenu, new TestTypeMenuDelegate(customMenu), Ui.SLIDE_IMMEDIATE );    		
        } 
        else if( id.equals("historySelection")) { 
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("History")});
	        menu.addItem(new Ui.MenuItem("History Lbl 1", null, "historyLbl1", null));
	        menu.addItem(new Ui.MenuItem("History Lbl 2", null, "historyLbl2", null));
	        menu.addItem(new Ui.MenuItem("History Lbl 3", null, "historyLbl3", null));
	        Ui.pushView(menu, new HistoryMainMenuDelegate(), Ui.SLIDE_IMMEDIATE );               	    
        }
        else if ( id.equals("load") ) {
        	// you can't do this whilst testing! Otherwise screws data
        	if ( $._mApp.mTestControl.mTestState >= TS_TESTING) {
        		$._mApp.mTestControl.alert(TONE_ERROR);
        		return;
        	} else {
	        	Sys.println("MainMenuDelegate: loading old intervals + stats and switching to Poincare");
	        	var success = $._mApp.mStorage.loadIntervalsFromStore();
	        	success = success && $._mApp.mStorage.loadStatsFromStore();
	        	if (success) {	        	
			  		if( $._mApp.viewNum != POINCARE_VIEW) {
						Ui.switchToView($._mApp.getView(POINCARE_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
					}
				} else { // failed to load data
	        		$._mApp.mTestControl.alert(TONE_ERROR);
	        		return;				
				}				
			}          
        }        
        else if ( id.equals("timer")) {
     		var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Timer")});
	        menu.addItem(new Ui.MenuItem("Duration", null, "duration", null));
	        Ui.pushView(menu, new TimerMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
        else if ( id.equals("threshold"))   {
 			var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Threshold")});
	        menu.addItem(new Ui.MenuItem("Upper", null, "upper", null));     
	        menu.addItem(new Ui.MenuItem("Lower", null, "lower", null));   	          
 	        Ui.pushView(menu, new ThresholdMenuDelegate(), Ui.SLIDE_IMMEDIATE );       
        }
        else if ( id.equals("colour"))   {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Colour")});
	        menu.addItem(new Ui.MenuItem("Background", null, "background", null));
	        menu.addItem(new Ui.MenuItem("Text", null, "text", null));
	        menu.addItem(new Ui.MenuItem("Labels", null, "labels", null));	 
	        //0.4.3
	        menu.addItem(new Ui.MenuItem("History 1", null, "history1", null));
	       	menu.addItem(new Ui.MenuItem("History 2", null, "history2", null));
	        menu.addItem(new Ui.MenuItem("History 3", null, "history3", null));	               
	        Ui.pushView(menu, new ColourMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
        else if ( id.equals("sound"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Sound")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSound)), Ui.SLIDE_IMMEDIATE );     
        }
        else if ( id.equals("vibration"))  {
            var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Vibration")});
	        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
	        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setVibe)), Ui.SLIDE_IMMEDIATE );  
        }
        else if (id.equals("reset")) {
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Reset")});
	        menu.addItem(new Ui.MenuItem("Results", null, "results", null));
	        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
	        Ui.pushView(menu, new ResetMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }  
        else if( id.equals("about"))  {
        	// build simple menu with version from system file
        	// Generate a new Menu for mainmenu
	        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("About")});
	       	var mAppVer = $._mApp.versionSet;
	        var mID = $._mApp.mDeviceID;
	        if (mID == null) {mID = "No device ID";}
	        //Sys.println("Device indentifier = "+mID);
	        menu.addItem(new Ui.MenuItem(mAppVer, null, "test", null));
	        menu.addItem(new Ui.MenuItem(mID, null, "deviceID", null));
	        Ui.pushView(menu, new EmptyMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        }
    }
    
    function setSound(value) {
		if (value == 1) { $._mApp.soundSet = true;} else { $._mApp.soundSet = false;}
    }

    function setVibe(value) {
		if (value == 1) { $._mApp.vibeSet = true; } else { $._mApp.vibeSet = false;}
    } 
    
    function onBack() {
    	//0.4.3 - should save changes to any properties
    	$._mApp.mStorage.saveProperties();
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
        Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        //0.4.3 - should save changes to any properties
    	$._mApp.mStorage.saveProperties();
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
        Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
    
}