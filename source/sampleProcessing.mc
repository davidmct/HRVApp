using Toybox.Application as App;
using Toybox.System as Sys;


function sampleProcessing(beatCount, beatEvent) {

	if(mPrevBeatCount != beatCount && 0 < livePulse) {
	
	isPulseRx = true;
	mNoPulseCount = 0;
	
	// Calculate estimated ranges for reliable data
	var maxMs = 60000 / (livePulse * 0.7);
	var minMs = 60000 / (livePulse * 1.4);
	
	// Get interval
	var intMs = 0;
	if(mPrevBeatEvent > beatEvent) {
		intMs = 64000 - mPrevBeatEvent + beatEvent;
	}
	else {
		intMs = beatEvent - mPrevBeatEvent;
	}
	// Only update hrv data if testing started, & values look to be error free
	if(isTesting && maxMs > intMs && minMs < intMs && maxMs > mPrevIntMs && minMs < mPrevIntMs) {
	
		var devMs = 0;
		if(intMs > mPrevIntMs) {
			devMs = intMs - mPrevIntMs;
		}
		else {
			devMs = mPrevIntMs - intMs;
		}
		devSqSum += devMs * devMs;
		pulseSum += livePulse;
		dataCount++;
	
		if(1 < dataCount) {
			var rmssd = Math.sqrt(devSqSum.toFloat() / (dataCount - 1));
			hrv = ((Math.log(rmssd, 1.0512712)) + 0.5).toNumber();
			avgPulse = ((pulseSum.toFloat() / dataCount) + 0.5).toNumber();
		}
	
		// Print live data
		//if(isTesting){
		//	var liveMs = (intMs.toFloat() / 1000);
		//	System.println(liveMs.format("%.03f"));
		//}
		}
		mPrevIntMs = intMs;
	}
	else {
		mNoPulseCount += 1;
		if(0 < livePulse) {
			var limit = 1 + 60000 / livePulse / 246; // 246 = 4.06 KHz
			if(limit < mNoPulseCount) {
				isPulseRx = false;
			}
		}
	}
	mPrevBeatCount = beatCount;
	mPrevBeatEvent = beatEvent;

}