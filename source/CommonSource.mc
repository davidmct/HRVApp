using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

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