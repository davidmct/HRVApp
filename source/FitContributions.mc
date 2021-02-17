//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
// Copyright updates by David McTernan 2020 for HRV application 
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;
using Toybox.ActivityRecording;

// Logic..
// Init clears variables?
// Test control will open Session which should also create fields
// when test starts then start() session
// when test ends then save() or discard() test
// session var to null when done ready to go round again!

//0.4.9
// Seems a bug in fit. Limit on number of fields you can add.

class HRVFitContributor {

	var mSession;

    // FIT Contributions variables    

	//hidden var mSminIntervalFound_Field;
	//hidden var mSmaxIntervalFound_Field;
	//hidden var mSminDiffFound_Field;
	//hidden var mSmaxDiffFound_Field;

	hidden var mSAvgPulse_Field;
	hidden var mSmRMSSD_Field;
	hidden var mSmLnRMSSD_Field;
	hidden var mSmSDNN_Field;
	hidden var mSmSDSD_Field; 
	hidden var mSmNN50_Field;
	hidden var mSmpNN50_Field; 
	hidden var mSmNN20_Field;
	hidden var mSmpNN20_Field;
	hidden var mSSource_Field;
	hidden var mSLONG_Field;
	hidden var mSSHORT_Field;
	hidden var mSECTOPIC_Field;	
		
	hidden var mRAvgPulse_Field;
	hidden var mRmRMSSD_Field;
	hidden var mRmLnRMSSD_Field;
	hidden var mRmSDNN_Field;
	hidden var mRmSDSD_Field; 
	hidden var mRmNN50_Field;
	hidden var mRmpNN50_Field; 
	hidden var mRmNN20_Field;
	hidden var mRmpNN20_Field;
	//hidden var mRecordLONG_Field;
	//hidden var mRecordSHORT_Field;
	hidden var mRECTOPIC_Field;

    // Constructor ... 
    function initialize() {
    	mSession = null;
    }
    
    function createFitFields() {
 
 		// Monkey graph can't seem to display UINT16 in summary charts!!!
 		// Get rid of consts as hardwired in fircontributions.xml anyway so why maintain two lists     

       	mRAvgPulse_Field = mSession.createField("AvgPulse", 0, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"bpm" });
       	mRmRMSSD_Field = mSession.createField("RMSSD", 1, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRmLnRMSSD_Field = mSession.createField("LnRMSSD", 2, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRmSDNN_Field = mSession.createField("SDNN", 3, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRmSDSD_Field = mSession.createField("SDSD", 4, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" }); 
       	mRmNN50_Field = mSession.createField("NN50", 5, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	mRmpNN50_Field = mSession.createField("pNN50", 6, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" }); 
       	mRmNN20_Field = mSession.createField("NN20", 7, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
		mRmpNN20_Field = mSession.createField("pNN20", 8, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
       	//mRecordLONG_Field = mSession.createField("Long", 9, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	//mRecordSHORT_Field = mSession.createField("Short", 10, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	//mRecordECTOPIC_Field = mSession.createField("Ectopic-R", 11, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	mRECTOPIC_Field = mSession.createField("Ectopic-R", 11, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       			
        mSAvgPulse_Field = mSession.createField("AvgPulse", 20, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"bpm" });		
 	   	//mSminIntervalFound_Field = mSession.createField("MinInterval", 21, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	//mSmaxIntervalFound_Field = mSession.createField("MaxInterval", 22, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSmRMSSD_Field = mSession.createField("RMSSD", 23, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSmLnRMSSD_Field = mSession.createField("LnRMSSD", 24, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSmSDNN_Field = mSession.createField("SDNN", 25, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSmSDSD_Field = mSession.createField("SDSD", 26, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" }); 
       	mSmNN50_Field = mSession.createField("NN50", 27, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSmpNN50_Field = mSession.createField("pNN50", 28, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" }); 
       	mSmNN20_Field = mSession.createField("NN20", 29, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSmpNN20_Field = mSession.createField("pNN20", 30, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });
       	//mSminDiffFound_Field = mSession.createField("MinDiffII", 31, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	//mSmaxDiffFound_Field = mSession.createField("MaxDiffII", 32, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSLONG_Field = mSession.createField("Long",       33, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSSHORT_Field = mSession.createField("Short",     34, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSECTOPIC_Field = mSession.createField("Ectopic-S", 35, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
        mSSource_Field = mSession.createField("Src",   36, FitContributor.DATA_TYPE_STRING, {:count=>10, :mesgType=>FitContributor.MESG_TYPE_SESSION});
       			 
		//mSminIntervalFound_Field.setData(0);
		//mSmaxIntervalFound_Field.setData(0);
		//mSminDiffFound_Field.setData(0);
		//mSmaxDiffFound_Field.setData(0);
		
		mSAvgPulse_Field.setData(0);
		mSmRMSSD_Field.setData(0.0);
		mSmLnRMSSD_Field.setData(0.0);
		mSmSDNN_Field.setData(0.0);
		mSmSDSD_Field.setData(0.0); 
		mSmNN50_Field.setData(0);
		mSmpNN50_Field.setData(0.0); 
		mSmNN20_Field.setData(0);
		mSmpNN20_Field.setData(0.0);
		mSSource_Field.setData("");
		mSLONG_Field.setData(0.0);
		mSSHORT_Field.setData(0.0);
		mSECTOPIC_Field.setData(0.0);
		mSSource_Field.setData("");
			
		mRAvgPulse_Field.setData(0);
		mRmRMSSD_Field.setData(0.0);
		mRmLnRMSSD_Field.setData(0.0);
		mRmSDNN_Field.setData(0.0);
		mRmSDSD_Field.setData(0.0); 
		mRmNN50_Field.setData(0);
		mRmpNN50_Field.setData(0.0); 
		mRmNN20_Field.setData(0);
		mRmpNN20_Field.setData(0.0);
		//mRecordLONG_Field.setData(0.0);
		//mRecordSHORT_Field.setData(0.0);
		//mRecordECTOPIC_Field.setData(0.0);
		mRECTOPIC_Field.setData(0);
    }
    
	function createSession() {
		// if FIT write is enabled we can initialise session
		//15:25 27/04/20 mSession = null;
		if ($.mFitWriteEnabled) {
			if (Toybox has :ActivityRecording) {    
				if ((mSession != null) && mSession.isRecording()) {
		        	mSession.stop();                                      // stop the session
		           	mSession.discard();                                   // discard the session
		          	mSession = null;                                      // set session control variable to null
		       	}
		       	// should be able to create a new session
				if ((mSession == null) || (mSession.isRecording() == false)) {
					try {
			    		mSession = ActivityRecording.createSession(
					    	{     // set up recording session
					        :name=>"HRV",                                   // set session name
					        :sport=>ActivityRecording.SPORT_GENERIC,        // set sport type
					        :subSport=>ActivityRecording.SUB_SPORT_GENERIC, // set sub sport type
					        }
			    		);		
					} catch(e) { System.println(e.getErrorMessage()); }
				}
			} // has
			// may need to create fields after starting session!!
			//if (mSession != null) { createFitFields();}
			Sys.println("createSession successful");
			return mSession;
		} //write enabled
		return null;
	}
	
	function startFITrec() {
		if (mSession != null) {Sys.println("startFITrec"); mSession.start(); createFitFields();}
	}
	
	function discardFITrec() {
		if (mSession != null) {Sys.println("discardFITrec"); mSession.stop(); mSession.discard(); mSession = null;}
	}
	
	function saveFITrec() {
		if (mSession == null) { return;}
		Sys.println("saveFITrec");
		
		// need stop before writing summary fields
		mSession.stop();
		
		updateSessionStats();
		
		mSession.save();	
		
		mSession = null;	
	}
	
	function updateSessionStats() {
		//var gg = $.$.
	
		//mSminIntervalFound_Field.setData($.mSampleProc.minIntervalFound);
		//mSmaxIntervalFound_Field.setData($.mSampleProc.maxIntervalFound);
		//mSminDiffFound_Field.setData($.mSampleProc.minDiffFound);
		//mSmaxDiffFound_Field.setData($.mSampleProc.maxDiffFound);
		
		mSAvgPulse_Field.setData($.mSampleProc.avgPulse);
		mSmRMSSD_Field.setData($.mSampleProc.mRMSSD);
		mSmLnRMSSD_Field.setData($.mSampleProc.mLnRMSSD);
		mSmSDNN_Field.setData($.mSampleProc.mSDNN);
		mSmSDSD_Field.setData($.mSampleProc.mSDSD); 
		mSmNN50_Field.setData($.mSampleProc.mNN50);
		mSmpNN50_Field.setData($.mSampleProc.mpNN50); 
		mSmNN20_Field.setData($.mSampleProc.mNN20);
		mSmpNN20_Field.setData($.mSampleProc.mpNN20);	
		mSLONG_Field.setData($.mSampleProc.vLongBeatCnt.toFloat());
		mSSHORT_Field.setData($.mSampleProc.vShortBeatCnt.toFloat());
		mSECTOPIC_Field.setData($.mSampleProc.vEBeatCnt.toFloat());
					
		var str;
		if ($.mSensorTypeExt == SENSOR_SEARCH) {
			str = "Ext";
		} else {
			str = "Int";
		}
		mSSource_Field.setData(str);		

		//Sys.println("FIT Session: "+$.mSampleProc.avgPulse+","+$.mSampleProc.mNN50+","+$.mSampleProc.mpNN50+","+$.mSampleProc.mNN20+","+$.mSampleProc.mpNN20);		
	}
	
	function updateRecordStats() {
		//Sys.println("Updating FIT records");
		//var gg = $._m$.			
		mRAvgPulse_Field.setData($.mSampleProc.avgPulse);
		mRmRMSSD_Field.setData($.mSampleProc.mRMSSD);
		mRmLnRMSSD_Field.setData($.mSampleProc.mLnRMSSD);
		mRmSDNN_Field.setData($.mSampleProc.mSDNN);
		mRmSDSD_Field.setData($.mSampleProc.mSDSD); 
		
		//Sys.println("FIT record: "+$.mSampleProc.mNN50+","+$.mSampleProc.mpNN50+","+$.mSampleProc.mNN20+","+$.mSampleProc.mpNN20);

		mRmNN50_Field.setData($.mSampleProc.mNN50);
		mRmpNN50_Field.setData($.mSampleProc.mpNN50); 
		mRmNN20_Field.setData($.mSampleProc.mNN20);
		mRmpNN20_Field.setData($.mSampleProc.mpNN20);	
		//mRecordLONG_Field.setData($.mSampleProc.vLongBeatCnt.toFloat());
		//mRecordSHORT_Field.setData($.mSampleProc.vShortBeatCnt.toFloat());
		//mRecordECTOPIC_Field.setData($.mSampleProc.vEBeatCnt.toFloat());
		mRECTOPIC_Field.setData($.mSampleProc.vEBeatFlag);
		// reset for next sample
		$.mSampleProc.vEBeatFlag = 0;
	}
	
	function closeFITrec() {Sys.println("closeFITrec"); mSession = null;}
    
	// save data in FIT
    function compute() {
		if ((mSession == null) || ($.mTestControl.mTestState != TS_TESTING) ) {return;}
		// update records every call if testing
		updateRecordStats();
		// programmers guide says to update these as well!
		//updateSessionStats();			
    }

    function setTimerRunning() {
    }

    function onTimerLap() {        
    }

    function onTimerReset() {
    }

}
