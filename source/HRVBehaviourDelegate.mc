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
	
	function onNextPage() {
		// down or swipe UP
		Ui.switchToView($._mApp.plusView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_LEFT));
		return true;
    }

    function onPreviousPage() {
		// Up or swipe down
		Ui.switchToView($._mApp.subView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_RIGHT));
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

    function slide(direction) {

    	//if((Ui.SLIDE_LEFT == direction || Ui.SLIDE_UP == direction) && GRAPH_VIEW == $._mApp.viewNum) {
    	if(Ui.SLIDE_LEFT == direction && HISTORY_VIEW == $._mApp.viewNum) {
    		return Ui.SLIDE_IMMEDIATE;
		}
    	//else if((Ui.SLIDE_RIGHT == direction || Ui.SLIDE_DOWN == direction) && GRAPH_VIEW == $._mApp.viewNum) {
    	else if(Ui.SLIDE_RIGHT == direction && HISTORY_VIEW == $._mApp.viewNum) {
    		return Ui.SLIDE_IMMEDIATE;
    	}
    	else {
    		return direction;
    	}
    }

    function onEnter() {
    	if (mDebugging) {
	    	Sys.println("HRVBehaviour onEnter()");
	    	Sys.println("HRVBehaviour onEnter(): viewNum "+ $._mApp.viewNum);
	    	Sys.println("HRVBehaviour onEnter(): isNotSaved " + $._mApp.mTestControl.mState.isNotSaved);
	    	Sys.println("HRVBehaviour onEnter(): datacount " + $._mApp.mSampleProc.dataCount);
	    	Sys.println("HRVBehaviour onEnter(): isFinished " + $._mApp.mTestControl.mState.isFinished);
	    	Sys.println("HRVBehaviour onEnter(): isTesting " + $._mApp.mTestControl.mState.isTesting);
	    	Sys.println("HRVBehaviour onEnter(): isAntRx " + $._mApp.mSensor.mHRData.isAntRx);
	    	Sys.println("HRVBehaviour onEnter(): isOpenCh " + $._mApp.mSensor.mHRData.isChOpen);
	    }
    	// 
		if($._mApp.viewNum != TEST_VIEW) {
			Sys.println("HRVBehaviour onEnter() - switch to test view");
			Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
			return true;
		}
		else {
			// in test view so means stop or start test
			var res = $._mApp.HRVStateChange(:enterPressed);
			if (res == true) {
				//Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
				var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Save result")});
		        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
		        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
	 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_LEFT );  
				return true;
			}
		}
				
 		Sys.println("HRVBehaviour onEnter() - leaving");   	
    	return true;
	}

	function onMenu() {
		
		// Generate a new Menu for mainmenu
        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Main")});
        // add items
        menu.addItem(new Ui.MenuItem("Test type", null, "test", null));
        menu.addItem(new Ui.MenuItem("Source", null, "source", null));       
        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
        menu.addItem(new Ui.MenuItem("About", null, "about", null));
        Ui.pushView(menu, new MainMenuDelegate(), Ui.SLIDE_LEFT );
		return true;
    }

	function onEscape() {
		if(TEST_VIEW == $._mApp.viewNum) {
			var res = $._mApp.HRVStateChange(:escapePressed);
			if (res == true) {		
				//Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
				var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Save test")});
		        menu.addItem(new Ui.MenuItem("Yes", null, "optOne", null));
		        menu.addItem(new Ui.MenuItem("No", null, "optTwo", null));
	 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_LEFT );  
			} else {
				Ui.popView(Ui.SLIDE_RIGHT);
				// suspect onStop is called anyway
				//$._mApp.onStop(null);
			}			
		}
		else {
			Ui.switchToView($._mApp.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
		}
		return true;
	}

	function onPower() {
		return true;
	}
	
	function setSave(value) {
		Sys.println("setSave() called with "+value);
		if (value == "optOne") { 
            $._mApp.mTestControl.saveTest();
        }
        else {
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
