using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class TestView extends Ui.View {

	hidden var app;
	
    function initialize() {
    	View.initialize();
    	app = App.getApp();
    }
    
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {
    	app.updateSeconds();
    	app.resetGreenTimer();

    	if(app.isClosing) {
			app.onStop( null );
			popView(SLIDE_RIGHT);
		}

		if(!app.isChOpen && !app.isWaiting) {
			app.mSensor.openCh();
		}
    }

    //! Update the view
    function onUpdate(dc) {
		//Sys.println("TestView:onUpdate() called");
    	// Default layout settings
	    var titleFont = 4;		// Gfx.FONT_LARGE
	    var numFont = 6;		// Gfx.FONT_NUMBER_MILD
	    var titleY = 14;
	    var strapY = 33;
	    var pulseY = 49;
	    var pulseLblY = 13;
	    var pulseTxtY = 41;
	    var msgTxtY = 74;
	    var resLblY = 99;
	    var resTxtY = 127;
	    var line1Y = 60;
	    var line2Y = 90;
	    var col1 = 65;
	    var col2 = 102;
	    var col3 = 164;

        var font = Gfx.FONT_TINY;		// Gfx.FONT_TINY 1
		var msgFont = Gfx.FONT_MEDIUM;	// Gfx.FONT_MEDIUM 3
		var just = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;		// Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER 5

    	// HRV
		var hrv = app.hrv;

		// Timer
		var timerTime = app.utcStop - app.utcStart;
		var testType = app.testTypeSet;

		if(TYPE_TIMER == testType) {
			timerTime = app.timerTimeSet;
		}
		else if(TYPE_AUTO == testType) {
			timerTime = app.autoTimeSet;
		}

		// Pulse
		var pulse = app.livePulse;

		// Message
    	var msgTxt;
    	var testTime = app.timeNow() - app.utcStart;

		if(app.isFinished) {
			pulse = app.avgPulse;
			testTime = app.utcStop - app.utcStart;

			if(MIN_SAMPLES > app.dataCount) {
				msgTxt = "Not enough data";
			}
			else if(app.isSaved) {
				msgTxt = "Result saved";
			}
			else {
				msgTxt = "Finished";
			}
    	}
    	else if(app.isTesting) {
    		//var cycleTime = (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			var cycle = 1 + testTime % (app.inhaleTimeSet + app.exhaleTimeSet + app.relaxTimeSet);
			if(cycle <= app.inhaleTimeSet) {
				msgTxt = "Inhale through nose " + cycle;
			}
			else if(cycle <= app.inhaleTimeSet + app.exhaleTimeSet) {
				msgTxt = "Exhale out mouth " + (cycle - app.inhaleTimeSet);
			}
			else {
				msgTxt = "Relax " + (cycle - (app.inhaleTimeSet + app.exhaleTimeSet));
			}

			if(TYPE_MANUAL != testType) {
				timerTime -= testTime;
			}
			else {
				timerTime = testTime;
			}
    	}
    	else if(app.isWaiting) {
    		msgTxt = "Autostart in " + app.timerFormat(app.timeAutoStart - app.timeNow());
    	}
    	else if(app.isStrapRx) {
			if(TYPE_TIMER == testType) {
				msgTxt = "Timer test ready";
			}
			else if(TYPE_MANUAL == testType) {
				msgTxt = "Manual test ready";
			}
			else {
				msgTxt = "Schedule " + app.clockFormat(app.autoStartSet);
			}
    	}
    	else {
    		msgTxt = "Searching for HRM";
    	}

    	// Strap & pulse indicators
    	var strapCol = app.txtColSet;
    	var pulseCol = app.txtColSet;
    	var strapTxt = "STRAP";
    	var pulseTxt = "PULSE";

    	if(!app.isChOpen) {
			pulse = 0;
			strapTxt = "SAVING";
			pulseTxt = "BATTERY";
		}
		else if(!app.isStrapRx) {
	    		strapCol = RED;
	    		pulseCol = RED;
    	}
    	else {
    		strapCol = GREEN;
    		if(!app.isPulseRx) {
	    		pulseCol = RED;
	    	}
	    	else {
	    		pulseCol = GREEN;
	    	}
    	}
    	
    	// adjust defaults for actual device now we have text strings
    	if(FORERUNNER == app.device) {
        	//numFont = 6;		// Gfx.FONT_NUMBER_MEDIUM
			resLblY = 100;
			pulseLblY = 12;
	    	pulseTxtY = 40;
        }
        else if(VIVOACTIVE == app.device) {
        	//numFont = 6;		// Gfx.FONT_NUMBER_MEDIUM
        }
        else if(EPIX == app.device) {
        	numFont = 6;		// Gfx.FONT_NUMBER_MEDIUM
        }
        else if(FENIX == app.device) {
        	numFont = Gfx.FONT_NUMBER_MEDIUM;	
        	titleFont = Gfx.FONT_MEDIUM;
			titleY = 47;
			strapY = 67;
			pulseY = 83;
			pulseLblY = 50;
			pulseTxtY = 73;
			msgTxtY = 108;
			resLblY = 134;
			resTxtY = 157;
			line1Y = 94;
			line2Y = 124;
			col1 = 80;
			col2 = 109;
			col3 = 154;
        } else if(FENIX6 == app.device) {
        	numFont =  Gfx.FONT_NUMBER_MILD; // was medium
        	titleFont = Gfx.FONT_MEDIUM;
        	
			titleY = 45;
			// text about strap and pulse
			var txt_size = [null, null];
			txt_size = dc.getTextDimensions("HRV TEST", titleFont);
			strapY = titleY + txt_size[1] + 5;
			// actual heart rate and label
			pulseLblY = titleY + txt_size[1]/2 + 5;			
			txt_size = dc.getTextDimensions( strapTxt, font);
			pulseY = strapY + txt_size[1] -5;
			pulseTxtY = strapY+(pulseY-strapY)/2;			
			
			// status message
			txt_size = dc.getTextDimensions( pulseTxt, font);
			var heightPulse = txt_size[1];
			msgTxtY = pulseY + heightPulse;
			
			// results strip under titles TIMER and HRV
			txt_size = dc.getTextDimensions( msgTxt, msgFont);
			resLblY = msgTxtY + txt_size[1] - 2;
			txt_size = dc.getTextDimensions( "TIMER", font);
			resTxtY = resLblY + txt_size[1];
			// lines splitting fields
			line1Y = msgTxtY - 15;
			line2Y = resLblY - 20;
			// Columns to display fields in
			col1 = dc.getWidth() /4 ;
			col2 = dc.getWidth() / 2;
			col3 = col1 + dc.getWidth() / 2 ;
        }
    	
		// Draw the view
        MapSetColour(dc, TRANSPARENT, app.bgColSet);
        dc.clear();

        MapSetColour( dc, app.lblColSet, TRANSPARENT);
        dc.drawLine(0, line1Y, dc.getWidth(), line1Y);
		dc.drawLine(0, line2Y, dc.getWidth(), line2Y);
		dc.drawText(col2, titleY, titleFont, "HRV TEST", just);
		dc.drawText(col3, pulseLblY, font, "BPM", just);
		dc.drawText(col1, resLblY, font, "TIMER", just);
		dc.drawText(col3, resLblY, font, "HRV", just);

		MapSetColour( dc, app.txtColSet, TRANSPARENT);
		dc.drawText(col3, pulseTxtY, numFont, pulse.toString(), just);
		dc.drawText(col2, msgTxtY, msgFont, msgTxt, just);
		dc.drawText(col1, resTxtY, numFont, app.timerFormat(timerTime), just);
		dc.drawText(col3, resTxtY, numFont, hrv.toString(), just);

		MapSetColour( dc, strapCol, TRANSPARENT);
		dc.drawText(col1, strapY, font, strapTxt, just);

		MapSetColour( dc, pulseCol, TRANSPARENT);
		dc.drawText(col1, pulseY, font, pulseTxt, just);

		// Testing only. Draw used memory
		//var str = System.getSystemStats().usedMemory.toString();
		//dc.setColor(WHITE, BLACK);
		//dc.drawText(dc.getWidth() / 2, 0, font, str, Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {
    }

}