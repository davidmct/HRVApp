//
// Copyright 2018 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi;
using Toybox.Graphics;

class ItemView extends WatchUi.View {

    var mText;

    // Constructor
    function initialize(text) {
        View.initialize();
        mText = new WatchUi.Text({:text => text,
            :color => Graphics.COLOR_BLACK,
            :backgroundColor => Graphics.COLOR_WHITE,
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER,
            :justification => Graphics.TEXT_JUSTIFY_CENTER});
    }

    // Update the view
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        mText.draw(dc);
    }
}

class BasicCustomMenu extends WatchUi.CustomMenu {

    var mTitle;

    function initialize( itemHeight, backgroundColor, options ) {
        mTitle = options.get(:title);
        WatchUi.CustomMenu.initialize( itemHeight, backgroundColor, options );
    }

    function drawTitle( dc ) {
        if( mTitle != null ) {
            if( Toybox.WatchUi.CustomMenu has :isTitleSelected ) {
                mTitle.setSelected(isTitleSelected());
            }
        }
        WatchUi.CustomMenu.drawTitle(dc);
    }

    function drawFooter( dc ) {
        if( Toybox.WatchUi.CustomMenu has :isFooterSelected ) {
            if( isFooterSelected() ) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
                dc.clear();
            }
        }
        WatchUi.CustomMenu.drawFooter(dc);
    }
}

// This is the custom item drawable.
// It draws the label it is initialized with at the center of the region
class CustomItem extends WatchUi.CustomMenuItem {
    var mLabel;
    var mAmSelected;

    function initialize(id, label, selected) {
        CustomMenuItem.initialize(id, {});
        mLabel = label;
        mAmSelected = selected;
    }
    
	function setSelected (state) { mAmSelected = state;}
	
    // draw the item string at the center of the item.
    function draw(dc) {
        var font;
        
        if( isFocused() ) {
            font = Graphics.FONT_LARGE;
        } else {
            font = Graphics.FONT_SMALL;
        }

        if( isSelected() || (mAmSelected == true) ) {
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLUE);
            dc.clear();
        }

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, font, mLabel, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(0, 0, dc.getWidth(), 0);
        dc.drawLine(0, dc.getHeight() - 1, dc.getWidth(), dc.getHeight() - 1);
    }
}

class DrawableMenuFooter extends WatchUi.Drawable {
    function initialize() {
        Drawable.initialize({});
    }

    // Draw bottom half of the last dividing line below the final item
    function draw(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.drawLine(0, 0, dc.getWidth(), 0);
    }
}
