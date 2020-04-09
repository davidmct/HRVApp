//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.FitContributor as Fit;

const AUX_HR_FIELD_ID    = 0;
const DELTA_HR_FIELD_ID  = 1;


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

class AuxHRFitContributor {

    hidden var mTimerRunning = false;

    // FIT Contributions variables
    hidden var mAuxHRField = null;
    hidden var mDeltaHRField  = null;

    // Constructor
    function initialize(dataField) {
    	// assume SINT is signed!
//        mAuxHRField    = dataField.createField("AuxHeartRate",  AUX_HR_FIELD_ID, Fit.DATA_TYPE_UINT8, { :nativeNum=>3,:mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });
 //       mDeltaHRField  = dataField.createField("DeltaHeartRate",   DELTA_HR_FIELD_ID,  Fit.DATA_TYPE_SINT8, { :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"bpm" });

//        mAuxHRField.setData(0);
//        mDeltaHRField.setData(0);

    }

    function compute(sensor, mSensorFound) {
//       mAuxHRField.setData( heartRate.toNumber() );
//       mDeltaHRField.setData( sensor.data.OHRHeartRateDelta.toNumber());

    }

    function setTimerRunning(state) {
        //mTimerRunning = state;
    }

    function onTimerLap() {
        
    }

    function onTimerReset() {
 
    }

}
