using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class PoincareView extends Ui.View {

	hidden var floorVar;
	hidden var scaleVar;
	var app;

	function initialize() { app = App.getApp(); View.initialize();}
	
    //! Restore the state of the app and prepare the view to be shown
    function onShow() {

    	var app = App.getApp();
    	app.resetGreenTimer();
		app.updateMinutes();
    }

    function scale(num) {

		return (((num - floorVar) * scaleVar) + 0.5).toNumber();
	}

    //! Update the view
    function onUpdate(dc) {

		var today = (app.timeToday() / 86400) % 30;	// Todays index
		var epoch = app.timeToday() - (86400 * 29);	// Index 29 days ago

		// REMOVE FOR PUBLISH
		//today = (app.timeNow() / 3600) % 30;	// Todays index
		//epoch = app.timeNow() - (3600 * 29);	// Index 29 days ago
		// REMOVE FOR PUBLISH
		//today = (app.timeNow() / 60) % 30;	// Todays index
		//epoch = app.timeNow() - (60 * 29);	// Index 29 days ago

		var dataCount = 0;
		var max = 0;
		var min = 310;

		// Find result limits
		for(var i = 0; i < 30; i++) {

			var ii = i * 5;

			// Only process if newer than epoch
			if(epoch <= app.results[ii]) {

				// Get range
				for(var iii = 1; iii <= 4; iii++) {

					var value = app.results[ii + iii];

					if(min > value) {
						min = value;
					}
					if(max < value) {
						max = value;
					}
				}

				dataCount++;
			}
		}

		// If no results then set min & max to create a nice graph scale
		if(0 == dataCount){
			min = -5;
			max = 5;
		}

		// Create the range
		var ceil = (max + 5) - (max % 5);
		var floor = min - (min % 5);

		var range = ceil - floor;
		var toggle = 0;
		while(0 != range % 15) {
			if(1 == toggle % 2) {
				ceil += 5;
			}
			else {
				floor -= 5;
			}
			range = ceil - floor;
			toggle++;
		}
		var scaleY = 90 / range.toFloat();

		floorVar = floor;
		scaleVar = scaleY;

		var font = 0; 	// Gfx.FONT_XTINY;
		var just = 5;	// Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
		var ctrX = dc.getWidth() / 2;
		var ctrY = dc.getHeight() / 2;
		var leftX = ctrX - 90;
		var rightX = ctrX + 90;
		var ceilY = ctrY - 45;
		var floorY = ctrY + 45;
		var textX = leftX + 20;
		var gap = (ceil - floor) / 3;
	    var line1Y = 60;
	    var line2Y = 90;

	    if(FENIX == app.device) {
			line1Y = 94;
			line2Y = 124;
		}

		// add code here
		// Draw the view
		//MapSetColour(dc, app.txtColSet, app.bgColSet);
		dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_BLACK);
		dc.clear();
		dc.drawText(100, 80, Gfx.FONT_MEDIUM, "POINCARE", Gfx.TEXT_JUSTIFY_CENTER); 
		dc.drawText(100, 150, Gfx.FONT_MEDIUM, app.mSensor.mHRData.mAntEvent.toString(), Gfx.TEXT_JUSTIFY_CENTER); 
		
		Sys.println("In POINCARE VIEW");
		
		// Testing only. Draw used memory
		//var str = System.getSystemStats().usedMemory.toString();
		//dc.setColor(WHITE, BLACK);
		//dc.drawText(dc.getWidth() / 2, 0, font, str, Gfx.TEXT_JUSTIFY_CENTER);
		
		//If using layout then calling onUpdate() works. If drawing explicitly then overwrites screen
		// Possibly needs to be at start! 
   		//View.onUpdate(dc);
    }
}