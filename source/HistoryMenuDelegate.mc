using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Graphics;

class HistoryMenuDelegate extends Ui.Menu2InputDelegate {

	var instanceIndex;
	var mMenu;
		
    function initialize(num, menu) {
    	// which history label do we set?
    	instanceIndex = num;
    	// pass the toggle menu list!!
    	mMenu = menu;
        Menu2InputDelegate.initialize();
    }

(:HistoryViaDictionary)
// pre 0.4.3 method 
    function onSelect(item) {
        var id = item.getId();       
        // could use switch

        // id is dictionary entry, value is results index
        var index = $.mHistorySelect.get(id);
        
        // problem is that this is a toggle essentially so could select or deselect    
        // assume code sets this as required when item clicked
        if (item.isEnabled()) {
        	// check not exceeded 3 values
        	//Sys.println("History menu delegate. selected "+id+" index "+index);
    		
    		// set bit for this value	
 			$.mHistorySelectFlags |= (1 << (index-1));
        	// then check if limit reached and reset
        	if (checkToMany()) {
        		// need to set disabled and clear flag
        		//Sys.println("HistoryMenuDelegate: too many toggles selected");
        		item.setEnabled(false);
        		$.mHistorySelectFlags &= ~(1 << (index-1));  
        		$.mTestControl.alert(TONE_ERROR);     	
        	} 
 		}
 		else {
 			// deselected case
 			$.mHistorySelectFlags &= ~(1 << (index-1)); 
 		} // end deselected case
 		
 		//Sys.println("History menu delegate. mHistorySelectFlags = "+$.mHistorySelectFlags.format("%x"));
    }
    
    function onSelect(item) {
        var id = item.getId();       
        // id is a number as a string
        var index = id.toNumber();
        
        // problem is that this is a toggle essentially so could select or deselect    
        // assume code sets this as required when item clicked
        if (item.isEnabled()) {
			// only allowed one item ... should reset state
        	//Sys.println("History menu delegate. selected "+id+" index "+index+" for label "+instanceIndex);
         	if (instanceIndex == 1) {
        		$.mHistoryLabel1 = index;
        	} else if (instanceIndex == 2) {
        		$.mHistoryLabel2 = index;
        	} else if (instanceIndex == 3) {
        		$.mHistoryLabel3 = index;
        	}
        	
        	// fix the checked state as only one allowed
	       	for ( var i=0; i < cHISTORYLABELLISTSIZE; i++) { //$.mHistoryLabelList.size(); i++) {
	       		var itemID = mMenu.findItemById(i.toString());
	       		//Sys.println("itemID = "+itemID+" from i ="+i);
	       		if ( i == index) {
	       			mMenu.getItem(itemID).setEnabled(true);    
	       		} else {
	       			mMenu.getItem(itemID).setEnabled(false);	
	       		}
	       	}
	       	//Sys.println("History item "+instanceIndex+" set to "+$.mHistoryLabelList[index]);
        	
       	} else {
       		//Sys.println("History menu delegate. deselected "+id+" index "+index+" for label "+instanceIndex);
          	if (instanceIndex == 1) {
        		$.mHistoryLabel1 = 0;
        	} else if (instanceIndex == 2) {
        		$.mHistoryLabel2 = 0;
        	} else if (instanceIndex == 3) {
        		$.mHistoryLabel3 = 0;
        	}   
        	
        	// defaults to "none" and turn off current selection
        	var i=index;
        	var itemID = mMenu.findItemById(i.toString());
       		mMenu.getItem(itemID).setEnabled(false); 
       		i = 0;
        	itemID = mMenu.findItemById(i.toString());
       		mMenu.getItem(itemID).setEnabled(true);        		   
   		    //Sys.println("History item "+instanceIndex+" set to "+$.mHistoryLabelList[i]);
       	}	
       	
       	//// fix the checked state as only one allowed
       	//for ( var i=0; i < $.mHistoryLabelList.size(); i++) {
       	//	var itemID = mMenu.findItemById(i.toString());
       	//	//Sys.println("itemID = "+itemID+" from i ="+i);
       	//	if ( i == index) {
       	//		mMenu.getItem(itemID).setEnabled(true);    
       	//	} else {
       	//		mMenu.getItem(itemID).setEnabled(false);	
       	//	}
       	//}	

    }    

(:HistoryViaDictionary)
// pre 0.4.3 method     
    function checkToMany() {
    	// count number of bits set
    	// should be DATA_SET_SIZE
    	var count = 0;
    	for (var i = 0; i < 14 ; i++) {
    		// if non-zero then set
    		if ( $.mHistorySelectFlags & (1 << i) ) {  
    			count++; 
    			//Sys.println("count "+count);
    		}  	
    	}
    	//Sys.println("History menu delegate. Selected so far :"+count);
    	var exceeded = (count > MAX_DISPLAY_VAR) ? true : false;
    	return exceeded;
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