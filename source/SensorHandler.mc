using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.Math;
using Toybox.Graphics as Gfx;

// Sample processing changes
// 1. Each batch update
//		When a batch of samples has arrived we can calculate group stats (these combined at end of test)
//		These are displayed on SummaryView
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

class SensorHandler {//extends Ant.GenericChannel {
   
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
			mHRMStatusCol = $.RED;
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
			$._mApp.mSampleProc.resetHRVData();
		} 
    }
	
	function initialize(mAntID, sensorType) {
    	mSearching = true;  	
    	mHRData = new HRStatus();  
    	// true if external strap 		
    	mSensorType = sensorType;
    	mAntIDLocal = mAntID;
    	mFunc = null;
    }
    
    // function to call to update TestController
	function setObserver(func) {
		mFunc = func;
	}
    
    function fSwitchSensor( oldSensor) {
    	Sys.println("fSwitchSensor() potential sensor change");

    	if (oldSensor != $._mApp.mSensorTypeExt) {
    		// firstly close down original sensor   		
       		if (oldSensor) { // ANT
    			if (sensor != null) {sensor.stopExtSensor(); }
    		} else { // internal strap or OHR
    			if (sensor != null) {sensor.stopIntSensor(); }  		
    		}
  	
	    	// now we can change local sensor type
	    	mSensorType =  $._mApp.mSensorTypeExt;

	    	// reset local variables
	    	mHRData.initialize();
	    		    	
	    	// now create connection
	    	SetUpSensors();
	    				
    		// update Test controller data  
			if (mFunc != null) {
				mFunc.invoke(:Update, [ "Switching sensor", false, true]);
			}

			Sys.println("Sensor switched");
    	} else {
    		Sys.println("Sensor unchanged");
    	}  	
    }
    
    function SetUpSensors() {
    	// has to be called after initialize as mSensor not created!!
    	mSearching = true;
    	
        if (mSensorType) {
    		// ANT case
    		Sys.println("ANT sensor selected");
    		sensor = new AntHandler(mAntIDLocal, mHRData);
    	} else {
    		// Internal or registered strap
    		Sys.println("OHR or registered sensor selected");
    		sensor = new InternalSensor(mHRData);
    	}
    	// update Test controller data  
    	if (mFunc != null) {
    		// no message and not ready; no state change needed
    		mFunc.invoke(:Update, [ "Setup sensor", false, false]);
    	}
    }
    
    function openCh() { 
    	// Garmin advice is release, initialize, setConfig, open!!!!
    	if (mHRData.isChOpen == true)
    	{
    		//Sys.println("OpenCh: closing open channels and reseting status");
    		//GenericChannel.close();
    	}
    	mSearching = true;  
    	if ($._mApp.mSensor.mSensorType) { 	
    		// only applies to ANT
			mHRData.isChOpen = sensor.GenericChannel.open();
		}
		//if (mDebuggingANT == true) { Sys.println("openCh(): isOpen? "+ mHRData.isChOpen);}
		
		mHRData.mHRMStatusCol = RED;
    	mHRData.mHRMStatus = "Found strap";
        // may need some other changes
    }
    
	// Close Ant channel.
    function closeCh() {
    	// release dumps whole config
    	if(mHRData.isChOpen) {
    		//GenericChannel.release();
    		//if (mDebuggingANT == true) {Sys.println("CloseCh(): closing open channel");}
    		if (mSensorType) { sensor.GenericChannel.close();}
    	}
    	mHRData.isChOpen = false;
		mHRData.mHRMStatusCol = RED;
    	mHRData.mHRMStatus = "HRM closed";
	    mHRData.livePulse = 0;
		mSearching = true;
		
		// update Test controller data  
    	if (mFunc != null) {
    		// no message and not ready
    		mFunc.invoke(:Update, [ "Closing channel", false, false]);
    	}
    } 
}

class AntHandler extends Ant.GenericChannel {  
    const DEVICE_TYPE = 120;  //strap
	const PERIOD = 8070; // 4x per second	
	hidden var mChanAssign;
	hidden var deviceCfg;
	hidden var mMessageCount=0;
	hidden var mHRDataLnk;
	
    function initialize(mAntID, mHRData) {
    	mHRDataLnk = mHRData;
    	 
        // Get the channel
        mChanAssign = new Ant.ChannelAssignment(
            //Ant.CHANNEL_TYPE_RX_NOT_TX,
            Ant.CHANNEL_TYPE_RX_ONLY,
            Ant.NETWORK_PLUS);
            		
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
       	GenericChannel.initialize(method(:onAntMsg), mChanAssign);
       	GenericChannel.setDeviceConfig(deviceCfg);
       	mHRDataLnk.isChOpen = GenericChannel.open();
       	
		// will now be searching for strap after openCh()
		Sys.println("ANT initialised");
	}	
	
	function stopExtSensor() {
		Sys.println("Stopping external sensors");
    	GenericChannel.close();
    	GenericChannel.release();
	}

    function onAntMsg(msg)
    {
		var payload = msg.getPayload();		
		if (mDebuggingANT == true) {
	        //Sys.println("device ID = " + msg.deviceNumber);
			//Sys.println("deviceType = " + msg.deviceType);
			//Sys.println("transmissionType= " + msg.transmissionType);
			//Sys.println("getPayload = " + msg.getPayload());
			//Sys.println("messageId = " + msg.messageId);	
			Sys.println("A - "+mMessageCount);
			mMessageCount++;
		}
		
        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId  ) {
        	if ($._mApp.mSensor.mSearching) {
                $._mApp.mSensor.mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
			// not sure this handles all page types and 65th special page correctly
    		      
            mHRDataLnk.livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();
	
			if (mDebuggingANT == true) {
				Sys.println("ANT: Pulse is :" + mHRDataLnk.livePulse);
				Sys.println("beatEvent is :" + beatEvent);
				Sys.println("beatCount is :" + beatCount);
			}
						
			newHRSampleProcessing(beatCount, beatEvent);
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
        	if (mDebuggingANT) {
        		//Sys.println("ANT EVENT msg");
        	}
       		if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
	            var event = (payload[1] & 0xFF);	            
	            switch( event) {
	            	case Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
	            		//if (mDebuggingANT) {Sys.println("ANT:EVENT: closed");}
	            		openCh();
	            		break;
	            	case Ant.MSG_CODE_EVENT_RX_FAIL:
						//mHRDataLnk.isStrapRx = false;
						//HRDataLnk.isPulseRx = false;
						mHRDataLnk.mHRMStatusCol = RED;
    					mHRDataLnk.mHRMStatus = "Lost strap";
	    				mHRDataLnk.livePulse = 0;
						$._mApp.mSensor.mSearching = true;
						// update Test controller data  
    					if ($._mApp.mSensor.mFunc != null) {
							// no message and not ready, no state change
							$._mApp.mSensor.mFunc.invoke(:Update, [ "RX fail", false, false]);
						}
						// wait for another message?
						//Sys.println( "RX_FAIL in AntHandler");
						break;
					case Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
						//Sys.println( "ANT:RX_FAIL, search/wait");
						$._mApp.mSensor.mSearching = true;	
						break;
					case Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT:
						//Sys.println( "ANT: EVENT timeout");
						////closeCh();
						////openCh();
						break;
	            	default:
	            		// channel response
	            		//Sys.println( "ANT:EVENT: default");
	            		break;
	    		} 
        	} else {
        		//Sys.println("Not an RF EVENT");
        	} 
        } else {
    		//other message!
    		//Sys.println( "ANT other message " + msg.messageId);
    	}
    }
    
	function newHRSampleProcessing(beatCount, beatEvent) {
		if (mDebuggingANT) {Sys.println("HR-SP");}
	
		// check we have a pulse and another beat recorded 
		if(mHRDataLnk.mPrevBeatCount != beatCount && 0 < mHRDataLnk.livePulse) {
			//mHRDataLnk.isPulseRx = true;
			mHRDataLnk.mHRMStatusCol = GREEN;
			mHRDataLnk.mHRMStatus = "HR data";
			mHRDataLnk.mNoPulseCount = 0;
			
			// update Test controller data  
			if ($._mApp.mSensor.mFunc != null) {
				// no message and not ready, no state change
				$._mApp.mSensor.mFunc.invoke(:Update, [ "HR data incoming", true, false]);
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
			var beatsInGap = beatCount - mHRDataLnk.mPrevBeatCount;	
			var isTesting = false;
			if ( $._mApp.mTestControl.mTestState == TS_TESTING) {isTesting = true;}	
			$._mApp.mSampleProc.rawSampleProcessing(isTesting, mHRDataLnk.livePulse, intMs, beatsInGap );
		} else {
			// either no longer have a pulse or Count not changing
			mHRDataLnk.mNoPulseCount += 1;
			if(0 < mHRDataLnk.livePulse) {
				var limit = 1 + 60000 / mHRDataLnk.livePulse / 246; // 246 = 4.06 KHz
				if(limit < mHRDataLnk.mNoPulseCount) {
					mHRDataLnk.mHRMStatusCol = RED;
    				mHRDataLnk.mHRMStatus = "Lost Pulse";
    				// update Test controller data  
					if ($._mApp.mSensor.mFunc != null) {
						// no message and not ready, see if reacquire
						$._mApp.mSensor.mFunc.invoke(:Update, [ "Lost pulse", false, false]);
					}
				}
			}
		}
		mHRDataLnk.mPrevBeatCount = beatCount;
		mHRDataLnk.mPrevBeatEvent = beatEvent;
		//Sys.println("HRSampleProcessing - end");
	}
}

class InternalSensor { 
	hidden var mHRDataLnk;
	 
	function initialize(mHR) { 
		mHRDataLnk = mHR; 
		SensorSetup();
	}
	
	function stopIntSensor() {
		Sys.println("Stopping internal sensors");
		// suspicion that having no sensors kills optical after testing until long timeout
		//Sensor.setEnabledSensors( [] );
		Sensor.unregisterSensorDataListener( );
	}
	
	// lets see if we can use sensor Toybox to get RR from both optical and ANT+
	// 3.0.0 on feature
	function SensorSetup() {
		var options = {
			:period => 1, 	// 1 second data packets
			:heartBeatIntervals => {:enabled => true}
		};
		Sensor.setEnabledSensors( [Sensor.SENSOR_HEARTRATE]);
		Sensor.registerSensorDataListener(self.method(:onHeartRateData), options);	
		
		Sys.println("Internal SensorSetup() ... mHRDataLnk :"+mHRDataLnk);
		
		mHRDataLnk.isChOpen = true;
		$._mApp.mSensor.mSearching = false;
	    
    	// update Test controller data  
		if ($._mApp.mSensor.mFunc != null) {
			// no message and not ready, no state change
			$._mApp.mSensor.mFunc.invoke(:Update, [ "Sensor setup", false, false]);
		}
	}
	
	// call back for HR data
	function onHeartRateData( sensorData) {
		var mSize = 0; 
		var heartBeatIntervals = [];
	
		//Sys.println("sensorData "+sensorData);
		
		if (sensorData has :heartRateData && sensorData.heartRateData != null) {
			heartBeatIntervals = sensorData.heartRateData.heartBeatIntervals;
			
			var sensorInfo = Sensor.getInfo();
			if (sensorInfo == null || sensorInfo.heartRate == null) {
				// flag no data and 
				mHRDataLnk.livePulse = 0;
				mHRDataLnk.mHRMStatusCol = RED;
				mHRDataLnk.mHRMStatus = "Lost Pulse";
				// update Test controller data  
				if ($._mApp.mSensor.mFunc != null) {
					$._mApp.mSensor.mFunc.invoke(:Update, [ mHRDataLnk.mHRMStatus, false, false]);
				}
			} else {
				mHRDataLnk.livePulse = sensorInfo.heartRate;
				mHRDataLnk.mHRMStatusCol = GREEN;
				mHRDataLnk.mHRMStatus = "HR data";
				// update Test controller data  
				if ($._mApp.mSensor.mFunc != null) {
					$._mApp.mSensor.mFunc.invoke(:Update, [ mHRDataLnk.mHRMStatus, true, false]);
				}
			}
		}	
		
		// now feed machine...
		//Sys.println("heartBeatIntervals.size() "+heartBeatIntervals.size());
		var isTesting = false;
		if ( $._mApp.mTestControl.mTestState == TS_TESTING) {isTesting = true;}	
		for ( var i=0; i< heartBeatIntervals.size(); i++) {
			var intMs = heartBeatIntervals[i];
			$._mApp.mSampleProc.rawSampleProcessing(isTesting, mHRDataLnk.livePulse, intMs, 1 );
		}	
						
		//Sys.println("Internal: live "+ mHRDataLnk.livePulse+" intervals "+heartBeatIntervals);
	} 
} 