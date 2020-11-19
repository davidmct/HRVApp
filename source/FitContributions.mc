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

	hidden var mSessionMinIntervalFound_Field;
	hidden var mSessionMaxIntervalFound_Field;
	//hidden var mSessionMinDiffFound_Field;
	//hidden var mSessionMaxDiffFound_Field;

	hidden var mSessionAvgPulse_Field;
	hidden var mSessionmRMSSD_Field;
	hidden var mSessionmLnRMSSD_Field;
	hidden var mSessionmSDNN_Field;
	hidden var mSessionmSDSD_Field; 
	hidden var mSessionmNN50_Field;
	hidden var mSessionmpNN50_Field; 
	hidden var mSessionmNN20_Field;
	hidden var mSessionmpNN20_Field;
	hidden var mSessionSource_Field;
	hidden var mSessionLONG_Field;
	hidden var mSessionSHORT_Field;
	hidden var mSessionECTOPIC_Field;	
		
	hidden var mRecordAvgPulse_Field;
	hidden var mRecordmRMSSD_Field;
	hidden var mRecordmLnRMSSD_Field;
	hidden var mRecordmSDNN_Field;
	hidden var mRecordmSDSD_Field; 
	hidden var mRecordmNN50_Field;
	hidden var mRecordmpNN50_Field; 
	hidden var mRecordmNN20_Field;
	hidden var mRecordmpNN20_Field;
	//hidden var mRecordLONG_Field;
	//hidden var mRecordSHORT_Field;
	hidden var mRecordECTOPIC_Field;

    // Constructor ... 
    function initialize() {
    	mSession = null;
    }
    
    function createFitFields() {
 
 		// Monkey graph can't seem to display UINT16 in summary charts!!!
 		// Get rid of consts as hardwired in fircontributions.xml anyway so why maintain two lists     

       	mRecordAvgPulse_Field = mSession.createField("AvgPulse", 0, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"bpm" });
       	mRecordmRMSSD_Field = mSession.createField("RMSSD", 1, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmLnRMSSD_Field = mSession.createField("LnRMSSD", 2, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmSDNN_Field = mSession.createField("SDNN", 3, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmSDSD_Field = mSession.createField("SDSD", 4, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" }); 
       	mRecordmNN50_Field = mSession.createField("NN50", 5, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	mRecordmpNN50_Field = mSession.createField("pNN50", 6, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" }); 
       	mRecordmNN20_Field = mSession.createField("NN20", 7, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
		mRecordmpNN20_Field = mSession.createField("pNN20", 8, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
       	//mRecordLONG_Field = mSession.createField("Long", 9, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	//mRecordSHORT_Field = mSession.createField("Short", 10, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	//mRecordECTOPIC_Field = mSession.createField("Ectopic-R", 11, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       	mRecordECTOPIC_Field = mSession.createField("Ectopic-R", 11, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"#" });
       			
        mSessionAvgPulse_Field = mSession.createField("AvgPulse", 20, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"bpm" });		
 	   	//mSessionMinIntervalFound_Field = mSession.createField("MinInterval", 21, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	//mSessionMaxIntervalFound_Field = mSession.createField("MaxInterval", 22, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmRMSSD_Field = mSession.createField("RMSSD", 23, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmLnRMSSD_Field = mSession.createField("LnRMSSD", 24, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmSDNN_Field = mSession.createField("SDNN", 25, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmSDSD_Field = mSession.createField("SDSD", 26, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" }); 
       	mSessionmNN50_Field = mSession.createField("NN50", 27, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSessionmpNN50_Field = mSession.createField("pNN50", 28, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" }); 
       	mSessionmNN20_Field = mSession.createField("NN20", 29, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSessionmpNN20_Field = mSession.createField("pNN20", 30, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });
       	//mSessionMinDiffFound_Field = mSession.createField("MinDiffII", 31, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	//mSessionMaxDiffFound_Field = mSession.createField("MaxDiffII", 32, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionLONG_Field = mSession.createField("Long",       33, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSessionSHORT_Field = mSession.createField("Short",     34, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
       	mSessionECTOPIC_Field = mSession.createField("Ectopic-S", 35, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"#" });
        mSessionSource_Field = mSession.createField("Src",   36, FitContributor.DATA_TYPE_STRING, {:count=>10, :mesgType=>FitContributor.MESG_TYPE_SESSION});
       			 
		//mSessionMinIntervalFound_Field.setData(0);
		//mSessionMaxIntervalFound_Field.setData(0);
		//mSessionMinDiffFound_Field.setData(0);
		//mSessionMaxDiffFound_Field.setData(0);
		
		mSessionAvgPulse_Field.setData(0);
		mSessionmRMSSD_Field.setData(0.0);
		mSessionmLnRMSSD_Field.setData(0.0);
		mSessionmSDNN_Field.setData(0.0);
		mSessionmSDSD_Field.setData(0.0); 
		mSessionmNN50_Field.setData(0);
		mSessionmpNN50_Field.setData(0.0); 
		mSessionmNN20_Field.setData(0);
		mSessionmpNN20_Field.setData(0.0);
		mSessionSource_Field.setData("");
		mSessionLONG_Field.setData(0.0);
		mSessionSHORT_Field.setData(0.0);
		mSessionECTOPIC_Field.setData(0.0);
		mSessionSource_Field.setData("");
			
		mRecordAvgPulse_Field.setData(0);
		mRecordmRMSSD_Field.setData(0.0);
		mRecordmLnRMSSD_Field.setData(0.0);
		mRecordmSDNN_Field.setData(0.0);
		mRecordmSDSD_Field.setData(0.0); 
		mRecordmNN50_Field.setData(0);
		mRecordmpNN50_Field.setData(0.0); 
		mRecordmNN20_Field.setData(0);
		mRecordmpNN20_Field.setData(0.0);
		//mRecordLONG_Field.setData(0.0);
		//mRecordSHORT_Field.setData(0.0);
		//mRecordECTOPIC_Field.setData(0.0);
		mRecordECTOPIC_Field.setData(0);
    }
    
	function createSession() {
		// if FIT write is enabled we can initialise session
		//15:25 27/04/20 mSession = null;
		if ($._mApp.mFitWriteEnabled) {
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
		var gg = $._mApp;
	
		//mSessionMinIntervalFound_Field.setData(gg.mSampleProc.minIntervalFound);
		//mSessionMaxIntervalFound_Field.setData(gg.mSampleProc.maxIntervalFound);
		//mSessionMinDiffFound_Field.setData(gg.mSampleProc.minDiffFound);
		//mSessionMaxDiffFound_Field.setData(gg.mSampleProc.maxDiffFound);
		
		mSessionAvgPulse_Field.setData(gg.mSampleProc.avgPulse);
		mSessionmRMSSD_Field.setData(gg.mSampleProc.mRMSSD);
		mSessionmLnRMSSD_Field.setData(gg.mSampleProc.mLnRMSSD);
		mSessionmSDNN_Field.setData(gg.mSampleProc.mSDNN);
		mSessionmSDSD_Field.setData(gg.mSampleProc.mSDSD); 
		mSessionmNN50_Field.setData(gg.mSampleProc.mNN50);
		mSessionmpNN50_Field.setData(gg.mSampleProc.mpNN50); 
		mSessionmNN20_Field.setData(gg.mSampleProc.mNN20);
		mSessionmpNN20_Field.setData(gg.mSampleProc.mpNN20);	
		mSessionLONG_Field.setData(gg.mSampleProc.vLongBeatCnt.toFloat());
		mSessionSHORT_Field.setData(gg.mSampleProc.vShortBeatCnt.toFloat());
		mSessionECTOPIC_Field.setData(gg.mSampleProc.vEBeatCnt.toFloat());
					
		var str;
		if (gg.mSensorTypeExt == SENSOR_SEARCH) {
			str = "Ext";
		} else {
			str = "Int";
		}
		mSessionSource_Field.setData(str);		

		//Sys.println("FIT Session: "+gg.mSampleProc.avgPulse+","+gg.mSampleProc.mNN50+","+gg.mSampleProc.mpNN50+","+gg.mSampleProc.mNN20+","+gg.mSampleProc.mpNN20);		
	}
	
	function updateRecordStats() {
		//Sys.println("Updating FIT records");
		var gg = $._mApp;
				
		mRecordAvgPulse_Field.setData(gg.mSampleProc.avgPulse);
		mRecordmRMSSD_Field.setData(gg.mSampleProc.mRMSSD);
		mRecordmLnRMSSD_Field.setData(gg.mSampleProc.mLnRMSSD);
		mRecordmSDNN_Field.setData(gg.mSampleProc.mSDNN);
		mRecordmSDSD_Field.setData(gg.mSampleProc.mSDSD); 
		
		//Sys.println("FIT record: "+gg.mSampleProc.mNN50+","+gg.mSampleProc.mpNN50+","+gg.mSampleProc.mNN20+","+gg.mSampleProc.mpNN20);

		mRecordmNN50_Field.setData(gg.mSampleProc.mNN50);
		mRecordmpNN50_Field.setData(gg.mSampleProc.mpNN50); 
		mRecordmNN20_Field.setData(gg.mSampleProc.mNN20);
		mRecordmpNN20_Field.setData(gg.mSampleProc.mpNN20);	
		//mRecordLONG_Field.setData(gg.mSampleProc.vLongBeatCnt.toFloat());
		//mRecordSHORT_Field.setData(gg.mSampleProc.vShortBeatCnt.toFloat());
		//mRecordECTOPIC_Field.setData(gg.mSampleProc.vEBeatCnt.toFloat());
		mRecordECTOPIC_Field.setData(gg.mSampleProc.vEBeatFlag);
		// reset for next sample
		gg.mSampleProc.vEBeatFlag = 0;
	}
	
	function closeFITrec() {Sys.println("closeFITrec"); mSession = null;}
    
	// save data in FIT
    function compute() {
		if ((mSession == null) || ($._mApp.mTestControl.mTestState != TS_TESTING) ) {return;}
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
