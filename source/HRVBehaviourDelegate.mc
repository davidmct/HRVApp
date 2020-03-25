using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class HRVBehaviourDelegate extends Ui.BehaviorDelegate {

    var app;
    
    function initialize() {
		BehaviorDelegate.initialize();
		app = App.getApp();
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
		Ui.switchToView(app.plusView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_LEFT));
		return true;
    }

    function onPreviousPage() {
		// Up or swipe down
		Ui.switchToView(app.subView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_RIGHT));
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

    	//if((Ui.SLIDE_LEFT == direction || Ui.SLIDE_UP == direction) && GRAPH_VIEW == app.viewNum) {
    	if(Ui.SLIDE_LEFT == direction && HISTORY_VIEW == app.viewNum) {
    		return Ui.SLIDE_IMMEDIATE;
		}
    	//else if((Ui.SLIDE_RIGHT == direction || Ui.SLIDE_DOWN == direction) && GRAPH_VIEW == app.viewNum) {
    	else if(Ui.SLIDE_RIGHT == direction && HISTORY_VIEW == app.viewNum) {
    		return Ui.SLIDE_IMMEDIATE;
    	}
    	else {
    		return direction;
    	}
    }

    function onEnter() {
    	if (mDebugging) {
	    	Sys.println("HRVBehaviour onEnter()");
	    	Sys.println("HRVBehaviour onEnter(): viewNum "+ app.viewNum);
	    	Sys.println("HRVBehaviour onEnter(): isNotSaved " + app.mTestControl.mState.isNotSaved);
	    	Sys.println("HRVBehaviour onEnter(): datacount " + app.mSensor.mHRData.dataCount);
	    	Sys.println("HRVBehaviour onEnter(): isFinished " + app.mTestControl.mState.isFinished);
	    	Sys.println("HRVBehaviour onEnter(): isTesting " + app.mTestControl.mState.isTesting);
	    	Sys.println("HRVBehaviour onEnter(): isAntRx " + app.mSensor.mHRData.isAntRx);
	    	Sys.println("HRVBehaviour onEnter(): isOpenCh " + app.mSensor.mHRData.isChOpen);
	    }
    	// 
		if(app.viewNum != TEST_VIEW) {
			Sys.println("HRVBehaviour onEnter() - switch to test view");
			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
			return true;
		}
		else {
			// in test view so means stop or start test
			var res = app.HRVStateChange(:enterPressed);
			if (res == true) {
				Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
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
        menu.addItem(new Ui.MenuItem("Settings", null, "settings", null));
        menu.addItem(new Ui.MenuItem("About", null, "about", null));
        Ui.pushView(menu, new MainMenuDelegate(), Ui.SLIDE_LEFT );
		return true;
    }

	function onEscape() {
		if(TEST_VIEW == app.viewNum) {
			var res = app.HRVStateChange(:escapePressed);
			if (res == true) {		
				Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
			} else {
				Ui.popView(Ui.SLIDE_RIGHT);
				app.onStop(null);
			}			
		}
		else {
			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
		}
		return true;
	}

	function onPower() {
		return true;
	}
}

// This is the custom drawable we will use for our main menu title
class DrawableMenuTitle extends Ui.Drawable {
    var mIsTitleSelected = false;
    hidden var mTitle = "unset";
    hidden var app;

    function initialize(label) {
        Drawable.initialize({});
        app = App.getApp();
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
        var labelWidth = dc.getTextWidthInPixels(mTitle, app.mMenuTitleSize);

        var bitmapX = (dc.getWidth() - (bitmapWidth + spacing + labelWidth)) / 2;
        var bitmapY = (dc.getHeight() - appIcon.getHeight()) / 2;
        var labelX = bitmapX + bitmapWidth + spacing;
        var labelY = dc.getHeight() / 2;

        var bkColor = mIsTitleSelected ? Graphics.COLOR_BLUE : Graphics.COLOR_BLACK;
        dc.setColor(bkColor, bkColor);
        dc.clear();

        dc.drawBitmap(bitmapX, bitmapY, appIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, labelY, app.mMenuTitleSize, mTitle, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
