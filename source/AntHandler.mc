using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;

class AntHandler extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;
    const PERIOD = 8070;
    
    var mApp;
    hidden var mSearching;
    hidden var mLocalAntID;
	
	function initialize(mAntID) {
    	mApp = Application.getApp();
    	mSearching = false;
    	mLocalAntID = mAntID;
    	// Get the channel
        var chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_RX_NOT_TX,
            Ant.NETWORK_PLUS);
        GenericChannel.initialize(self.method(:onAntMsg), chanAssign);

        // Set the configuration
        var deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => mLocalAntID,             //Set to 0 to use wildcard search
            :deviceType => DEVICE_TYPE,            
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,
            :searchTimeoutLowPriority => 10,
            :searchTimeoutHighPriority => 2,
            :searchThreshold => 0} );
        setDeviceConfig(deviceCfg);
		// will now be searching for strap after openCh()
    }
        
    function openCh() { 
    	closeCh();
    	mSearching = true;   	
		mApp.isChOpen = GenericChannel.open();
        // may need some other changes
    }

    function onAntMsg(msg)
    {
		var payload = msg.getPayload();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {
        	if (mSearching) {
                mSearching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
            }
			// not sure this handles all page types and 65th special page correctly
			
            mApp.isAntRx = true;
            mApp.isStrapRx = true;
            mApp.livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();

			sampleProcessing(beatCount, beatEvent);
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
       		if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
	            var event = (payload[1] & 0xFF);
	            if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == event) {
	            	openCh();
	            } 
	            else if ( Ant.MSG_CODE_EVENT_RX_FAIL == event ) {
					mApp.isStrapRx = false;
					mApp.isPulseRx = false;
					mSearching = false;
	            }
	            else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH == event ) {
					mApp.isAntRx = false;
	            }
	            else if( Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT == event ) {
					closeCh();
					openCh();
	            }
	            else {
	            	// channel response
	            }
	    	}
        }
    }
    
	// Close Ant channel.
    function closeCh() {
    	// release dumps whole config
    	if(mApp.isChOpen) {
    		//GenericChannel.release();
    		GenericChannel.close();
    	}
    	mApp.isChOpen = false;
    	mApp.isAntRx = false;
		mApp.isStrapRx = false;
		mApp.isPulseRx = false;
		mSearching = false;
    }
    

    
}