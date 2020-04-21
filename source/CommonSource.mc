using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Lang;

// This is the custom drawable we will use for backgrounds
class CustomBackground extends Ui.Drawable {

    function initialize(settings) {
        Drawable.initialize({});
        //mColour = mapColour( $._mApp.bgColSet);
    }

    // fill background
    function draw(dc) {
    	// could draw a rectangle
    	var fore = mapColour( TRANSPARENT);
    	var back = mapColour($._mApp.bgColSet);
        dc.setColor(back, back);
    	dc.clear();

    }
}

function timerFormat(time) {
	var hour = time / 3600;
	var min = (time / 60) % 60;
	var sec = time % 60;
	if(0 < hour) {
		return Lang.format("$1$:$2$:$3$",[hour.format("%01d"),min.format("%02d"),sec.format("%02d")]);
	}
	else {
		return Lang.format("$1$:$2$",[min.format("%01d"),sec.format("%02d")]);
	}
}


function timeNow() {
	return (Time.now().value() + Sys.getClockTime().timeZoneOffset);
}

function timeToday() {
	return (timeNow() - (timeNow() % 86400));
}
