//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
// Copyright updates by David McTernan 2020 for HRV application 
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;

const AUX_HR_FIELD_ID    = 0;
const DELTA_HR_FIELD_ID  = 1;
const CURR_HEMO_CONC_FIELD_ID = 0;
const LAP_HEMO_CONC_FIELD_ID = 1;
const AVG_HEMO_CONC_FIELD_ID = 2;
const CURR_HEMO_PERCENT_FIELD_ID = 3;
const LAP_HEMO_PERCENT_FIELD_ID = 4;
const AVG_HEMO_PERCENT_FIELD_ID = 5;



// Want to save all stats plus min/max as session summary
//	var avgPulse;
//	var minIntervalFound;
//	var maxIntervalFound;
//	var mRMSSD;
//	var mLnRMSSD;
//	var mSDNN;
//	var mSDSD; 
//	var mNN50;
//	var mpNN50; 
//	var mNN20;
//	var mpNN20;
//		stats[9] = $._mApp.mSampleProc.minDiffFound;
//		stats[10] = $._mApp.mSampleProc.maxDiffFound;


// probably want to create this when testing is set up to start
class HRVFitContributor {

	// probably call mTestRunning
    hidden var mTimerRunning = false;

    // Variables for computing averages
    hidden var mHCLapAverage = 0.0;
    hidden var mHCSessionAverage = 0.0;
    hidden var mHPLapAverage = 0.0;
    hidden var mHPSessionAverage = 0.0;
    hidden var mLapRecordCount = 0;
    hidden var mSessionRecordCount = 0;

    // FIT Contributions variables
    hidden var mCurrentHCField = null;
    hidden var mLapAverageHCField = null;
    hidden var mSessionAverageHCField = null;
    hidden var mCurrentHPField = null;
    hidden var mLapAverageHPField = null;
    hidden var mSessionAverageHPField = null;

    // Constructor ... not sure we need dataField which is self in caller
    function initialize(dataField) {
        mCurrentHCField = dataField.createField("currHemoConc", CURR_HEMO_CONC_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>54, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"g/dl" });
        mLapAverageHCField = dataField.createField("lapHemoConc", LAP_HEMO_CONC_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>84, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"g/dl" });
        mSessionAverageHCField = dataField.createField("avgHemoConc", AVG_HEMO_CONC_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>95, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"g/dl" });

        mCurrentHPField = dataField.createField("currHemoPerc", CURR_HEMO_PERCENT_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>57, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
        mLapAverageHPField = dataField.createField("lapHemoConc", LAP_HEMO_PERCENT_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>87, :mesgType=>FitContributor.MESG_TYPE_LAP, :units=>"%" });
        mSessionAverageHPField = dataField.createField("avgHemoConc", AVG_HEMO_PERCENT_FIELD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>98, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });

        mCurrentHCField.setData(0);
        mLapAverageHCField.setData(0);
        mSessionAverageHCField.setData(0);

        mCurrentHPField.setData(0);
        mLapAverageHPField.setData(0);
        mSessionAverageHPField.setData(0);

    	// assume SINT is signed!
//        mAuxHRField    = dataField.createField("AuxHeartRate",  AUX_HR_FIELD_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>3,:mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
 //       mDeltaHRField  = dataField.createField("DeltaHeartRate",   DELTA_HR_FIELD_ID,  Fit.DATA_TYPE_SINT8, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });

//        mAuxHRField.setData(0);
//        mDeltaHRField.setData(0);

    }

// where is this called from? Probably add to Update cycle in HRVapp
    function compute(sensor) {
//       mAuxHRField.setData( heartRate.toNumber() );
//       mDeltaHRField.setData( sensor.data.OHRHeartRateDelta.toNumber());
		//if( mTimerRunning ) {
		//}
    }

    function setTimerRunning(state) {
        mTimerRunning = state;
    }

    function onTimerLap() {
        
    }

    function onTimerReset() {
 
    }

}
