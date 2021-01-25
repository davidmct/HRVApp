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
		
// Use this step to allow back button to work!!
var finalShow = false;

(:discard)
class IntroView extends Ui.View {

	hidden var shown = false;
	hidden var oneCalc = true;
	hidden var mCloseCnt = 0;
	// screen centre point
	hidden var scrnCP;
	hidden var mArcRadius;
	hidden var mArcWidth;
	hidden var mArrowLen;
	hidden var cGridWith;
	hidden var mCircColSel;

	
	hidden var _allowExit = false;
			
    function initialize() { 
      	View.initialize();  
        // Retrieve device type
		$.mDeviceType = Ui.loadResource(Rez.Strings.DeviceNum).toNumber();
		shown = false;  // not shown test view
		oneCalc = true; // one pass of generating results only
		$.mTesting = true; // enter test state 1st
		$.mSaveSession = false;  // if test finishes then save
		mCloseCnt = 0; 
		mCircColSel = 0; // which colour centre circle to show
		_allowExit = false; // see if we can pop this view
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
    	 				
		if(!shown) { 	
			Sys.println("Initview show() !shown");	
	 		Ui.pushView( new TestView(), new HRVBehaviourDelegate(), Ui.SLIDE_IMMEDIATE);
	 		shown=true;			
		}
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
		dc.drawText(scrnCP[0], scrnCP[1], Gfx.FONT_TINY, $.glanceData[2].format("%.1f") ,Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    
    	// back to text colour
    	dc.setColor( $.mLabelColour, Gfx.COLOR_TRANSPARENT);   
       
    }
    
	function resultsShow(dc) {
    
    	// Could draw a dial in upperhalf of screen with arrow showing scale position as per glance.
    	// would have band of R, A, G with arrow pointing to some point on arc
    	// below mid-point would have a set of labels: 
    	//	 Trend up/down arrow and delta as a % from trend
    	//	 Maybe message in TextBox?
    	// 	 Today and avg over X days for HRV?
    	
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
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);

		// Draw averages for M and W
		lineY += a[1] - 5;
		mTxt = " W="+$.glanceData[1].format("%.1f")+" M="+$.glanceData[0].format("%.1f");    		
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
 		
 		// Draw recommendation
 		lineY += a[1] - 5;  
 		mTxt = $.glanceData[5]; 	
    	dc.drawText( scrnCP[0], lineY, Gfx.FONT_TINY, mTxt, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);    	    	
    }

(:discard)   
    function f_drawTrendArrow(dc) {    
        // Draw arrow showing trend or flat
    	// could make variable if we had a bounded value between -100 and 100 say
    	// need to add range around zero once scale known
    	var posArrow = [140, 200];
    	
    	// valid trend data
    	if ( $.glanceData[3] == true) {
	    	if ( $.glanceData[4] > 0) {
	    		// trend going up
	    		// principal is draw an arrow at an angle representing scale of trend
	    		// (centerPoint, angle, handLength, tailLength, width) - angle of 0 = 12 o'clock
	        	dc.fillPolygon(generateHandCoordinates(posArrow, 0, 20, 0, 8));        
		        // add a rotated arrow head
		        // (centerPoint, angle, offset, arrowBase, arrowHeight )
		        dc.fillPolygon(generateArrowCoordinates(posArrow, 0, 20, 10, 15 ));
	    	} else if ( $.glanceData[4] < 0) {
	    		// trend going down
	         	dc.fillPolygon(generateHandCoordinates(posArrow, 180, 20, 0, 8));        
		        // add a rotated arrow head
		        // (centerPoint, angle, offset, arrowBase, arrowHeight )
		        dc.fillPolygon(generateArrowCoordinates(posArrow, 180, 20, 10, 15 ));   	
	    	} else {
	    		dc.fillRectangle( posArrow[0] - 20/2, posArrow[1] - 8/2, 20, 8); 	
	    	}
    	}
    }
    
    function alert(type) {
		if( Attention has :playTone ) {
    		//Attention.playTone(type);
    	}
    	
    	if (Attention has :vibrate) {
    		Attention.vibrate([new Attention.VibeProfile(100,400)]);
    	}
    }
      
    //! Update the view
    function onUpdate(dc) {
    	//Sys.println("IntroView: onUpdate start");
    	
    	if(dc has :setAntiAlias) {dc.setAntiAlias(true);}
    	
		var width=dc.getWidth();
		var height=dc.getHeight();
		dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
		dc.clear();
		dc.setColor(Gfx.COLOR_BLUE,Gfx.COLOR_TRANSPARENT);
		
		if (finalShow && mSaveSession ) {
			// timer expired 
			
			// calculate glance and test results - only call once
			if (oneCalc) { 
				alert (TONE_SUCCESS);
				var _stats = [ $.mSampleProc.mRMSSD, $.mSampleProc.vEBeatCnt, $.mSampleProc.mNN50];
				mCircColSel = GG.generateResults( _stats);
				_stats = null; 
				oneCalc = false;
				
				// close sensors to stop overflow of buffers
				$.mSensor.CloseSensors();
				$.mSensor = null;
				
				// just in case any properties changed
				HRVS.saveProperties();
				
				// start timer
				mCloseCnt = $.mSecondCnt;
			}
			
			// display results for 5 seconds then set finalShow  = false. Could also probably release some memory buffers eg intervals			
			// time out of this view
			// removed timeout so user has to press back to exit or timeout of widget
			//if ( $.mSecondCnt > mCloseCnt + 15) { finalShow = false; _allowExit = true;}
			
			resultsShow(dc);

		} else if (finalShow && !mSaveSession) {
			// we hit escape or enter to leave session
		 	dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"No result saved\nHit Back to Exit",Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
		}
		else if (_allowExit) {		
			dc.drawText(width/2,height/2,Gfx.FONT_SMALL,"Hit Back to Exit",Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
			Sys.println("Hit back pushed to view");
			// what happens if we pop view here??
			// aim to leave widget
			//Ui.popView(Ui.SLIDE_IMMEDIATE); // System Error. failed invoking Symbol 
		}

		//Sys.println("IntroView: onUpdate exit");
  
    }

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    function onHide() {   	
    	Sys.println("onHide InitView");
    }
    
// ALL Glance data generation moved out to module
    
    
}