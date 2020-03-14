using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;


class NumberPicker extends WatchUi.Picker {

    function initialize(initial_v, limit_v, inc_v) {

        var title = new WatchUi.Text({:text=>Rez.Strings.numberPickerTitle, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        // allow for two 2 digit fields
        var factories = new [2];
        // need to split initial number over four digits
        if (limit_v > 9999) { throw new myException( "Number picker input > 9999"); }
        	
        factories[0] = new NumberFactory(0, limit_v % 100, inc_v, {});
        factories[1] = new NumberFactory(0, limit_v / 100, inc_v, {});
        
        // now fill in initial values of each factory
        var mTemp = factories.size();
        var defaults = [mTemp];

        defaults[0] = initial_v % 100;
        defaults[1] = initial_v / 100;

        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}