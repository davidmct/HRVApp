using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as Sys;

class antHandler extends Ant.GenericChannel {
    const DEVICE_TYPE = 120;
    const PERIOD = 8070;
	
	function openCh() {
        // Get the channel
        var chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_RX_NOT_TX,
            Ant.NETWORK_PLUS);
		//try {
            //Create the sensor object and open it
        //    mSensor = new AuxHRSensor(mAntID);
        //    mSensor.open();
        //} catch(e instanceof Ant.UnableToAcquireChannelException) {
        //    System.println(e.getErrorMessage());
        //    mSensor = null;
        //}
        // Set the configuration
        var deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => mAntID,             //Set to 0 to use wildcard search
            :deviceType => DEVICE_TYPE,            
            :transmissionType => 0,
            :messagePeriod => PERIOD,
            :radioFrequency => 57,
            :searchTimeoutLowPriority => 2,
            :searchTimeoutHighPriority => 2,
            :searchThreshold => 0} );

        antCh = new Ant.GenericChannel(self.method(:onAntMsg), chanAssign);
        antCh.setDeviceConfig(deviceCfg);
		isChOpen = antCh.open();
    }

    function onAntMsg(msg)
    {
		var payload = msg.getPayload();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {

            isAntRx = true;
            isStrapRx = true;
            livePulse = payload[7].toNumber();
			var beatEvent = ((payload[4] | (payload[5] << 8)).toNumber() * 1000) / 1024;
			var beatCount = payload[6].toNumber();

			sampleProcessing(beatCount, beatEvent);
        }
        else if( Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId ) {
            var event = payload[1].toNumber();
            if( Ant.MSG_CODE_EVENT_RX_FAIL == event ) {
				isStrapRx = false;
				isPulseRx = false;
            }
            else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH == event ) {
				isAntRx = false;
            }
            else if( Ant.MSG_CODE_EVENT_RX_SEARCH_TIMEOUT == event ) {
				closeCh();
				openCh();
            }
        }
    }

	// Close Ant channel.
    function closeCh() {
    	if(isChOpen) {
    		antCh.release();
    	}
    	isChOpen = false;
    	isAntRx = false;
		isStrapRx = false;
		isPulseRx = false;
    }
    

    
}