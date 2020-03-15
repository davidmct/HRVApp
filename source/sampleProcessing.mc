using Toybox.Application as App;
using Toybox.System as Sys;


function sampleProcessing(beatCount, beatEvent) {

	if(mApp.mPrevBeatCount != beatCount && 0 < mApp.livePulse) {
	
	mApp.isPulseRx = true;
	mApp.mNoPulseCount = 0;
	
	// Calculate estimated ranges for reliable data
	var maxMs = 60000 / (livePulse * 0.7);
	var minMs = 60000 / (livePulse * 1.4);
	
	// Get interval
	var intMs = 0;
	if(mApp.mPrevBeatEvent > beatEvent) {
		intMs = 64000 - mApp.mPrevBeatEvent + beatEvent;
	}
	else {
		intMs = beatEvent - mApp.mPrevBeatEvent;
	}
	// Only update hrv data if testing started, & values look to be error free
	if(mApp.isTesting && maxMs > intMs && minMs < intMs && maxMs > mApp.mPrevIntMs && minMs < mApp.mPrevIntMs) {
	
		var devMs = 0;
		if(intMs > mApp.mPrevIntMs) {
			devMs = intMs - mApp.mPrevIntMs;
		}
		else {
			devMs = mApp.mPrevIntMs - intMs;
		}
		mApp.devSqSum += devMs * devMs;
		mApp.pulseSum += mApp.livePulse;
		mApp.dataCount++;
	
		if(1 < mApp.dataCount) {
			var rmssd = Math.sqrt(mApp.devSqSum.toFloat() / (mApp.dataCount - 1));
			mApp.hrv = ((Math.log(rmssd, 1.0512712)) + 0.5).toNumber();
			mApp.avgPulse = ((mApp.pulseSum.toFloat() / mApp.dataCount) + 0.5).toNumber();
		}
	
		// Print live data
		//if(isTesting){
		//	var liveMs = (intMs.toFloat() / 1000);
		//	System.println(liveMs.format("%.03f"));
		//}
		}
		mApp.mPrevIntMs = intMs;
	}
	else {
		mApp.mNoPulseCount += 1;
		if(0 < mApp.livePulse) {
			var limit = 1 + 60000 / mApp.livePulse / 246; // 246 = 4.06 KHz
			if(limit < mApp.mNoPulseCount) {
				mApp.isPulseRx = false;
			}
		}
	}
	mApp.mPrevBeatCount = beatCount;
	mApp.mPrevBeatEvent = beatEvent;

}