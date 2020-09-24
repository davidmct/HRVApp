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

const AVG_PULSE_FIELD_ID = 0;
const MIN_INTERVAL_FIELD_ID = 1;
const MAX_INTERVAL_FIELD_ID = 2;
const RMSSD_FIELD_ID = 3;
const LN_RMSSD_FIELD_ID = 4;
const SDNN_FIELD_ID = 5;
const SDSD_FIELD_ID = 6;
const NN50_FIELD_ID = 7;
const P_NN50_FIELD_ID = 8;
const NN20_FIELD_ID = 9;
const P_NN20_FIELD_ID = 10;
const MIN_DIFF_FIELD_ID = 11;
const MAX_DIFF_FIELD_ID = 12;
const R_AVG_PULSE_FIELD_ID = 13;
const R_RMSSD_FIELD_ID = 14;
const R_LN_RMSSD_FIELD_ID = 15;
const R_SDNN_FIELD_ID = 16;
const R_SDSD_FIELD_ID = 17;
const R_NN50_FIELD_ID = 18;
const R_P_NN50_FIELD_ID = 19;
const R_NN20_FIELD_ID = 20;
const R_P_NN20_FIELD_ID = 21;
const SOURCE_FIELD_ID = 22;

// 0.4.7 - add ectopic beat data
const MISSED_FIELD_ID = 23;
const R_MISSED_FIELD_ID = 24;
const DOUBLE_FIELD_ID = 25;
const R_DOUBLE_FIELD_ID = 26;


// Logic..
// Init clears variables?
// Test control will open Session which should also create fields
// when test starts then start() session
// when test ends then save() or discard() test
// session var to null when done ready to go round again!

class HRVFitContributor {

	var mSession;

    // FIT Contributions variables    

	hidden var mSessionMinIntervalFound_Field;
	hidden var mSessionMaxIntervalFound_Field;
	hidden var mSessionMinDiffFound_Field;
	hidden var mSessionMaxDiffFound_Field;

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
	hidden var mSessionMISSED_Field;
	hidden var mSessionDOUBLE_Field;
		
	hidden var mRecordAvgPulse_Field;
	hidden var mRecordmRMSSD_Field;
	hidden var mRecordmLnRMSSD_Field;
	hidden var mRecordmSDNN_Field;
	hidden var mRecordmSDSD_Field; 
	hidden var mRecordmNN50_Field;
	hidden var mRecordmpNN50_Field; 
	hidden var mRecordmNN20_Field;
	hidden var mRecordmpNN20_Field;
	hidden var mRecordMISSED_Field;
	hidden var mRecordDOUBLE_Field;

    // Constructor ... 
    function initialize() {
    	mSession = null;
    }
    
    function createFitFields() {
 
 		// Monkey graph can't seem to display UINT16 in summary charts!!!
 	   	mSessionMinIntervalFound_Field = mSession.createField("MinInterval", MIN_INTERVAL_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionMaxIntervalFound_Field = mSession.createField("MaxInterval", MAX_INTERVAL_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionMinDiffFound_Field = mSession.createField("MinDiffII", MIN_DIFF_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionMaxDiffFound_Field = mSession.createField("MaxDiffII", MAX_DIFF_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });

       	mSessionAvgPulse_Field = mSession.createField("AvgPulse", AVG_PULSE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"bpm" });
       	mSessionmRMSSD_Field = mSession.createField("RMSSD", RMSSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmLnRMSSD_Field = mSession.createField("LnRMSSD", LN_RMSSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmSDNN_Field = mSession.createField("SDNN", SDNN_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionmSDSD_Field = mSession.createField("SDSD", SDSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" }); 
       	mSessionmNN50_Field = mSession.createField("NN50", NN50_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"occurences" });
       	mSessionmpNN50_Field = mSession.createField("pNN50", P_NN50_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" }); 
       	mSessionmNN20_Field = mSession.createField("NN20", NN20_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"occurences" });
       	mSessionmpNN20_Field = mSession.createField("pNN20", P_NN20_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });
       	mSessionSource_Field = mSession.createField("Source", SOURCE_FIELD_ID, FitContributor.DATA_TYPE_STRING, {:count=>10, :mesgType=>FitContributor.MESG_TYPE_SESSION});
       	mSessionMISSED_Field = mSession.createField("Missed", MISSED_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	mSessionDOUBLE_Field = mSession.createField("Double", DOUBLE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"ms" });
       	
       	mRecordAvgPulse_Field = mSession.createField("AvgPulse", R_AVG_PULSE_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"bpm" });
       	mRecordmRMSSD_Field = mSession.createField("RMSSD", R_RMSSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmLnRMSSD_Field = mSession.createField("LnRMSSD", R_LN_RMSSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmSDNN_Field = mSession.createField("SDNN", R_SDNN_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordmSDSD_Field = mSession.createField("SDSD", R_SDSD_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" }); 
       	mRecordmNN50_Field = mSession.createField("NN50", R_NN50_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"occurences" });
       	mRecordmpNN50_Field = mSession.createField("pNN50", R_P_NN50_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" }); 
       	mRecordmNN20_Field = mSession.createField("NN20", R_NN20_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"occurences" });
		mRecordmpNN20_Field = mSession.createField("pNN20", R_P_NN20_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
       	mRecordMISSED_Field = mSession.createField("Missed", R_MISSED_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       	mRecordDOUBLE_Field = mSession.createField("Double", R_DOUBLE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"ms" });
       			 
		mSessionMinIntervalFound_Field.setData(0);
		mSessionMaxIntervalFound_Field.setData(0);
		mSessionMinDiffFound_Field.setData(0);
		mSessionMaxDiffFound_Field.setData(0);
		
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
		mSessionMISSED_Field.setData(0.0);
		mSessionDOUBLE_Field.setData(0.0);
			
		mRecordAvgPulse_Field.setData(0);
		mRecordmRMSSD_Field.setData(0.0);
		mRecordmLnRMSSD_Field.setData(0.0);
		mRecordmSDNN_Field.setData(0.0);
		mRecordmSDSD_Field.setData(0.0); 
		mRecordmNN50_Field.setData(0);
		mRecordmpNN50_Field.setData(0.0); 
		mRecordmNN20_Field.setData(0);
		mRecordmpNN20_Field.setData(0.0);
		mRecordMISSED_Field.setData(0.0);
		mRecordDOUBLE_Field.setData(0.0);
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
	
		mSessionMinIntervalFound_Field.setData($._mApp.mSampleProc.minIntervalFound);
		mSessionMaxIntervalFound_Field.setData($._mApp.mSampleProc.maxIntervalFound);
		mSessionMinDiffFound_Field.setData($._mApp.mSampleProc.minDiffFound);
		mSessionMaxDiffFound_Field.setData($._mApp.mSampleProc.maxDiffFound);
		
		mSessionAvgPulse_Field.setData($._mApp.mSampleProc.avgPulse);
		mSessionmRMSSD_Field.setData($._mApp.mSampleProc.mRMSSD);
		mSessionmLnRMSSD_Field.setData($._mApp.mSampleProc.mLnRMSSD);
		mSessionmSDNN_Field.setData($._mApp.mSampleProc.mSDNN);
		mSessionmSDSD_Field.setData($._mApp.mSampleProc.mSDSD); 
		mSessionmNN50_Field.setData($._mApp.mSampleProc.mNN50);
		mSessionmpNN50_Field.setData($._mApp.mSampleProc.mpNN50); 
		mSessionmNN20_Field.setData($._mApp.mSampleProc.mNN20);
		mSessionmpNN20_Field.setData($._mApp.mSampleProc.mpNN20);	
		mSessionMISSED_Field.setData($._mApp.mSampleProc.vMissedBeatCnt.toFloat());
		mSessionDOUBLE_Field.setData($._mApp.mSampleProc.vDoubleBeatCnt.toFloat());
			
		var str;
		if ($._mApp.mSensorTypeExt == SENSOR_SEARCH) {
			str = "External";
		} else {
			str = "Internal";
		}
		mSessionSource_Field.setData(str);		

		//Sys.println("FIT Session: "+$._mApp.mSampleProc.avgPulse+","+$._mApp.mSampleProc.mNN50+","+$._mApp.mSampleProc.mpNN50+","+$._mApp.mSampleProc.mNN20+","+$._mApp.mSampleProc.mpNN20);		
	}
	
	function updateRecordStats() {
		//Sys.println("Updating FIT records");
				
		mRecordAvgPulse_Field.setData($._mApp.mSampleProc.avgPulse);
		mRecordmRMSSD_Field.setData($._mApp.mSampleProc.mRMSSD);
		mRecordmLnRMSSD_Field.setData($._mApp.mSampleProc.mLnRMSSD);
		mRecordmSDNN_Field.setData($._mApp.mSampleProc.mSDNN);
		mRecordmSDSD_Field.setData($._mApp.mSampleProc.mSDSD); 
		
		//Sys.println("FIT record: "+$._mApp.mSampleProc.mNN50+","+$._mApp.mSampleProc.mpNN50+","+$._mApp.mSampleProc.mNN20+","+$._mApp.mSampleProc.mpNN20);

		mRecordmNN50_Field.setData($._mApp.mSampleProc.mNN50);
		mRecordmpNN50_Field.setData($._mApp.mSampleProc.mpNN50); 
		mRecordmNN20_Field.setData($._mApp.mSampleProc.mNN20);
		mRecordmpNN20_Field.setData($._mApp.mSampleProc.mpNN20);	
		mRecordMISSED_Field.setData($._mApp.mSampleProc.vMissedBeatCnt.toFloat());
		mRecordDOUBLE_Field.setData($._mApp.mSampleProc.vDoubleBeatCnt.toFloat());

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
