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
		//Sys.println("onNextPage()");
		// down or swipe UP
		Ui.switchToView($.plusView(), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
    }

    function onPreviousPage() {
		// Up or swipe down
		Ui.switchToView($.subView(), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
		return true;
    }

    // handle other key presses
    function onKey(event) {
    	//Sys.println("onKey()");

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
    	//Sys.println("onEnter()");
		if($.viewNum != TEST_VIEW) {
			//Sys.println("HRVBehaviour onEnter() - switch to test view");
			Ui.switchToView($.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
			return true;
		}
		else {
			// in test view so means stop or start test
			var res = $.mTestControl.StateMachine(:enterPressed);
			// true if enough samples to save but we have to be in testing state
			if (res == true) {
				var menu = new Ui.Menu2({:title=>"Save?"});
		        menu.addItem(new Ui.MenuItem("Yes", null, "1", null));
		        menu.addItem(new Ui.MenuItem("No", null, "2", null));
	 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_IMMEDIATE );  
				return true;
			}
		}				
 		//Sys.println("HRVBehaviour onEnter() - leaving");   	
    	return true;
	}

	function onMenu() {
		//Sys.println("onMenu()");		
		// Generate a new Menu for mainmenu
        var menu = new Ui.Menu2({:title=>new DrawableMenuTitle("Main", false)});
        // add items
        menu.addItem(new Ui.MenuItem("Test type", null, "t", null));
        menu.addItem(new Ui.MenuItem("Source", null, "s", null));  
        menu.addItem(new Ui.MenuItem("Fit Output", null, "f", null));
        menu.addItem(new Ui.MenuItem("History view", null, "h", null));      
        //0.6.0 check low memory device
        if (System.getSystemStats().totalMemory > 128000) { 
        	//Sys.println("System memory > 128k");
        	menu.addItem(new Ui.MenuItem("Load Intervals", null, "l", null)); 
        }
       	menu.addItem(new Ui.MenuItem("Timer", null, "ti", null));
        menu.addItem(new Ui.MenuItem("Threshold", null, "th", null));
        menu.addItem(new Ui.MenuItem("Colours", null, "c", null));
        menu.addItem(new Ui.MenuItem("Auto Scaling", null, "sc", null));
        menu.addItem(new Ui.MenuItem("Sound", null, "so", null));
        menu.addItem(new Ui.MenuItem("Vibration", null, "v", null));   
        menu.addItem(new Ui.MenuItem("Reset", null, "r", null));    
        menu.addItem(new Ui.MenuItem("About", null, "a", null));
        Ui.pushView(menu, new MainMenuDelegate(), Ui.SLIDE_IMMEDIATE );
        //Sys.println("onMenu()- end");
		return true;
    }

	function onEscape() {
		//Sys.println("onEscape()");
		if(TEST_VIEW == $.viewNum) {
			var res = $.mTestControl.StateMachine(:escapePressed);	
			// true means we need to check to save	
			if (res == true) {		
				var menu = new Ui.Menu2({:title=>"Save test"});
		        menu.addItem(new Ui.MenuItem("Yes", null, "1", null));
		        menu.addItem(new Ui.MenuItem("No", null, "2", null));
	 	        Ui.pushView(menu, new ChoiceMenu2Delegate(self.method(:setSave)), Ui.SLIDE_IMMEDIATE );  
			} 	
		
			// in TEST_VIEW. If we ended a test we fall back to test view otherwise Pop
			if ($.mTestControl.mTestState < TS_TESTING) {
				//Ui.switchToView($.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
				Ui.popView(Ui.SLIDE_IMMEDIATE);
				return true;
			} 
		} else {
			// move back to test view
			Ui.switchToView($.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);				
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
            $.mTestControl.saveTest();
        }
        else {
        	//Sys.println("discardTest() called");
        	$.mTestControl.discardTest();
        }		
    }
	
}

// This is the custom drawable we will use for our main menu title
class DrawableMenuTitle extends Ui.Drawable {
    var mIsTitleSelected = false;
    hidden var mTitle = "unset";
    hidden var drawTrue;

    function initialize(label, mDrawBit) {
        Drawable.initialize({});
        mTitle = label;
        drawTrue = mDrawBit;
    }

    function setSelected(isTitleSelected) {
        mIsTitleSelected = isTitleSelected;
    }

    // Draw the application icon and main menu title
    function draw(dc) {
    	//Sys.println("Draw Menu Title draw?"+drawTrue);
        var spacing = 2;
        var appIcon = null;
        var bitmapWidth = 0;
        var bitmapX = 0;
        var bitmapY = 0;              
        var labelWidth = dc.getTextWidthInPixels(mTitle, $.mMenuTitleSize);
        
        if ( drawTrue) { 
        	appIcon = WatchUi.loadResource(Rez.Drawables.LauncherIcon);
          	bitmapWidth = appIcon.getWidth();
          	bitmapX = (dc.getWidth() - (bitmapWidth + spacing + labelWidth)) / 2;
        	bitmapY = (dc.getHeight() - appIcon.getHeight()) / 2;
        }

        var labelX = bitmapX + bitmapWidth + spacing;
        var labelY = dc.getHeight() / 2;

        var bkColor = mIsTitleSelected ? Graphics.COLOR_BLUE : Graphics.COLOR_BLACK;
        dc.setColor(bkColor, bkColor);
        dc.clear();

        if ( drawTrue) { dc.drawBitmap(bitmapX, bitmapY, appIcon);}
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        if (drawTrue) {
        	dc.drawText(labelX, labelY, $.mMenuTitleSize, mTitle, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {        
        	dc.drawText(dc.getWidth()/2, labelY, Gfx.FONT_MEDIUM, mTitle, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        //Sys.println("Draw Menu Title end");
    }
}
