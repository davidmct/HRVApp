using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class HRVBehaviourDelegate extends Ui.BehaviorDelegate {
    
    function initialize() {
		BehaviorDelegate.initialize();
	}
      
    function onSelect() {
    	// same as enter, tap or click
    	return onEnter();  
    }
    
    function onBack() {
    	// same as escape
    	return onEscape();
    }
 
    function onDone() {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }  
	
	function onNextPage() {
		// down or swipe UP
		Ui.switchToView($._mApp.plusView(), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
    }

    function onPreviousPage() {
		// Up or swipe down
		Ui.switchToView($._mApp.subView(), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
    }

    // handle other key presses
    function onKey(event) {

    	if(Ui.KEY_ENTER == event.getKey()) {
			// menu key
			onEnter();
		}
		else if(Ui.KEY_ESC == event.getKey()) {
			// same as back
			onEscape();
      	}
      	else if(Ui.KEY_MENU == event.getKey()) {
			onMenu();
      	}
      	else if(Ui.KEY_POWER == event.getKey()) {
			onPower();
		}
		return true;
	}

    function onEnter() {
		if($._mApp.viewNum != TEST_VIEW) {
			//Sys.println("HRVBehaviour onEnter() - switch to test view");
			Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
			return true;
		}
		else {
			// in test view so means stop or start test
			var res = $._mApp.mTestControl.StateMachine(:enterPressed);
			// true if enough samples to save but we have to be in testing state
			//if ($._mApp.mTestControl.mTestState == TS_TESTING) {
				if (res == true) {
					var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Save result")});
			        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
			        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
		 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_IMMEDIATE );  
					return true;
				}// else {
					// we haven't enough samples to save so kill FIT
					//Sys.println("discardTest() called");
	        		//$._mApp.mTestControl.discardTest();			
				//}
			//}
		}
				
 		//Sys.println("HRVBehaviour onEnter() - leaving");   	
    	return true;
	}

	function onMenu() {
		
		// Generate a new Menu for mainmenu
        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Main")});
        // add items
        menu.addItem(new Ui.MenuItem("Test type", null, "test", null));
        menu.addItem(new Ui.MenuItem("Source", null, "source", null));  
        menu.addItem(new Ui.MenuItem("Fit Output", null, "fitOutput", null));
        menu.addItem(new Ui.MenuItem("History view", null, "historySelection", null));       
        menu.addItem(new Ui.MenuItem("Load Intervals", null, "load", null));        
        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
        menu.addItem(new Ui.MenuItem("About", null, "about", null));
        Ui.pushView(menu, new MainMenuDelegate(), Ui.SLIDE_IMMEDIATE );
		return true;
    }

	function onEscape() {
		if(TEST_VIEW == $._mApp.viewNum) {
			var res = $._mApp.mTestControl.StateMachine(:escapePressed);	
			// true means we need to check to save	
			if (res == true) {		
				var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Save test")});
		        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
		        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
	 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_IMMEDIATE );  
			} 	
		
			// in TEST_VIEW. If we ended a test we fall back to test view otherwise Pop
			if ($._mApp.mTestControl.mTestState < TS_TESTING) {
				//Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
				Ui.popView(Ui.SLIDE_IMMEDIATE);
				return true;
			} //else {
				// we are not testing so must be real exit of app
				//Ui.popView(Ui.SLIDE_IMMEDIATE);
			//}
		} else {
			// move back to test view
			Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);				
		}
		return true;
	}

	function onPower() {
		return true;
	}
	
	function setSave(value) {
		//Sys.println("setSave() called with "+value);
		if (value == 1) { 
			//Sys.println("saveTest() called");
            $._mApp.mTestControl.saveTest();
        }
        else {
        	//Sys.println("discardTest() called");
        	$._mApp.mTestControl.discardTest();
        }		
    }
	
}

// This is the custom drawable we will use for our main menu title
class DrawableMenuTitle extends Ui.Drawable {
    var mIsTitleSelected = false;
    hidden var mTitle = "unset";

    function initialize(label) {
        Drawable.initialize({});
        mTitle = label;
    }

    function setSelected(isTitleSelected) {
        mIsTitleSelected = isTitleSelected;
    }

    // Draw the application icon and main menu title
    function draw(dc) {
        var spacing = 2;
        var appIcon = WatchUi.loadResource(Rez.Drawables.LauncherIcon);
        var bitmapWidth = appIcon.getWidth();
        var labelWidth = dc.getTextWidthInPixels(mTitle, $._mApp.mMenuTitleSize);

        var bitmapX = (dc.getWidth() - (bitmapWidth + spacing + labelWidth)) / 2;
        var bitmapY = (dc.getHeight() - appIcon.getHeight()) / 2;
        var labelX = bitmapX + bitmapWidth + spacing;
        var labelY = dc.getHeight() / 2;

        var bkColor = mIsTitleSelected ? Graphics.COLOR_BLUE : Graphics.COLOR_BLACK;
        dc.setColor(bkColor, bkColor);
        dc.clear();

        dc.drawBitmap(bitmapX, bitmapY, appIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, labelY, $._mApp.mMenuTitleSize, mTitle, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
