using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;
using Toybox.Math;

class AntHandler extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;  //strap
    const PERIOD = 8070; // 4x per second
    
    var mApp;
    var mHRData;
    var deviceCfg;
    
    var mSearching;
    hidden var mChanAssign;
    //hidden var mLocalmAntID;
    //hidden var mAntCh;
    
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
		var mPrevIntMs;
		var hrv;
		var avgPulse;
		var	devSqSum;
		var	pulseSum;
		var	dataCount;
		var devMs;
		var mAntEvent;
		
    	function initialize() {
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
			mPrevIntMs = 0;	
			resetTestVariables();	
		}
		
		function resetTestVariables() {
			hrv = 0;
			avgPulse = 0;
			devSqSum = 0;
			pulseSum = 0;
			dataCount = 0;
			devMs = 0;
		} 
    }
	
	function initialize(mAntID) {
    	mApp = Application.getApp();
    	mSearching = true;
    	//mLocalmAntID = mAntID;
    	
    	mHRData = new HRStatus();
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
       	mChanAssign.setBackgroundScan(true);
       	GenericChannel.initialize(method(:onAntMsg), mChanAssign);
       	setDeviceConfig(deviceCfg);
       	mHRData.isChOpen = GenericChannel.open();
       	
		// will now be searching for strap after openCh()
		Sys.println("ANT initialised");
    }
        
    function openCh() { 
    	if (mHRData.isChOpen == true)
    	{
    		//Sys.println("OpenCh: closing open channels and reseting status");
    		//GenericChannel.close();
    	}
    	mSearching = true;   	
		mHRData.isChOpen = GenericChannel.open();
		Sys.println("openCh(): isOpen? "+ mHRData.isChOpen);
		
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
    		Sys.println("CloseCh(): closing open channel");
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
        //Sys.println("device ID = " + msg.deviceNumber);
		//Sys.println("deviceType = " + msg.deviceType);
		//Sys.println("transmissionType= " + msg.transmissionType);
		//Sys.println("getPayload = " + msg.getPayload());
		//Sys.println("messageId = " + msg.messageId);

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId  ) {
        	if (mSearching) {
                mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
			// not sure this handles all page types and 65th special page correctly
			//Sys.println("ANT DATA");			
			// added another getPayload() as in sensor code
			//payload = msg.getPayload();
            mHRData.isAntRx = true;
            mHRData.isStrapRx = true;
            mHRData.strapCol = GREEN;
            
            mHRData.livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();

			Sys.println("ANT: Pulse is :" + mHRData.livePulse);
			Sys.println("beatEvent is :" + beatEvent);
			Sys.println("beatCount is :" + beatCount);
						
			HRSampleProcessing(beatCount, beatEvent);
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
        	if (mDebugging) {
        		//Sys.println("ANT EVENT msg");
        	}
       		if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
	            var event = (payload[1] & 0xFF);	            
	            switch( event) {
	            	case Ant.MSG_CODE_EVENT_CHANNEL_CLOSED:
	            		//Sys.println("ANT:EVENT: closed");
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
    
    function HRSampleProcessing(beatCount, beatEvent) {
		//Sys.println("HRSampleProcessing");
		
		// want a test that we are testing and need samples around whole lot?
		
		if(mHRData.mPrevBeatCount != beatCount && 0 < mHRData.livePulse) {
			//Sys.println("HRSampleProcessing - step 1");
			mHRData.isPulseRx = true;
	    	mHRData.pulseCol = GREEN;
			mHRData.mNoPulseCount = 0;
			
			// Calculate estimated ranges for reliable data
			var maxMs = 60000 / (mHRData.livePulse * 0.7);
			var minMs = 60000 / (mHRData.livePulse * 1.4);
			
			// Get interval
			var intMs = 0;
			if(mHRData.mPrevBeatEvent > beatEvent) {
				intMs = 64000 - mHRData.mPrevBeatEvent + beatEvent;
			} else {
				intMs = beatEvent - mHRData.mPrevBeatEvent;
			}
			
			if (mDebugging) {
				// maybe too much data for speed");
				//Sys.println("HRSampleProcessing - step 2");
				Sys.println("HRSampleProcessing isTesting - "+ mApp.mTestControl.mState.isTesting);	
				Sys.println("HRSampleProcessing livePulse - "+mHRData.livePulse);			
				Sys.println("HRSampleProcessing maxMs - "+maxMs);
				Sys.println("HRSampleProcessing intMs - "+intMs);
				Sys.println("HRSampleProcessing minMs - "+minMs);	
				Sys.println("HRSampleProcessing PrevIntMs - "+mHRData.mPrevIntMs);	
				Sys.println("HRSampleProcessing	mNoPulseCount - "+  mHRData.mNoPulseCount);
				Sys.println("HRSampleProcessing mPrevBeatCount - "+ mHRData.mPrevBeatCount);
				Sys.println("HRSampleProcessing mPrevBeatEvent - "+ mHRData.mPrevBeatEvent);			
			} 
			
			// Only update hrv data if testing started, & values look to be error free			
			if(mApp.mTestControl.mState.isTesting && 
				maxMs > intMs && 
				minMs < intMs && 
				maxMs > mHRData.mPrevIntMs && 
				minMs < mHRData.mPrevIntMs) {		
				// test line without app testing
				//if(maxMs > intMs && minMs < intMs && maxMs > mHRData.mPrevIntMs && minMs < mHRData.mPrevIntMs) {		
				//var devMs = 0;
				if(intMs > mHRData.mPrevIntMs) {
					mHRData.devMs = intMs - mHRData.mPrevIntMs;
				} else {
					mHRData.devMs = mHRData.mPrevIntMs - intMs;
				}
				Sys.println("HRSampleProcessing - step 3");
				mHRData.devSqSum += mHRData.devMs * mHRData.devMs;
				mHRData.pulseSum += mHRData.livePulse;
				mHRData.dataCount++;
			
				if(1 < mHRData.dataCount) {
					var rmssd = Math.sqrt(mHRData.devSqSum.toFloat() / (mHRData.dataCount - 1));
					mHRData.hrv = ((Math.log(rmssd, 1.0512712)) + 0.5).toNumber();
					mHRData.avgPulse = ((mHRData.pulseSum.toFloat() / mHRData.dataCount) + 0.5).toNumber();
				}
			
				// Print live data
				//if(isTesting){
				//var liveMs = (intMs.toFloat() / 1000);
				//Sys.println(liveMs.format("%.03f"));
				//}
			}
			mHRData.mPrevIntMs = intMs;
			//Sys.println("HRSampleProcessing - step 4");
		} else {
			//Sys.println("HRSampleProcessing - step 5");
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
}