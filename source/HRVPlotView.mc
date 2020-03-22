using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;


// Plot the HRV over time for current test
// have a sliding window that just has last N results

class HrvPlotView extends Ui.View {

	function initialize() { View.initialize();}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {

    }

    //! Update the view
    function onUpdate(dc) {

    	var app = App.getApp();

    	// Default layout settings
	    var titleFont = 4;		// Gfx.FONT_LARGE
		var meridiemFont = 3;	// Gfx.FONT_MEDIUM
	    var numFont = 8;		// Gfx.FONT_NUMBER_THAI_HOT
	    var timeY = 74;
	    var titleY = 125;
	    var meridiemX = 1;
	    var meridiemY = 74;
	    var line1Y = 60;
	    var line2Y = 90;
	    var col1 = 102;

	    // Customize layout for device. Defaults = Epix & Vivo
        if(FORERUNNER == app.device) {
			titleY = 128;
			meridiemX = 4;
			meridiemY = 75;
        }
        else if(FENIX == app.device) {
        	meridiemFont = 2;		// Gfx.FONT_SMALL
			timeY = 104;
			titleY = 176;
			meridiemX = 0;
			meridiemY = 109;
			line1Y = 94;
			line2Y = 124;
			col1 = 109;
        } else if(FENIX6 == app.device) {
        	meridiemFont = 2;		// Gfx.FONT_SMALL
			timeY = 104;
			titleY = 176;
			meridiemX = 0;
			meridiemY = 109;
			line1Y = 94;
			line2Y = 124;
			col1 = 109;
        }

		var font = 1;		// Gfx.FONT_TINY
		var msgFont = 3;	// Gfx.FONT_MEDIUM
		var just = 5;		// Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER

		// Get time units
		var time = app.timeNow();
    	var hour = (time / 3600) % 24;
		var min = (time / 60) % 60;
		var sec = time % 60;

		// Process 12/24 hr differences
		var meridiemTxt = "";

		if(System.getDeviceSettings().is24Hour) {
			if(0 == time) {
				hour = 24;
			}
			else {
				hour = hour % 24;
			}
		}
		else {
			if(12 > hour) {
				meridiemTxt = "AM";
			}
			else {
				meridiemTxt = "PM";
			}
			hour = 1 + (hour + 11) % 12;
		}

		// Format time
    	var timeStr = format("$1$:$2$", [hour.format("%01d"), min.format("%02d")]);

		// Get meridiem offset
		var textW = dc.getTextWidthInPixels(timeStr, numFont);
		var col2 = col1 + meridiemX + textW / 2;

		// Draw the view
		MapSetColour(dc, TRANSPARENT, app.bgColSet);
		dc.clear();

		// Draw the lines
		MapSetColour(dc, app.lblColSet, app.bgColSet);
        dc.drawLine(0, line1Y, dc.getWidth(), line1Y);
		dc.drawLine(0, line2Y, dc.getWidth(), line2Y);

		// Fix for Forerunner. Text doesn't leave gap to lines
		if(FORERUNNER == app.device) {
			var x = (dc.getWidth() / 2) - (textW / 2) - 3;
			MapSetColour(dc, app.bgColSet, app.bgColSet);
			dc.drawLine(x, line1Y, x + textW + 6, line1Y);
			dc.drawLine(x, line2Y, x + textW + 6, line2Y);
			MapSetColour(dc, lblColSet, app.bgColSet);
        }

		dc.drawText(col1, timeY, numFont, timeStr, just);
		dc.drawText(col2, meridiemY, meridiemFont, meridiemTxt, 6);
		dc.drawText(col1, titleY, titleFont, "HRV", just);

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