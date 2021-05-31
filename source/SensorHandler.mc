using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.Math;
using Toybox.Graphics as Gfx;
using Toybox.Sensor;

// Sample processing changes
// 1. Each batch update
//		When a batch of samples has arrived we can calculate group stats (these combined at end of test)
//		These are displayed on StatsView
//2. On each sample arriving...
//		don't do anything if not testing
//		If beatCount same as previous then ignore ie no pulse
//		If beatCount != previous+1 then we have missed data potentially
//			Options: ignore as invalid and move variables on
//					assume this is data unchanged and write previous values to store for count, event and IntMs
//		We shouldn't guess interval besides if well out of range ie a dropped beat or double beat then OK
//			(detect this in processing not in handler)
// 		Add intMs to list in sampleProcess class .. addSample()
//3. In sample processing we could work out delta and save this but more storage...

class SensorHandler {

    var mHRData;
    var sensor;
    hidden var mSensorType;
    hidden var mAntIDLocal;
    var mSearching;
    var mFunc;

    class HRStatus {
     	var isChOpen;
		var livePulse;
		var mHRMStatusCol;
    	var mHRMStatus;
		var mNoPulseCount;
		var mPrevBeatCount;
		var mPrevBeatEvent;

    	function initialize() {
        	isChOpen = false;
			// had to add $ to find RED symbol. enum stopped working here but was OK in other code!!
			mHRMStatusCol = 4; //$.RED;
    		mHRMStatus = "Searching...";
			initForTest();
			resetTestVariables();
		}

		function initForTest() {
			livePulse = 0;
			mNoPulseCount = 0;
			mPrevBeatCount = 0;
			mPrevBeatEvent = 0;
			resetTestVariables();
		}

		function resetTestVariables() {
			$.mSampleProc.resetHRVData();
		}
    }

	function initialize(mAntID, sensorType) {
    	mSearching = true;
    	mHRData = new HRStatus();
    	// true if external strap
    	mSensorType = sensorType;
    	mAntIDLocal = mAntID;
	   	mFunc = null;
    	//0.4.04 make sure if nothing used so far variable is null
    	sensor = null;
    }

    // function to call to update TestController
	function setObserver(func) {
		mFunc = func;
	}

    // clean-up on exit
    function CloseSensors() {
 		//
 		if ( sensor == null) { return;}

  		if (sensor has :stopExtSensor) {
    		sensor.stopExtSensor();
    	} else if (sensor has :stopIntSensor) {
    		sensor.stopIntSensor( self);
    	}
    }

(:discard)
    function fSwitchSensor( oldSensor) {
    	Sys.println("fSwitchSensor() potential sensor change of "+oldSensor+", to "+$.mSensorTypeExt);

    	if (oldSensor != $.mSensorTypeExt) {
    		// firstly close down original sensor

    		//0.4.5 optimisation
    		// no need to check OldSensor as only active one needs to be closed
    		CloseSensors();

    		//// 0.4.04 make type const
       		//if (oldSensor == SENSOR_SEARCH) { // ANT
       		//	//Sys.println("stopping ext ANT");
       		//	if ((sensor != null) && (sensor has :stopExtSensor)) {
    		//		sensor.stopExtSensor();
    		//	}
    		//} else { // internal strap or OHR
    		//	//Sys.println("stopping Internal");
    		//	if ((sensor != null) && (sensor has :stopIntSensor)) {
    		//		sensor.stopIntSensor();
    		//	}
    		//}

    		sensor = null;

    		// discard FIT session if active
    		// we should always have a mFitControl
    		if ($.mFitControl != null) {
    			$.mFitControl.discardFITrec();
    		}

	    	// now we can change local sensor type
	    	mSensorType = $.mSensorTypeExt;

	    	// reset local variables
	    	mHRData.initialize();

	    	// now create connection
	    	SetUpSensors();

    		// update Test controller data
    		// 0.4.5 This is done in SetUpSensors so remove
    		//if (false) {
			//	if (mFunc != null) {
			//		// sensor not ready and need a restart
			//		mFunc.invoke(:Update, [ "Switching sensor", false, true]);
			//	}
			//	// sending above message causes restart anyway !!
			//	// kill any running test
			//	$.mTestControl.StateMachine(:RestartControl);
			//}

			Sys.println("Sensor switched");
    	} else {
    		Sys.println("Sensor unchanged");
    	}
    }


// Now only inetrnal sensors to free memory
    function SetUpSensors() {
    	// has to be called after initialize as mSensor not created!!
    	mSearching = true;
	    // Internal or registered strap
		Sys.println("OHR or Strap selected");
		if (sensor != null) {sensor = null;}
		sensor = new InternalSensor(mHRData);
    }

(:discard)
    function SetUpSensors() {
    	// has to be called after initialize as mSensor not created!!
    	mSearching = true;

        if (mSensorType) {
    		// ANT case
    		Sys.println("ANT sensor");
    		if (sensor != null) {sensor = null;}
    		sensor = new AntHandler(mAntIDLocal, mHRData);
    	} else {
    		// Internal or registered strap
    		Sys.println("OHR or registered sensor");
    		if (sensor != null) {sensor = null;}
    		sensor = new InternalSensor(mHRData);
    	}
    	// update Test controller data
    	// 0.4.5 - done in init of each sensor
    	//if (mFunc != null) {
    	//	// no message and not ready; no state change needed
    	//	mFunc.invoke(:Update, [ "Setup sensor", false, false]);
    	//}
    }

(:discard)
    function openCh() {
    	// Garmin advice is release, initialize, setConfig, open!!!!
    	if (mHRData.isChOpen == true)
    	{
    		//Sys.println("OpenCh: closing open channels and reseting status");
    		//GenericChannel.close();
    	}
    	mSearching = true;
    	if (mSensorType) {
    		// only applies to ANT
    		Sys.println("openCh() trying to open channel again");
			mHRData.isChOpen = sensor.GenericChannel.open();
		}
		//if (mDebuggingANT == true) { Sys.println("openCh(): isOpen? "+ mHRData.isChOpen);}

		mHRData.mHRMStatusCol = 4; //RED;
    	mHRData.mHRMStatus = "Connected"; //"Found strap";
        // may need some other changes
    }

	// Close Ant channel.
(:discard)
    function closeCh() { // never called
    	// release dumps whole config
    	if(mHRData.isChOpen) {
    		//GenericChannel.release();
    		//if (mDebuggingANT == true) {Sys.println("CloseCh(): closing open channel");}
    		if (mSensorType) { sensor.GenericChannel.close();}
    	}
    	mHRData.isChOpen = false;
		mHRData.mHRMStatusCol = 4; //RED;
    	mHRData.mHRMStatus = "ANT closed";
	    mHRData.livePulse = 0;
		mSearching = true;

		// update Test controller data
		//0.4.5 - now done in init of each sensor
    	//if (mFunc != null) {
    	//	// no message and not ready
    	//	mFunc.invoke(:Update, [ "Closing channel", false, false]);
    	//}
    }
}

(:discard)
class AntHandler extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;  //strap
	const PERIOD = 8070; // 4x per second
	hidden var mChanAssign;
	var deviceCfg;
	hidden var mMessageCount=0;
	hidden var mHRDataLnk;
	//hidden var mSavedAntID;

    function initialize(mAntID, mHRData) {
    	mHRDataLnk = mHRData;

    	//$.DebugMsg( true, "mANTID : "+mAntID+" mHRDataLnk="+mHRDataLnk+" mHRData="+mHRData);

    	//mSavedAntID = mAntID;
    	mChanAssign = null;
    	deviceCfg = null;

        // Get the channel
        try {
	        mChanAssign = new Ant.ChannelAssignment(
	            //Ant.CHANNEL_TYPE_RX_NOT_TX,
	            Ant.CHANNEL_TYPE_RX_ONLY,
	            Ant.NETWORK_PLUS);
		} catch (ex) {
			Sys.println("Can't assign ANT channel, try again");
			stopExtSensor();
	        mChanAssign = new Ant.ChannelAssignment(
	            //Ant.CHANNEL_TYPE_RX_NOT_TX,
	            Ant.CHANNEL_TYPE_RX_ONLY,
	            Ant.NETWORK_PLUS);
		}
		finally {
			if (mChanAssign == null) { error ("No ANT Channels"); } //throw new $.myException( "No ANT channels available");}
		}
       	GenericChannel.initialize(method(:onAntMsg), mChanAssign);

        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => mAntID,             //Set to 0 to use wildcard search
            :deviceType => DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => 10,    // was 10 Timeout in 25s
            //:searchTimeoutHighPriority => 2,
            :searchThreshold => 0} );           //Pair to all transmitting sensors, 0 disabled, 1 = nearest
       	//mChanAssign.setBackgroundScan(true);

       	GenericChannel.setDeviceConfig(deviceCfg);
       	// returns true if channel open
       	mHRDataLnk.isChOpen = GenericChannel.open();

    	// update Test controller data
		if ($.mSensor.mFunc != null) {
			// no message and not ready, no state change -> 0.4.5 force reset
			$.mSensor.mFunc.invoke(:Update, [ "Sensor setup", false, true]);
		}

		// will now be searching for strap after openCh()
		Sys.println("ANT initialised. IsOpen:"+mHRDataLnk.isChOpen);
	}

	function stopExtSensor() {
		Sys.println("stopExtSensor: Stopping external ANT sensors");
		if (GenericChannel != null) {
    		GenericChannel.close();
    		GenericChannel.release();
    		//0.4.5
    		$.mSensor.mSearching = true;
    	}
	}

    function onAntMsg(msg)
    {
		var payload = msg.getPayload();

		//$.DebugMsg( true, "m.dt="+msg.messageId+"mS="+$.mSensor.mSearching);

		//if ( msg.messageId == 64) { $.DebugMsg( true, "type="+msg.deviceType+" TT="+msg.transmissionType);}

        //$.DebugMsg( mDebuggingANT, "device ID = " + msg.deviceNumber);
		//$.DebugMsg( mDebuggingANT, "deviceType = " + msg.deviceType);
		//$.DebugMsg( mDebuggingANT, "transmissionType= " + msg.transmissionType);
		//$.DebugMsg( mDebuggingANT, "getPayload = " + msg.getPayload());
		//$.DebugMsg( mDebuggingANT, "messageId = " + msg.messageId);
		//$.DebugMsg( mDebuggingANT, "A - "+mMessageCount);

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId  ) {
        	if ($.mSensor.mSearching) {
                $.mSensor.mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();

                //0.4.4
	            // This may be too early as may need a number of messages
				// using deviceCfg just gives value for setup!!!
				//$.DebugMsg( true, " msg.deviceNumber ="+msg.deviceNumber);
	            $.mAuxHRAntID = msg.deviceNumber;

                $.DebugMsg( true, "Ant ID found = "+$.mAuxHRAntID+". mSearching = false");
            }
			// not sure this handles all page types and 65th special page correctly

            mHRDataLnk.livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();
			mHRDataLnk.mHRMStatusCol = 8; //GREEN;
    		mHRDataLnk.mHRMStatus = "HR data";

    		//$.DebugMsg(true, "d");

    		// this is also called in sample processing but conditional
    		//0.4.4 - can't see reason for this!!
    		//if ($.mSensor.mFunc != null) {
			//	$.mSensor.mFunc.invoke(:Update, [ "Re-opening", true, false]);
			//}

			//if (mDebuggingANT == true) {
			//	Sys.println("ANT: Pulse is :" + mHRDataLnk.livePulse);
			//	Sys.println("beatEvent is :" + beatEvent);
			//	Sys.println("beatCount is :" + beatCount);
			//}

			newHRSampleProcessing(beatCount, beatEvent);
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
        	//$.DebugMsg( mDebuggingANT, "ANT EVENT msg");
        	//$.DebugMsg( true, "e");
       		if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
	            var event = (payload[1] & 0xFF);
	            // force closed
	            // event =  Ant.MSG_CODE_EVENT_CHANNEL_CLOSED;
	            switch( event) {
	            	case Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
	            		//Sys.println("ANT:EVENT: closed");
	            		//$.DebugMsg( true, "e.c");
	            		//$.mSensor.openCh();
	            		// open channel again
	            		mHRDataLnk.isChOpen = GenericChannel.open();
	            		// initialise again
	            		//initialize(mSavedAntID, mHRDataLnk);
	            		// NOT SURE WE SHOULD LOSE STRAP
						mHRDataLnk.mHRMStatusCol = 4; //RED;
    					mHRDataLnk.mHRMStatus = "Lost strap";
	    				mHRDataLnk.livePulse = 0;
						//$.mSensor.mSearching = true;
						// update Test controller data
						//$.DebugMsg(true, "CL.O."+mHRDataLnk.isChOpen);
    					if ($.mSensor.mFunc != null) {
							// no message and not ready, no state change
							$.mSensor.mFunc.invoke(:Update, [ "Re-opening", false, false]);
						}
	            		break;
	            	case Ant.MSG_CODE_EVENT_RX_FAIL:
	            		//$.DebugMsg( true, "e.f");

	            		// Maybe should ignore this state!!

	            		//0.4.5 comment out
						//mHRDataLnk.mHRMStatusCol = RED;
    					//mHRDataLnk.mHRMStatus = "Lost strap";
	    				//mHRDataLnk.livePulse = 0;
						////$.mSensor.mSearching = true;
						//// update Test controller data
    					//if ($.mSensor.mFunc != null) {
						//	// no message and not ready, no state change
						//	$.mSensor.mFunc.invoke(:Update, [ "RX fail", false, false]);
						//}
						// wait for another message?
						break;
					case Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
						//Sys.println( "ANT:RX_FAIL, search/wait");
						//$.DebugMsg( true, "e.s");
						$.mSensor.mSearching = true;
						break;
					case Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT:
						//Sys.println( "ANT: EVENT timeout");
						////closeCh();
						////openCh();
						//$.DebugMsg( true, "e.t");
						break;
	            	default:
	            		// channel response
	            		//$.DebugMsg( true, "e.d");
	            		//Sys.println( "ANT:EVENT: default");
	            		break;
	    		}
        	} else {
        		//Sys.println("Not an RF EVENT");
        		//$.DebugMsg( true, "e.n."+msg.messageId);
        	}
        } else {
    		//other message!
    		//$.DebugMsg( true, "e."+msg.messageId);
    		//Sys.println( "ANT other message " + msg.messageId);
    	}
    }

	function newHRSampleProcessing(beatCount, beatEvent) {

		// check we have a pulse and another beat recorded
		if(mHRDataLnk.mPrevBeatCount != beatCount && 0 < mHRDataLnk.livePulse) {
			// 0.4.4
			// don't need two next lines as in msg handler!
			//mHRDataLnk.mHRMStatusCol = 8; //GREEN;
			//mHRDataLnk.mHRMStatus = "HR data";

			mHRDataLnk.mNoPulseCount = 0;

			// update Test controller data
			if ($.mSensor.mFunc != null) {
				// no message and not ready, no state change
				$.mSensor.mFunc.invoke(:Update, [ "HR data incoming", true, false]);
			}

			// Get interval
			// need to check 64000 in ANT spec for roll-over number
			var intMs = 0;
			if(mHRDataLnk.mPrevBeatEvent > beatEvent) {
				intMs = 64000 - mHRDataLnk.mPrevBeatEvent + beatEvent;
			} else {
				intMs = beatEvent - mHRDataLnk.mPrevBeatEvent;
			}

			//Sys.println("HR->S");
			//0.4.3 - beatCount is byte that goes from 0-255 and wraps!!
			var beatsInGap;
			// wrap case
			if ( mHRDataLnk.mPrevBeatCount == 255) {
				beatsInGap = beatCount+1;
			} else {
				beatsInGap = beatCount - mHRDataLnk.mPrevBeatCount;
			}

			//var beatsInGap = beatCount - mHRDataLnk.mPrevBeatCount;
			var isTesting = false;
			if ( $.mTestControl.mTestState == TS_TESTING) {isTesting = true;}

			$.mSampleProc.rawSampleProcessing(isTesting, mHRDataLnk.livePulse, intMs, beatsInGap );

		} else {
			// either no longer have a pulse or Count not changing
			mHRDataLnk.mNoPulseCount += 1;
			if(0 < mHRDataLnk.livePulse) {
				var limit = 1 + 60000 / mHRDataLnk.livePulse / 246; // 246 = 4.06 KHz
				if(limit < mHRDataLnk.mNoPulseCount) {
					mHRDataLnk.mHRMStatusCol = 4; //RED;
    				mHRDataLnk.mHRMStatus = "Lost Pulse";
    				// update Test controller data
					if ($.mSensor.mFunc != null) {
						// no message and not ready, see if reacquire
						$.mSensor.mFunc.invoke(:Update, [ "Lost pulse", false, false]);
					}
				}
			}
		}
		mHRDataLnk.mPrevBeatCount = beatCount;
		mHRDataLnk.mPrevBeatEvent = beatEvent;
		//$.DebugMsg( false, "HRSampleProcessing - end");
	}
}

class InternalSensor {
	hidden var mHRDataLnk;

	function initialize(mHR) {
		mHRDataLnk = mHR;
		SensorSetup();
	}

	function stopIntSensor( _self) {
		Sys.println("Stopping internal sensors");

    	// suspicion that having no sensors kills optical after testing until long timeout
    	// Note CIQ ignores off state of ANT HRM. See if this line of code releases it.
    	
    	//0.6.3 remove disabling of sensors to keep already attached ones alive
		//Sensor.setEnabledSensors( [] );
		
		//0.6.6 aim to stop just strap if CIQ3.2
		var _ans = false;
		if (_self has :disableSensorType) {
			Sys.println("Stop: >=CIQ 3.2");
			_ans = disableSensorType( Sensor.SENSOR_HEARTRATE);
			if (_ans) { 
				Sys.println("Strap disabled"); 
			} 
		}
		
		Sensor.unregisterSensorDataListener( );
		//0.4.5
    	$.mSensor.mSearching = true;
	}

	// lets see if we can use sensor Toybox to get RR from both optical and ANT+
	// 3.0.0 on feature
	function SensorSetup() {
		var options = {
			:period => 1, 	// 1 second data packets
			:heartBeatIntervals => {:enabled => true}
		};
		
		//0.6.3 
		// Enable external and onboard if CIQ >= 3.2.0
		//0.6.4
		// Update test to select strap if available otherwise OHR
		var _ans;
		
		if (Sensor has :enableSensorType) {
			Sys.println(">=CIQ 3.2 detected");
			_ans = Sensor.enableSensorType( Sensor.SENSOR_HEARTRATE);
			if (_ans) { 
				Sys.println("Strap enabled"); 
			} else {
				Sys.println("no strap");
				_ans = Sensor.enableSensorType( Sensor.SENSOR_ONBOARD_HEARTRATE);
				if (_ans) { Sys.println("OHR enabled");} else {Sys.println("no OHR either");}
			}
		} else {
			_ans = Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE]);
			Sys.println("Enable response ="+_ans);
		}
		
		Sensor.registerSensorDataListener(self.method(:onHeartRateData), options);
		//Sys.println("Internal SensorSetup()");
	
		mHRDataLnk.isChOpen = true;
		$.mSensor.mSearching = false;

    	// update Test controller data
		if ($.mSensor.mFunc != null) {
			// no message and not ready, no state change -> 0.4.5 force reset of controller
			$.mSensor.mFunc.invoke(:Update, [ "Sensor setup: Int", false, true]);
		}
	}

	// call back for HR data
	function onHeartRateData( sensorData) {
		//var mSize = 0;
		var heartBeatIntervals = [];

		//$.DebugMsg( true, "H0");

		//Sys.println("sensorData "+sensorData);

		if (sensorData has :heartRateData && sensorData.heartRateData != null) {
			heartBeatIntervals = sensorData.heartRateData.heartBeatIntervals;

			var sensorInfo = Sensor.getInfo();
			if (sensorInfo == null || sensorInfo.heartRate == null) {
				// flag no data and
				mHRDataLnk.livePulse = 0;
				mHRDataLnk.mHRMStatusCol = 4; //RED;
				mHRDataLnk.mHRMStatus = "Lost Pulse";
				// update Test controller data
				if ($.mSensor.mFunc != null) {
					$.mSensor.mFunc.invoke(:Update, [ mHRDataLnk.mHRMStatus, false, false]);
				}
			} else {
				mHRDataLnk.livePulse = sensorInfo.heartRate;
				mHRDataLnk.mHRMStatusCol = 8; //GREEN;
				mHRDataLnk.mHRMStatus = "HR data";
				// update Test controller data
				if ($.mSensor.mFunc != null) {
					$.mSensor.mFunc.invoke(:Update, [ mHRDataLnk.mHRMStatus, true, false]);
				}
			}

			//$.DebugMsg( true, "H1");

			// now feed machine...
			//Sys.println("heartBeatIntervals.size() "+heartBeatIntervals.size());
			var isTesting = false;
			if ( $.mTestControl.mTestState == TS_TESTING) {isTesting = true;}

			//$.DebugMsg( true, "H-"+heartBeatIntervals.size().toString());

			for ( var i=0; i< heartBeatIntervals.size(); i++) {
				var intMs = heartBeatIntervals[i];
				//$.DebugMsg( true, "H2");
				$.mSampleProc.rawSampleProcessing(isTesting, mHRDataLnk.livePulse, intMs, 1 );
			}
		}
		//else {
		//	// no intervals
		//	$.DebugMsg( true, "H-noHRD");
		//}

		//Sys.println("Internal: live "+ mHRDataLnk.livePulse+" intervals "+heartBeatIntervals);
	}
}
