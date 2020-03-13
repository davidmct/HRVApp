using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;


class NumberPicker extends WatchUi.Picker {

    function initialize(initial_v, limit_v) {

        var title = new WatchUi.Text({:text=>Rez.Strings.numberPickerTitle, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        var factories = new [1];

        factories[0] = new NumberFactory(0, limit_v, 1, {});
 
        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>[initial_v]});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}
