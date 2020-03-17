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
    	if(Ui.SLIDE_LEFT == direction && GRAPH_VIEW == app.viewNum) {
    		return Ui.SLIDE_IMMEDIATE;
		}
    	//else if((Ui.SLIDE_RIGHT == direction || Ui.SLIDE_DOWN == direction) && GRAPH_VIEW == app.viewNum) {
    	else if(Ui.SLIDE_RIGHT == direction && GRAPH_VIEW == app.viewNum) {
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
	    	Sys.println("HRVBehaviour onEnter(): isNotSaved " + app.isNotSaved);
	    	Sys.println("HRVBehaviour onEnter(): datacount " + app.mSensor.mHRData.dataCount);
	    	Sys.println("HRVBehaviour onEnter(): isFinished " + app.isFinished);
	    	Sys.println("HRVBehaviour onEnter(): isTesting " + app.isTesting);
	    	Sys.println("HRVBehaviour onEnter(): isWaiting " + app.isWaiting);
	    	Sys.println("HRVBehaviour onEnter(): isAntRx " + app.mSensor.mHRData.isAntRx);
	    }
    	// 
		if(0 < app.viewNum) {
			Sys.println("HRVBehaviour onEnter() - switch to test view");
			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
			return true;
		}
		else if(app.isNotSaved && MIN_SAMPLES < app.dataCount) {
			Sys.println("HRVBehaviour onEnter() - confirm save");
			Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
			// skips Green timer reset may need checking
			return true;
    	}
    	else if(app.isFinished) {
    		Sys.println("HRVBehaviour onEnter() - Finished");
    		app.resetTest();
    		Ui.requestUpdate();
    	}
    	else if(app.isTesting || app.isWaiting) {
    		Sys.println("HRVBehaviour onEnter() - Stop test");
    		app.stopTest();
    		Ui.requestUpdate();
    	}
    	else if(!app.mSensor.mHRData.isAntRx){
    		Sys.println("HRVBehaviour onEnter() - no ANT");
    		app.alert(TONE_ERROR);
    	}
    	else {
    		Sys.println("HRVBehaviour onEnter() - start branch");
    		app.startTest();
    		app.stopViewTimer();
    		app.updateSeconds();
    	}
		
    	app.resetGreenTimer();
 		Sys.println("HRVBehaviour onEnter() - leaving");   	
    	return true;
	}

	function onMenu() {
		app.stopGreenTimer();
		app.stopViewTimer();
		
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
			if(app.isTesting) {
				app.stopTest();
			}
			if(app.isFinished && app.isNotSaved && MIN_SAMPLES < app.mSensor.mHRData.dataCount) {
				app.isClosing = true;
				Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
			}
			else {
				app.onStop( null);
				Ui.popView(Ui.SLIDE_RIGHT);
			}
		}
		else {
			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
		}
		return true;
	}

	function onPower() {
		app.resetGreenTimer();
		return true;
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
        var labelWidth = dc.getTextWidthInPixels(mTitle, Graphics.FONT_MEDIUM);

        var bitmapX = (dc.getWidth() - (bitmapWidth + spacing + labelWidth)) / 2;
        var bitmapY = (dc.getHeight() - appIcon.getHeight()) / 2;
        var labelX = bitmapX + bitmapWidth + spacing;
        var labelY = dc.getHeight() / 2;

        var bkColor = mIsTitleSelected ? Graphics.COLOR_BLUE : Graphics.COLOR_BLACK;
        dc.setColor(bkColor, bkColor);
        dc.clear();

        dc.drawBitmap(bitmapX, bitmapY, appIcon);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(labelX, labelY, Graphics.FONT_MEDIUM, mTitle, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
