using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;  
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Attention;

using GlanceGen as GG;
using HRVStorageHandler as mStorage;


    	// Message to glance structure
		//	[0] Avg HRV 1 month = 0 if no data... do we have to work out which days data falls on?
		//	[1] Avg HRV 1 week = 0 if no data
		//	[2] Latest HRV
		//	[3] Valid trend?
		//	[4] Trend and value +/-X. can we scale this and fit in range??
		//	[5] "Comment" string
		//	[6] current %  Position in age range (under, (low, high), over) : split display 20%, 60%, 20%
		//	[7] last update time utc		
		//  [8] Position for weekly dial
		//  [9] Position for monthly dial
		// [10] Low age HRV
		// [11] High age HRV

class HRVView extends Ui.View {

	// screen centre point
	hidden var scrnCP;
	hidden var mArcRadius;
	hidden var mArcWidth;
	hidden var mArrowLen;
	hidden var cGridWith;
	hidden var mCircColSel;
	hidden var _viewN;
	hidden var mJust = Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER;
			
    function initialize( viewNum) { 
      	View.initialize();  
        // Retrieve device type
		mCircColSel = 0; // which colour centre circle to show
		_viewN = viewNum;
     }

 	function onLayout(dc) {
 		scrnCP = [dc.getWidth()/2, dc.getHeight()/2]; 
 		mArcRadius = dc.getHeight() * 0.35;
		mArrowLen = mArcRadius-10;		
		mArcWidth = 20;
		
		// use as proxy for size of text box
		var a = Ui.loadResource(Rez.Strings.PoincareGridWidth);
		cGridWith = a.toNumber();
		a = null;
 	}	
 		 	
 	//! Restore the state of the app and prepare the view to be shown
    function onShow() { 
    	Sys.println("InitView onShow()");

    }
    
    //! Update the view
    function onUpdate(dc) {
    	//Sys.println("IntroView: onUpdate start");
    	
    	var _dataOK = false;
    	
    	if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
    	
		var width=dc.getWidth();
		var height=dc.getHeight();
		
		dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
		dc.clear();
		dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_TRANSPARENT);
		
		
		// NEED TO TEST FOR DATA AVAILABLE OTHERWISE MESSAGE
		
		// if view 0:
		// 	if mData not set then pull in old results once! and draw red circle around. Put -- in middle of circle
		//	if mData set and we have glance data then show results
		// if view 1
		// more text on screen - maybe even chart of HRV saved
		
		if (_viewN == 0) {	
			// Case of mGData true and glanceData null not possible as flag set after creation		
			if ($.mGData == true && $.glanceData != null) {
				// Need to draw green circle around like test view. Check not overwritten or add to code			
				resultsShow(dc, true);
			} else if ($.mGData == false ) {
				 if ($.glanceData == null || $.glanceData[0] == null) {
				 	// Try to load data and display
				 	_dataOK = $.loadGResultsFromStore();	
				 } else if ($.glanceData != null || $.glanceData[0] != null) {
				 	// we have previous loaded
				 	_dataOK = true;				 
				 }
				
				if (_dataOK) { 					
					// draw a red circle and also -- in middle
					//Sys.println("Show old results");
					resultsShow(dc, false);
				} else {
					//Sys.println("show no test");
					dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"No test result", mJust);
				}
			}	
		} else {
			// placeholder for second screen
			dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"Second screen placeholder", mJust);		
		
		}	
		
		// $.loadGResultsFromStore()	

		//Sys.println("IntroView: onUpdate exit");  
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {   	
    	Sys.println("onHide InitView");
    }   
    	
    // From analog sample
    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
    
    // BUT y axis is inverted (increases down) and hence rotation not what you expect from sign of cos/sin
    function generateHandCoordinates(centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], [width / 2, -handLength], [width / 2, tailLength]];
        var result = new [4];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }

        return result;
    }
        
    // Rotate an arrow head triangle that is offset from x,y in y dimension ie = handLength
    // arrowBase is bisected by x and has a Height
    function generateArrowCoordinates(centerPoint, angle, offset, arrowBase, arrowHeight ) {
        // Map out the coordinates of the arrow head      
        var result = new [3];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        
        // work out the default points of triangle
        var baseX = centerPoint[0];
        var baseY = centerPoint[1];
        
        var coords = [ [-(arrowBase / 2), -offset], [(arrowBase / 2), -offset], [ 0, -arrowHeight-offset] ];

		//Sys.println("Arrow base coords = "+coords);
		
        // Transform the coordinates
        for (var i = 0; i < 3; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
            var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

            result[i] = [centerPoint[0] + x, centerPoint[1] + y];
        }
		
		//Sys.println("Arrow coords: "+result);
		
        return result;
    }   

    
    function drawArrow( dc, _percent, _colour) {    
        var dialAngle = (180.0 * _percent - 90.0) * Math.PI / 180.0;

		// Set dial colour	
		dc.setColor( _colour, Gfx.COLOR_TRANSPARENT);  
		        
        //Sys.println ("Dial input = "+_percent+" % dialAngle in radians="+dialAngle);
         
        // (centerPoint, angle, handLength, tailLength, width) - angle of 0 = 12 o'clock
        dc.fillPolygon(generateHandCoordinates(scrnCP, dialAngle, mArrowLen, 10, 6));        
        // add a rotated arrow head
        // (centerPoint, angle, offset, arrowBase, arrowHeight )
        dc.fillPolygon(generateArrowCoordinates(scrnCP, dialAngle, mArrowLen-10, 18, mArcWidth));   
    
    }
    
    // draw the arrows showing status
    // Need to decide what three arrows represent!!
    // Drawing the dial hand: Angle should be based on %.  mid-point is 50%
	// adjust to make 12 o'clock 50%  
    function drawArrowSet( dc) {
  	
		// oldest arrow - monthly. starts as zero until have four weeks
		if ( $.glanceData[9] > 0.01) {
			drawArrow( dc, $.glanceData[9], Gfx.COLOR_DK_GRAY);
		}
		
		// next arrow
		drawArrow( dc, $.glanceData[8], Gfx.COLOR_LT_GRAY);
		 			  		
 		// main arrow		
		drawArrow( dc, $.glanceData[6], Gfx.COLOR_WHITE);
        
        // MAKE CIRCLE CONTAIN CURRENT HRV VALUE
        
        // add a cirlce a bottom of dial in blue for now
        // Could use colour band we are in!
        var mCol = Gfx.COLOR_DK_BLUE;
        
        //Sys.println(" mCircColSel="+mCircColSel);
        
        if (mCircColSel < 20 ) {
        	mCol = 	$.mArcCol[0];
        } else if ( mCircColSel < 50) {
        	mCol = 	$.mArcCol[1];
        } else if ( mCircColSel <= 80) {
        	mCol = 	$.mArcCol[2];
        } else {
        	mCol = 	$.mArcCol[3];
        }
    	dc.setColor( mCol, Gfx.COLOR_TRANSPARENT);
    	dc.fillCircle( scrnCP[0], scrnCP[1], 30);
    	
    	// add HRV to centre of circle
		//dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		dc.drawText(scrnCP[0], scrnCP[1], Gfx.FONT_TINY, $.glanceData[2].format("%.1f"), mJust);
    
    	// back to text colour
    	dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);   
       
    }
    
    // create results view
    // if _newG is true then have full data
	function resultsShow(dc, _newG) {
    
    	// Could draw a dial in upperhalf of screen with arrow showing scale position as per glance.
    	// would have band of R, A, G with arrow pointing to some point on arc
    	// below mid-point would have a set of labels: 
    	//	 Trend up/down arrow and delta as a % from trend
    	//	 Maybe message in TextBox?
    	// 	 Today and avg over X days for HRV?
    	
		//Sys.println("resultsShow");
		
		//0.6.3 HRV. Show source of data		
		if (_newG) {
			// draw green ring
			dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);	
		} else {
			// draw red ring
			dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);	
			
			// we should have no current data so NEED TO FORCE "--"
		}
		dc.setPenWidth(2);
		dc.drawArc(dc.getWidth()/2, dc.getHeight()/2, dc.getWidth()/2-2, Gfx.ARC_COUNTER_CLOCKWISE, 0, 360);
		dc.setPenWidth(1);		

    	// See if we can add age range labels. These will be at 54 degrees from vertical (12 o'clock = 0)
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
						
		var _results;
		var angle = -54 * Math.PI / 180.0;
		// mArcRadius plus width of arc itself
		_results = generateHandCoordinates(scrnCP, angle, mArcRadius+mArcWidth-5, 0, 2);
		
		//Sys.println("Results for txt ="+_results);
		//dc.fillPolygon( _results);
		
		dc.drawText(_results[1][0], _results[1][1], Gfx.FONT_XTINY, $.glanceData[10].format("%.0f"), Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);	
		
		angle = -angle; // 126 * Math.PI / 180.0;
		_results = generateHandCoordinates(scrnCP, angle, mArcRadius+mArcWidth-5, 0, 2);
		dc.drawText(_results[1][0], _results[1][1], Gfx.FONT_XTINY, $.glanceData[11].format("%.0f"), Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
		 	
    	// drawArc(x, y, r, attr, degreeStart, degreeEnd)
    	dc.setPenWidth( mArcWidth);
		dc.setColor($.mArcCol[0], Gfx.COLOR_BLACK);
		dc.drawArc(scrnCP[0], scrnCP[1], mArcRadius, Gfx.ARC_CLOCKWISE, 180, 144);
		dc.setColor($.mArcCol[1], Gfx.COLOR_BLACK);		
		dc.drawArc(scrnCP[0], scrnCP[1], mArcRadius, Gfx.ARC_CLOCKWISE, 144, 90);
		dc.setColor($.mArcCol[2], Gfx.COLOR_BLACK);
		dc.drawArc(scrnCP[0], scrnCP[1], mArcRadius, Gfx.ARC_CLOCKWISE, 90, 36);
		dc.setColor($.mArcCol[3], Gfx.COLOR_BLACK);
		dc.drawArc(scrnCP[0], scrnCP[1], mArcRadius, Gfx.ARC_CLOCKWISE, 36, 0);		
		dc.setPenWidth(1);	
		
		// draw dial arrows
		drawArrowSet(dc);		
		   	
    	var msgTxt = "";
    	var mTxt = "";
			
    	dc.setColor( mValueColour, Gfx.COLOR_TRANSPARENT);
    	var a = dc.getTextDimensions("HRV", Graphics.FONT_TINY);
    	var lineY = scrnCP[1]+30+a[1]/2;
    	var lineX = scrnCP[0]-cGridWith/2;

		if ( $.glanceData[3] == false) {
			mTxt = "unknown trend";
		} else {
			mTxt = "Trend: "+$.glanceData[4].format("%+.1f");
		}
		
		// was left just when using lineX. Draw ST trend
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, mJust);

		// Draw averages for M and W
		lineY += a[1] - 5;
		mTxt = " W="+$.glanceData[1].format("%.1f")+" M="+$.glanceData[0].format("%.1f");    		
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, mJust);
 		
 		// Draw recommendation
 		lineY += a[1] - 5;  
 		mTxt = $.glanceData[5]; 	
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, mJust);    	    	
    	
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    	if ( !_newG) {
			lineY += a[1] - 5; 
			dc.drawText(scrnCP[0], lineY, Gfx.FONT_TINY, "OLD", mJust);		
		}
 
    }
    
}