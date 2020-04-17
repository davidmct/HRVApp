using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Graphics;

class HistoryMenuDelegate extends Ui.Menu2InputDelegate {
	
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();       
        // could use switch

        // id is dictionary entry, value is results index
        var index = $.mHistorySelect.get(id);
        
        // problem is that this is a toggle essentially so could select or deselect
        
        // on deselect then we clear flag 
        // on select we need to do a count of the number selected
        // .. using flag is latest
        // .. using status of all items requires access to other menu items
        
        // assume code sets this when item clicked
        if (item.isEnabled()) {
        	// check not exceeded 3 values
        	Sys.println("History menu delegate. selected "+$.mHistorySelect[id].toString());
        	var checkToMany = false;
        	
        	if (checkToMany) {
        		// need to set disabled and clear flag
        	
        	} else {        	
        		// set bit for this value		
 				$.mHistorySelectFlags |= (1 << (index-1));
 			}
 		}
 		else {
 			// deslected case
 		
 		} // end deselected case

 
    }
    
    function onBack() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(WatchUi.SLIDE_DOWN);
    }   
    
    function onWrap(key) {
        //Disallow Wrapping
        return false;
    }
    
}