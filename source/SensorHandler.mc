using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.Math;

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

class AntHandler extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;  //strap
    const PERIOD = 8070; // 4x per second
    
    var mApp;
    var mHRData;
    var deviceCfg;
    hidden var mMessageCount=0;
    
    var mSearching;
    hidden var mChanAssign;
    
    class HRStatus {
     	var isChOpen;
		var isAntRx;
		var isStrapRx;
		var isPulseRx;
		var livePulse;
		var strapCol;
    	var pulseCol;
    	var strapTxt;
    	var pulseTxt;
		var mNoPulseCount;
		var mPrevBeatCount;
		var mPrevBeatEvent;
		
		hidden var appLnk;
		
    	function initialize(app) {
        	appLnk = app;
        	isChOpen = false;
    		isAntRx = false;
			isStrapRx = false;
			isPulseRx = false;
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
			appLnk.mSampleProc.resetHRVData();
		} 
    }
	
	function initialize(mAntID) {
    	mApp = Application.getApp();
    	mSearching = true;
  	
    	mHRData = new HRStatus(mApp);
    	// Strap & pulse indicators
    	mHRData.strapCol = RED;
    	mHRData.pulseCol = RED;
    	mHRData.strapTxt = "STRAP";
    	mHRData.pulseTxt = "PULSE";
    	
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
       	mHRData.isChOpen = GenericChannel.open();
       	
		// will now be searching for strap after openCh()
		Sys.println("ANT initialised");
    }
        
    function openCh() { 
    	// Garmin advice is release, initialize, setConfig, open!!!!
    	if (mHRData.isChOpen == true)
    	{
    		//Sys.println("OpenCh: closing open channels and reseting status");
    		//GenericChannel.close();
    	}
    	mSearching = true;   	
		mHRData.isChOpen = GenericChannel.open();
		if (mDebuggingANT == true) { Sys.println("openCh(): isOpen? "+ mHRData.isChOpen);}
		
		mHRData.strapCol = RED;
    	mHRData.pulseCol = RED;
    	mHRData.strapTxt = "STRAP";
    	mHRData.pulseTxt = "PULSE";
        // may need some other changes
    }
    
	// Close Ant channel.
    function closeCh() {
    	// release dumps whole config
    	if(mHRData.isChOpen) {
    		//GenericChannel.release();
    		if (mDebuggingANT == true) {Sys.println("CloseCh(): closing open channel");}
    		GenericChannel.close();
    	}
    	mHRData.isChOpen = false;
    	mHRData.isAntRx = false;
		mHRData.isStrapRx = false;
		mHRData.isPulseRx = false;
		mHRData.strapCol = RED;
	    mHRData.pulseCol = RED;
	    mHRData.livePulse = 0;
		mHRData.strapTxt = "SAVING";
		mHRData.pulseTxt = "BATTERY";
		mSearching = true;
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
        	if (mSearching) {
                mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
			// not sure this handles all page types and 65th special page correctly
            mHRData.isAntRx = true;
            mHRData.isStrapRx = true;
            mHRData.strapCol = GREEN;
            
            mHRData.livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();
	
			if (mDebuggingANT == true) {
				Sys.println("ANT: Pulse is :" + mHRData.livePulse);
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
						mHRData.isStrapRx = false;
						mHRData.isPulseRx = false;
						mHRData.strapCol = RED;
	    				mHRData.pulseCol = RED;
	    				mHRData.livePulse = 0;
						mSearching = true;
						// wait for another message?
						//Sys.println( "RX_FAIL in AntHandler");
						break;
					case Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH:
						//Sys.println( "ANT:RX_FAIL, search/wait");
						mSearching = true;	
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
		if(mHRData.mPrevBeatCount != beatCount && 0 < mHRData.livePulse) {
			mHRData.isPulseRx = true;
	    	mHRData.pulseCol = GREEN;
			mHRData.mNoPulseCount = 0;
					
			// Get interval
			// need to check 64000 in ANT spec for roll-over number
			var intMs = 0;
			if(mHRData.mPrevBeatEvent > beatEvent) {
				intMs = 64000 - mHRData.mPrevBeatEvent + beatEvent;
			} else {
				intMs = beatEvent - mHRData.mPrevBeatEvent;
			}
			
			//Sys.println("HR->S");
			var beatsInGap = beatCount - mHRData.mPrevBeatCount;			
			mApp.mSampleProc.rawSampleProcessing(mApp.mTestControl.mState.isTesting, mHRData.livePulse, intMs, beatsInGap );

		} else {
			// either no longer have a pulse or Count not changing
			mHRData.mNoPulseCount += 1;
			if(0 < mHRData.livePulse) {
				var limit = 1 + 60000 / mHRData.livePulse / 246; // 246 = 4.06 KHz
				if(limit < mHRData.mNoPulseCount) {
					mHRData.isPulseRx = false;
					mHRData.pulseCol = RED;
				}
			}
		}
		mHRData.mPrevBeatCount = beatCount;
		mHRData.mPrevBeatEvent = beatEvent;
		//Sys.println("HRSampleProcessing - end");
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
	}
	
	// call back for HR data
	function onHeartRateData( sensorData) {
		var mSize = 0; 
		var mlivePulse = 0;
		var heartBeatIntervals = [];
		Sys.println("sensorData "+sensorData);
		if (sensorData has :heartRateData && sensorData.heartRateData != null) {
			heartBeatIntervals = sensorData.heartRateData.heartBeatIntervals;
			// send each datum to processing here...
			
			var sensorInfo = Sensor.getInfo();
			if (sensorInfo == null || sensorInfo.heartRate == null) {
				// flag no data and 
				mlivePulse = 0;
			} else {
				mlivePulse = sensorInfo.heartRate;
			}
		}	
		
		Sys.println("optical?: live "+ mlivePulse+" intervals "+heartBeatIntervals);
	}
    
}