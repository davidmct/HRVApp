using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.System as Sys;

class NumberFactory extends WatchUi.PickerFactory {
    hidden var mStart;
    hidden var mStop;
    hidden var mIncrement;
    hidden var mFormatString;
    hidden var mFont;

    function getIndex(value) {
        var index = (value / mIncrement) - mStart;
        return index;
    }

    function initialize(start, stop, increment, options) {
        PickerFactory.initialize();

        mStart = start;
        mStop = stop;
        mIncrement = increment;

        if(options != null) {
            mFormatString = options.get(:format);
            mFont = options.get(:font);
        }

        if(mFont == null) {
            mFont = Graphics.FONT_NUMBER_MEDIUM;
        }

        if(mFormatString == null) {
            mFormatString = "%d";
        }
    }

    function getDrawable(index, selected) {
    	// need to change this width if it works. Doesn't need to set two parts to field as per time!!
    	//Sys.println("Number Factory. need to make width based on screen size");
    	// take out :width=>200
        return new WatchUi.Text( { :text=>getValue(index).format(mFormatString),:color=>Graphics.COLOR_WHITE, :font=> mFont, :locX =>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_CENTER } );
    }

    function getValue(index) {
        return mStart + (index * mIncrement);
    }

    function getSize() {
        return ( mStop - mStart ) / mIncrement + 1;
    }

}
