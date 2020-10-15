using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Graphics;

class HistoryMainMenuDelegate extends Ui.Menu2InputDelegate {
	
    function initialize() {
        Menu2InputDelegate.initialize();
    }

(:HistoryViaDictionary)
// pre 0.4.3 method    
    function AddToggleMenuItems( mMenu, labelNum) {
    
        var mKeys = $.mHistorySelect.keys();
        var options = {:enabled=>"selected", :disabled=>"deselected"};
        var align = {:alignment=>Ui.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT};
                  
        for (var i = 0; i < $.mHistorySelect.size() ; i++) {
        	var mHistoryName = mKeys[i].toString();
        	// can't control order unless use individual lines and no dictionary
        	// get value for current key
        	var index = $.mHistorySelect.get(mHistoryName);
        	var selectState = ($._mApp.mHistorySelectFlags & (1 << (index-1))) ? true : false;
        	//Sys.println("SelectState = "+selectState);
        	mMenu.addItem(new Ui.ToggleMenuItem(mHistoryName, options, mHistoryName, selectState, align));	        	
    	}
	}
	
    function AddHistoryMenuItems( mMenu, labelNum) {
        var options = {:enabled=>"selected", :disabled=>"deselected"};
        var align = {:alignment=>Ui.MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT};  
        var mHistoryLabelList = Ui.loadResource(Rez.JsonData.jsonHistoryLabelList); 
                       
        for (var i = 0; i < mHistoryLabelList.size() ; i++) {
        	var mHistoryName = mHistoryLabelList[i].toString();
        	var selectState = 0;
        	// should have made HistoryLabel an array
        	if (labelNum == 1) {
        		selectState = ($._mApp.mHistoryLabel1 == i) ? true : false;
        	} else if (labelNum == 2) {
        		selectState = ($._mApp.mHistoryLabel2 == i) ? true : false;
        	} else if (labelNum == 3) {
        		selectState = ($._mApp.mHistoryLabel3 == i) ? true : false;
        	}
        	//Sys.println("SelectState = "+selectState);
        	mMenu.addItem(new Ui.ToggleMenuItem(mHistoryName, options, i.toString(), selectState, align));
        	//mMenu.addItem(new Ui.MenuItem(mHistoryName, null, i.toString(), null));	        	
    	}
	}	

    function onSelect(item) {
        var id = item.getId();       
        // could use switch
        
        if( id.equals("1")) {            
            var toggleMenu = new Ui.Menu2({:title=> new DrawableMenuTitle("Label 1")});           
            AddHistoryMenuItems( toggleMenu, 1);
           	Ui.pushView(toggleMenu, new HistoryMenuDelegate(1, toggleMenu), Ui.SLIDE_IMMEDIATE );            	    
        } 
        else if( id.equals("2")) {            
            var toggleMenu = new Ui.Menu2({:title=> new DrawableMenuTitle("Label 2")});
            AddHistoryMenuItems( toggleMenu, 2);
           	Ui.pushView(toggleMenu, new HistoryMenuDelegate(2, toggleMenu), Ui.SLIDE_IMMEDIATE );            	    
        }
		else if( id.equals("3")) {            
            var toggleMenu = new Ui.Menu2({:title=> new DrawableMenuTitle("Label 3")});
            AddHistoryMenuItems( toggleMenu, 3);
           	Ui.pushView(toggleMenu, new HistoryMenuDelegate(3, toggleMenu), Ui.SLIDE_IMMEDIATE );            	    
        }
    }
        
    function onBack() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_IMMEDIATE);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
    
}