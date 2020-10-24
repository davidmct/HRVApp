using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;

const DOUBLEDIGIT_FORMAT = "%02d";

// made this too specific for seconds so could rewrite

class NumberPicker extends WatchUi.Picker {

    function initialize(initial_v, limit_v, inc_v) {

        var title = new WatchUi.Text({:text=>Rez.Strings.numberPickerT, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        // allow for two 2 digit fields
        var factories = new [3];
        // need to split initial number over four digits
        if (limit_v > 5959) { throw new myException( "Number picker input > 5959"); }
        
        // test as putting these in NumFac didn't work
        // format now mm:ss
        var mTop = (limit_v / 100);
        var mBottom = limit_v % 100; 
        
        factories[0] = new NumberFactory(0, mTop, inc_v, {:format=>DOUBLEDIGIT_FORMAT});
        factories[1] = new WatchUi.Text({:text=>":", :font=>Graphics.FONT_MEDIUM, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER, :color=>Graphics.COLOR_WHITE});
        factories[2] = new NumberFactory(0, mBottom, inc_v, {:format=>DOUBLEDIGIT_FORMAT});
        
        // now fill in initial values of each factory
        var defaults = new [factories.size()];
        defaults[0] = initial_v / 60;
        defaults[0] = defaults[0];
        defaults[1] = null;
        defaults[2] = initial_v % 60;

        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}

class NumberPicker2Digit extends WatchUi.Picker {

    function initialize(Llimit_v, initial_v, Ulimit_v, inc_v) {

        var title = new WatchUi.Text({:text=>"Select", :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});
        // allow for one 2 digit field
        var factories = new [1];
        // need to split initial number over four digits
        if (Ulimit_v > 40) { throw new myException( "Number picker input > 40"); }
        if (Llimit_v < 10) { throw new myException( "Number picker input < 10"); }
      
        factories[0] = new NumberFactory(Llimit_v, Ulimit_v, inc_v, {:format=>DOUBLEDIGIT_FORMAT});
      
        // now fill in initial values of each factory
        var defaults = new [factories.size()];
        defaults[0] = initial_v;

        Picker.initialize({:title=>title, :pattern=>factories, :defaults=>defaults});
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

}