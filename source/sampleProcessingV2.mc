using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Math;
using Toybox.Lang as Lang;



// add here functions to post process HR data once we have it!
// This should contain all the data collection and stats generation
// sample data etc is kept in Storage and properties class

// Measurements possible

//SDNN, the standard deviation of NN intervals. Often calculated over a 24-hour period. 
//SDANN, the standard deviation of the average NN intervals calculated over short periods, usually 5 minutes. 
//	SDNN is therefore a measure of changes in heart rate due to cycles longer than 5 minutes. 
//	SDNN reflects all the cyclic components responsible for variability in the period of recording, therefore it 
//	represents total variability.
// SDNN can be measured over shorter time intervals but assumes abnormal beats have been removed. RR measure = NN with abnormal peaks removed
//RMSSD ("root mean square of successive differences"), the square root of the mean of the squares of the successive 
//	differences between adjacent NNs.
//SDSD ("standard deviation of successive differences"), the standard deviation of the successive differences between adjacent NNs.[36]
//NN50, the number of pairs of successive NNs that differ by more than 50 ms.
//pNN50, the proportion of NN50 divided by total number of NNs.
//NN20, the number of pairs of successive NNs that differ by more than 20 ms.
//pNN20, the proportion of NN20 divided by total number of NNs.

// Note geometric patterns need 20m-24hrs!

//Frequency domain methods assign bands of frequency and then count the number of NN intervals that match each band. 
//The bands are typically high frequency (HF) from 0.15 to 0.4 Hz, low frequency (LF) from 0.04 to 0.15 Hz, and the 
//very low frequency (VLF) from 0.0033 to 0.04 Hz.

// Analysis has shown that the LS periodogram can produce a more accurate estimate of the PSD than FFT methods for typical RR data. 
//Since the RR data is an unevenly sampled data, another advantage of the LS method is that in contrast to FFT-based methods it is 
//able to be used without the need to resample and detrend the RR data.

// https://en.wikipedia.org/wiki/Standard_deviation
//The following two formulas can represent a running (repeatedly updated) standard deviation. 
//A set of two power sums s1 and s2 are computed over a set of N values of x, denoted as x1, ..., xN:

//s(j)=sum [k=1 to N] (x(k)^j)

//Given the results of these running summations, the values N, s1, s2 can be used at any time to compute the 
//current value of the running standard deviation:

//sigma = sqrt (N*s(2)-s(1)^2)/N
//Where N, as mentioned above, is the size of the set of values (or can also be regarded as s0).

//Similarly for sample standard deviation,

//s= sqrt ((N*s(2)-s(1)^2) / (N*(N-1)) ).
//In a computer implementation, as the three s(j) sums become large, we need to consider round-off error, 
//arithmetic overflow, and arithmetic underflow. The method below calculates the running sums method with
// reduced rounding errors. This is a "one pass" algorithm for calculating variance of n samples without the 
//need to store prior data during the calculation. Applying this method to a time series will result in 
//successive values of standard deviation corresponding to n data points as n grows larger with each new sample, 
//rather than a constant-width sliding window calculation.

//For k = 1, ..., n:

// A(0)=0
// A(k)=A(k-1)+ (x(k)-A(k-1))/k
//where A is the mean value.

// Q(0)=0
// Q(k)=Q(k-1)+ (k-1)/k*(x(k)-A(k-1))^2 = Q(k-1)+( x(k)-A(k-1) )( x(k)-A(k) )
// Q(1)=0 since k-1=0 or x(1) = A(1)

// Sample variance:
//	s(n)^2 = Q(n)/(n-1)

//Population variance:
//	sigma(n)^2 = Q(n)/n

// RMSSD = sqrt( sum squares: (NN(i)-NN(i-1))^2 / Number of samples)

// 0.5.0
// Added new implementation of L,S,E saving and some code optimisations


// 0.4.7
// Need to pick what Upper and lower delta thresholds to choose: UpperThreshold ( II has gone longer) and LowerThreshold (II gone shorter)
// Thresholds are % values compared to running average to accommodate changing base heart rate. Absolute number is not relative to that beat
// For user define in terms of tightness
// [Very tight, tight, nominal, loose, very loose] matches [ ... ] set of % variances allowed
// use enum or dictionary?

// Need to update Count of Lower and Upper threshold exceeded

// Status bits
//   Use two integers as bit fields bit[0] = current, bit[1] = previous
//   bit = 0 means OK, bit = 1 means LONG (over upperthreshold) or SHORT (below lower threshold) depending on variable
// status combinations and action
// OK, OK -> add latest sample to stats
// OK S -> wait
// OK L -> wait
// L S -> inc ectopic, missed beat
// L L -> inc, heart slowing down?
// S L -> inc, double beat, no stats update, no avg update
// S S -> inc, ??? maybe change of rate up
// S, OK or L, OK then add both samples to stats but inc respective counters

// Init
//	Setup thresholds being used setup (settings need a pick list), status all OK
//	StartThresholding = false

// Sample #n arrived
// If n=0 then as now
// if n < filter length
//		status  = oK for current sample
//		add sample
//		update stats and rtn
// if n >= filter length AND not (StartThresholding)
//		StartThresholding = true
//		Add sample
//		Work out average of previous 5 samples
// else
// 		Add sample??
//		Test against threshold
//		Set status of sample
//		check this and last sample against status combinations and take action
//		if not OK then rtn else ???

// last two sample values should be in buffer
// need to increment counts of ectopic beats

(:sampProcV2)
class SampleProcessing {

	// these need to be moved from ANThandler and references changed
	hidden var devMs;
	hidden var devSqSum;
	hidden var pulseSum;
	
	hidden var mSDNN_param = [0, 0.0, 0.0, 0.0, 0.0];
	hidden var mSDSD_param = [0, 0.0, 0.0, 0.0, 0.0];
	
	hidden var mStartThreshold = false;
	//hidden var gg; //$._ mApp to make global more local!
	
	var dataCount;
	var avgPulse;
	var minIntervalFound;
	var maxIntervalFound;
	var minDiffFound;
	var maxDiffFound;
	var mRMSSD;
	var mLnRMSSD;
	var mSDNN;
	var mSDSD; 
	var mNN50;
	var mpNN50; 
	var mNN20;
	var mpNN20;
	
	//0.5.0
	// add stats on deviation so can be tuned!! Difference from AVG
	var mpLongMax; // % by which long
	var mpShortMax; // % by which short
	var mLongMax; // ms by which long
	var mShortMax; // ms by which short	
	
	// 0.4.6 variables for ectopic beats
	var vLongBeatCnt;
	var vShortBeatCnt;
	var vEBeatCnt;
	//var vRunningAvg;
	// use a set of 3 bits to record when events happened which is cleared on FIT compute
	var vEBeatFlag;
	
	// keep a record of averages calculated in shifting buffer
	var aAvgStore = new [MAX_NUMBERBEATSGRAPH];
	// associated value of II to make beat graph simpler
	// NOTE need to write current avg into this buffer when ectopic and not update avg
	var aIIValue = new [MAX_NUMBERBEATSGRAPH];
	//var aAvgStoreIndex;
	
	// index always points to next available slot to save new entries
	hidden var mSampleIndex;
	hidden var mSampleProc;
	hidden var mFILTER_D = 4;
	
	function initialize() {
		// do we keep big buffer of intervals here?
		// for moment define it in global space as need to use it in views
		// if we make a circular buffer then will need to make lots of calls to get data
		$.mIntervalSampleBuffer = new [MAX_BPM * MAX_TIME];
		clearAvgBuffer();		
		resetSampleBuffer();
		resetHRVData();
		
		Sys.println("ln(rMSSD) scale factor is "+$.mLogScale);
	}
	
	function resetSampleBuffer() { 
		mSampleIndex = 0;
		mSampleProc = 0; // delayed version of above
		$.mIntervalSampleBuffer[0] = 0;
		clearAvgBuffer();
		mStartThreshold = false;
		minIntervalFound = 2000; // around 30 BPM
		maxIntervalFound = 0;
		mpLongMax = 0.0;
		mpShortMax = 0.0; 
		mLongMax = 0; 
		mShortMax = 0;
	}
	
	function resetHRVData() {
		resetSampleBuffer();
		clearAvgBuffer();
		minDiffFound = 2000;
		maxDiffFound = 0;
		devMs = 0;
		devSqSum = 0.0;
		pulseSum = 0;
		dataCount = 0;	
		avgPulse = 0;
		mRMSSD = 0.0;
		mLnRMSSD = 0.0;	
		mSDNN = 0.0;
		mSDSD = 0.0; 
		mNN50 = 0;
		mpNN50 = 0.0; 
		mNN20 = 0;
		mpNN20 = 0.0;
		mSDNN_param = [0, 0.0, 0.0, 0.0, 0.0];
		mSDSD_param = [0, 0.0, 0.0, 0.0, 0.0];
		vLongBeatCnt = 0;
		vShortBeatCnt = 0;
		vEBeatCnt = 0;
		//vRunningAvg = 0.0;
		vEBeatFlag = 0;

	}
	
	function clearAvgBuffer() {
		var length = aAvgStore.size();
		
		for (var i = 0; i < length; i++) {
			aAvgStore[i] = 0.0;
			aIIValue[i] = 0;	
		}			
	}
	
	function getNumberOfSamples() {
		// starts at zero
		//return mSampleIndex;
		return mSampleProc;
	}
	
	function setNumberOfSamples(index) {
		mSampleIndex = index+mFILTER_D; // writing ahead of processing
		mSampleProc = index;
	}
	
	function getCurrentEntry() {
		var index;
		index = getNumberOfSamples();
		if (index == 0) {
			return [0, SAMP_OK];
		} else {
			return getSample(index-1);
		}
	}
	
	function addSample( intervalMs, beatsInGap ) { //, mFlag) {
		// input is an interval time in ms
		// mFlag is status of interval
		
		// pre process bounds for poincare plot of RR interval
		// first sample will have null beatsInGap so ignore as 
		if (beatsInGap != null ) {
			if (intervalMs > maxIntervalFound) { maxIntervalFound = intervalMs;}
			else if (intervalMs < minIntervalFound) { minIntervalFound = intervalMs;}
		}
		
		// 0.7.1 
		// if buffer overflows return true and stop accepting
		if ( mSampleIndex >= $.mIntervalSampleBuffer.size()-1) { 
			//Sys.println("Sample Buffer full");
			return true;
		}
		
		// Might want to implement circular buffer to avoid this...
		// also can notify testControl to stop testing
		//if ( mSampleIndex > $.mIntervalSampleBuffer.size()-1) {
		//	throw new $.myException("Buffer limit reached in sample Processing");
		//}
				
		$.mIntervalSampleBuffer[mSampleIndex] = intervalMs; // | (mFlag << 12);	
		mSampleIndex++;	
		// may need more input to clean up the signal eg if beatCount gap larger than 1		
		//Sys.println("Sample count: "+mSampleIndex);
	}
	
	// updates flag at mSampleProc and increments pointer
	function addFlagProc( mFlag) {
		$.mIntervalSampleBuffer[mSampleProc] |= (mFlag << 12);	
		mSampleProc++;
	}
	
	function getSample(index) {
		var mSamp = $.mIntervalSampleBuffer[index];
		var mFlag = (mSamp) >> 12 & 0xF;
		mSamp = mSamp & 0x0FFF;		
		return [mSamp, mFlag];
	}
	
	// move buffers to right so slot 0 free for new entry
	function shiftAvgBuffer() {
		var length = aAvgStore.size();
		for (var i = length-1; i > 0; i--) {
			aAvgStore[i] = aAvgStore[i-1];
			aIIValue[i] = aIIValue[i-1];	
		}			
	}	
	
(:TestVersion)
	function addAverage( mAvg, mSample) {
		// Might choose to add complexity to this depending how ectopic algo works out
		shiftAvgBuffer();
		aAvgStore[0] =	mAvg;
		aIIValue[0] = mSample;
		$.mTestAvgBuffer[$.mTestBufferIndex] = mAvg;
		$.mTestBufferIndex++;		
		//Sys.println("addAverage(test) :"+mAvg);
	}
	
(:notTestVersion)
	function addAverage( mAvg, mSample) {
		// Might choose to add complexity to this depending how ectopic algo works out
		shiftAvgBuffer();
		aAvgStore[0] = mAvg;
		aIIValue[0] = mSample;
		//Sys.println("addAverage(not test) :"+mAvg);
	}

    // Work out for each sample what the average value of previous 5 points is
	// function to return average of N samples from buffer starting at current sample
	// Need to skip ectopic beats in past and if we run out of buffer do best we can!
	// Would need two episodes in last 10 beats to fail
	// returns float
	
	// USE aAVGStore. See if modify AddAverage to replicate if this handled ectopic beats (by just adding unadjusted average
	// would have to use differential average then avg(n) = (a0+ ...+a4)/5 = avg(n-1) + (a5-a0)/5
	// a0 calculated after 5 samples
	
	// Actual imp. Works out which 5 samples to use by looking at all samples as we don't know which are L/S/E
	
	// More optimal IMP We have a known running average which only has good known beats in it
	// mNumSamples points to next free slot, this intMs (sampleIn) would go in there
	// mRAvg is current running average before this sample is added
	// use differential average then avg(n) = (a0+ ...+a4)/5 = avg(n-1) + (a5-a0)/5
	// we need to look back through buffer finding II(n-x) where x gives us the 5th non ectopic sample
	// II(mNumSamples-1) = a(1) if not ectopic etc. Find a(5)
	// a(0) = sampleIn
	// keep samples found just in case less than 5 which is filter length 
	
	// may have to change to use S, OK; L, OK ie brief fluctuation 
(:discard)	
    function fCalcAvgValues( mRAvg, sampleIn, mNumSamples) {  
    	var mIIVal = new [5]; // found II sample for samples average 
    	var mFoundCount = 0;
    	// Assume we have shifted bits already before average called.
    	var newAvg = 0.0;
    	var mFound = false;
    	
    	//Sys.println("fCalcAvgValues: called with Avg"+mRAvg+", sampleIn "+sampleIn+", mNumSamples "+mNumSamples);
    	
    	// for case when we find insufficient data
    	mIIVal[0] = sampleIn;
    	
    	// Limited to bottom of buffer
    	// All we need to do is from mNumberSamples -1 look for II's that are not flagged going back in time
    	// however as this range might include ectopci beats need to skip those
    	var i = mNumSamples-1;
    	while (!mFound && i >= 0 ) {
    		if ( ($.mIntervalSampleBuffer[i]) & 0xF000 !=0 ) {
    			// bad entry so need to move on further back
    			//Sys.println("fCalcAvgValues: skip sample # :"+i+", mFlagOffset: "+mFlagOffset);
    			i--;    		
    		} else {
    			// Good sample	
    			mFoundCount++;
    			mIIVal[mFoundCount] = $.mIntervalSampleBuffer[i] & 0x0FFF;
    			
    			//Sys.println("fCalcAvgValues: Add sample: "+i+", mFoundCount: "+mFoundCount+", mIIVal[]:"+mIIVal);
    			
    			i--;
    		}
    		if (mFoundCount == 4) {
    			mFound = true;   		
    		}    	
    	}   	
    	
    	// work out new avg
    	var sum = 0;
     	if (mFoundCount == 0) {
    			newAvg = sampleIn;
    	}    	
    	else {
    		// average samples we have
    		for (i = 0; i <= mFoundCount; i++) {
    			sum += mIIVal[i];
    		}
    		newAvg = sum.toFloat() / (mFoundCount+1);   	
    	}
    	
    	//Sys.println("fCalcAvgValues: samples found = "+mIIVal+" sum = "+sum+", new avg = "+newAvg);
    	
    	mIIVal = null;
    	return newAvg;
    	
    } // end function fCalcAvgValues()

(:discard)
	function fNormalCase( _vAvg, _previousIntMs, _intMs, _livePulse, _mFlag) {
		// add sample to II and stats, update running avg add this and II to avg buffers		
		// flag corresponds to _mSampleProc value	
		addFlagProc( _mFlag); 				
		// add and shift avg buffer and II store
		//addAverage( _vAvg, _intMs); // done in mainline now as always update
		// Update stats!
		updateRunningStats( _previousIntMs, _intMs, _livePulse);
		
		return; 	
	}
	
	// filter of length 7 around _mSampleProc including latest intMs
	function mFilter7( _mSampleProc, _intMs) {
		//var i = _mSampleProc - 3;
		var mSum = 0;
		var mII;
		for (var j = _mSampleProc - 3; j < _mSampleProc + 3; j++) {
			// clear flag just in case
			mII = getSample(j);
			mSum += mII[0] & 0x0FFF;
			//i++;		
		}
		mSum += _intMs;
		return  mSum.toFloat() / 7.0;
	}
			
	function rawSampleProcessing (isTesting, livePulse, intMs, beatsInGap ) {
		//Sys.println("v0.5.5 rawSampleProcessing called. mSampleIndex is = "+mSampleIndex);
		var newAvg;

		//$.DebugMsg( true, "["+livePulse+","+intMs+","+beatsInGap+"]");
		
		// Only update hrv data if testing started, & values look to be error free	
		if ((!isTesting) || (livePulse == 0) || (beatsInGap == null)) {
			// Don't capture data if not testing OR
			// livePulse== 0 could happen on first loop - avoids divide by 0
			// If we still have an interval could create BPM from that...
			// Sys.println("rawSampleProcessing(): livePulse 0 - discarding");
			return;
		}
						
		// Given ANT sensor only provides one interval then we should probably ignore this sample
		if (beatsInGap != 1) {$.DebugMsg( true, "C-"+mSampleIndex+"B:"+beatsInGap+" t:"+intMs);}
				
		// Sample #n arrived
		
		// Calculate estimated ranges for reliable data based on current pulse
		// Set special mode to ignore
		var maxMs;
		var minMs;
		if ( $.mTestMode) {	
			maxMs = 3000; // 20 bpm :-)
			minMs = 200;  // 300 bpm
		} else {			
			maxMs = 60000 / (livePulse * 0.7);
			minMs = 60000 / (livePulse * 1.4);
		}
		
		// Put sample in buffer with average of samples available. We know top bits clear until we reach enough to start processing
		// Start incrementing processing pointer when mSampleIndex >= FILTER_D (post index increment)
		// when pointer free slot on input = 7 ie sample 6
		// when pointer free slot on input >= 7 ie sample 6 is current one ... 0, 1, 2, 3, 4, 5, 6, 7 then we can start processing
		// ... Calculate average around middle one of filter ie sample mSampleIndex-FILTER_D or mSampleProc
		// ... Threshold and set flag
		// ... Compare this and previous one for flag setting 
	
		// special case of 1st sample as previous will be zero!
		// make sure not stupid number
		if (mSampleIndex == 0) {
			if ( maxMs > intMs && minMs < intMs) { 				
				addSample(intMs, 1); // increments mSampleIndex, was null but want to use for min max
			}
			return;
		}
		
		// Setup the first few averages which are ignored
		//if (mSampleIndex < mFILTER_D) {
		//		vRunningAvg += intMs;
		//		addAverage( vRunningAvg / (mSampleIndex+1), intMs);	
		//}
		
		// always add sample - come here from sample 2 onwards 
		//addSample(intMs, 1, SAMP_OK); // increments mSampleIndex
		
		// For first 6 samples just update stats and add sample (write of 5th makes ptr = 6)
		// filter length = 7 
		if (mSampleIndex < 6 ) {
			if ( maxMs > intMs && minMs < intMs) { 
				// getSample returns [Interval, flag]
				var previousIntMs = getSample(mSampleIndex-1);		
				// add sample and inc pointer!!	Flag = 0 		
				addSample(intMs, 1); 
				// No need to update vLower and vUpper flags as not testing and 0 = OK
				// Stats only updated when we have done sample testing!!
				if (mSampleIndex < 3) {
					updateRunningStats(previousIntMs[0], intMs, livePulse);
				}		
			}
			return;
		}
		
		// special sample as we now have enough data to start processing
		if (mSampleIndex == 6 ) {		
			mSampleProc = 3; // as length 7 filter
			
			// complete first 3 samples average
			var mSP0 = getSample(0);
			var mSP1 = getSample(1);
			var mSP2 = getSample(2);
			addAverage( mSP0[0], mSP0[0]);
			addAverage( (mSP0[0]+mSP1[0])/2, mSP1[0]);
			addAverage( (mSP0[0]+mSP1[0]+mSP2[0])/3, mSP2[0]);
		}
		
		if ( maxMs > intMs && minMs < intMs) { 				
			// Now main handling of samples
			newAvg = mFilter7( mSampleProc, intMs);
			// always add sample to II buffer
			//0.7.1 if buffer overflows then abort new samples
			if ( addSample(intMs, 1) ) { return; } // buffer overrun
		} else {
			Sys.println(" Sample out of nominal range: "+intMs+" at index:"+mSampleIndex+" with pulse:"+livePulse);
			return;		
		}
		
		// look back at previous samples to process	
		var previousIntMs = getSample(mSampleProc-1);
		var currentIntMs = getSample(mSampleProc);
				
		// add and shift avg buffer and II store
		addAverage( newAvg, currentIntMs[0]);	
				
		// Now we can threshold
		// what type is current sample?
		var c_mFlag = SAMP_OK;
		
		// test against over threshold. Note these are % but factional ie < 1
		// Could do x100 here
				
		var mDiff = (currentIntMs[0].toFloat() - newAvg);
		if (mDiff > mLongMax) { mLongMax = mDiff;}
		
		if (mDiff < 0 && mDiff.abs() > mShortMax) { mShortMax = mDiff.abs();}
		
		var mDelta = mDiff / newAvg;
		if (mDelta >= 0) {
			if (mDelta >= $.vUpperThresholdSet) {	c_mFlag = SAMP_L; }
			if (mDelta > mpLongMax ) { mpLongMax = mDelta;}					
		} 
		else {
			var mDa = mDelta.abs();
			if (mDa >= $.vLowerThresholdSet) { c_mFlag = SAMP_S;}
			if (mDa > mpShortMax ) { mpShortMax = mDa;}				
		}
		
		//Sys.println("SampleProc: "+mSampleProc+", mDiff="+mDiff+", mDelta (frac)="+mDelta);
		
		// need to remember to update flag and do stats if needed 
		//Sys.println("SampleProc: "+mSampleProc+", delta %, L : "+mpLongMax+", "+mLongMax+": %,S : "+mpShortMax+", "+mShortMax); 
			
		// status combinations and action
		// OK, OK -> add latest sample to stats
		// OK S -> wait
		// OK L -> wait
		// L S -> inc ectopic, missed beat
		// L L -> inc, heart slowing down?
		// S L -> inc, double beat
		// S S -> inc, ??? maybe change of rate up	
		//Sys.println("SampleProc: Sample# "+mSampleIndex+", mDelta :"+format("$1$%",[(100*mDelta).format("%d")])+
		//	" flags old and new: "+previousIntMs[1]+", "+c_mFlag+" avg="+vRunningAvg);
		
		var mFlagToSet = SAMP_OK;
		
		// We can have SL, LS as a previous flag state. 0.5.5 missed this rare event and caught in error message
		
		switch (previousIntMs[1]) {
			case SAMP_OK:
				if (c_mFlag == SAMP_OK) {
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);
				} 
				else if (c_mFlag == SAMP_S) {
					vShortBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x1;
					//Sys.println("SampleProcessing: SHORT BEAT FOUND");	
					// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
					mFlagToSet = c_mFlag; //SAMP_S; 			
				}
				else if (c_mFlag == SAMP_L) {
					vLongBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x2;
					//Sys.println("SampleProcessing: LONG BEAT FOUND");	
					// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
					mFlagToSet = c_mFlag; //SAMP_L;									
				}			
			break;
			case SAMP_L:
				if (c_mFlag == SAMP_OK) {
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);
				} 
				else if (c_mFlag == SAMP_S) {
					vShortBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x5;
					// inc missed beat, no stats update, save current avg and II to avgstore
					mFlagToSet = SAMP_SL;
					vEBeatCnt++;	
					//Sys.println("SampleProcessing: SHORT and ECTOPIC BEAT FOUND");				
				}
				else if (c_mFlag == SAMP_L) { // LL maybe shouldn't update stats
					// heart rate is possibly slowing down or increasing as consecutive change in direction	
					mFlagToSet = c_mFlag;
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);									
				}				
			break;		
			case SAMP_S:
				if (c_mFlag == SAMP_OK) {
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);
				} 
				else if (c_mFlag == SAMP_S) { // SS maybe shouldn't update stats
					// heart rate is possibly slowing down or increasing as consecutive change in direction	
					mFlagToSet = c_mFlag;
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);					
				}
				else if (c_mFlag == SAMP_L) {
					vLongBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x6;
					// inc missed beat, no stats update, save current avg and II to avgstore
					mFlagToSet = SAMP_LS;
					vEBeatCnt++;						
					//Sys.println("SampleProcessing: Long and ECTOPIC BEAT FOUND");								
				}				
			break;		
			case SAMP_LS: // short followed by long previously
			case SAMP_SL: // long followed by short
				// not sure how to handle sequence of 3 samples over thresholds
				if (c_mFlag == SAMP_OK) {				
					updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);		
				} else if (c_mFlag == SAMP_L) {
					vLongBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x6;				
				} else {
					vShortBeatCnt++;
					vEBeatFlag = vEBeatFlag | 0x5;				
				}
				mFlagToSet = c_mFlag;			
			break;
			default:
				Sys.println("SP:UBC--flags P:"+previousIntMs[1]+" C:"+c_mFlag);
			break;
		} // end switch previous		
		
		// set flag and inc ptr
		addFlagProc(mFlagToSet);
	
		// end thresholding process
			
		//Sys.println("Sample end: new avgStore: "+aAvgStore+" aIIValue = "+aIIValue);

	// end new rawSampleProcessing
	}	

(:discard)
	function dummy() {
		// OLD CODE OLD CODE	 
					
		if 	( (c_mFlag == SAMP_OK) && 
				(
			    	( previousIntMs[1] == SAMP_OK ) || ( previousIntMs[1] == SAMP_L ) || ( previousIntMs[1] == SAMP_S ) 
			  	)    
			) {
			updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);
		} 
		else if ( previousIntMs[1] == SAMP_OK && c_mFlag == SAMP_S) {
			vShortBeatCnt++;
			vEBeatFlag = vEBeatFlag | 0x1;
			//Sys.println("SampleProcessing: SHORT BEAT FOUND");	
			// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
			mFlagToSet = SAMP_S; 
		} 
		else if ( previousIntMs[1] == SAMP_OK && c_mFlag == SAMP_L) {
			vLongBeatCnt++;
			vEBeatFlag = vEBeatFlag | 0x2;
			//Sys.println("SampleProcessing: LONG BEAT FOUND");	
			// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
			mFlagToSet = SAMP_L;		
		}
		else if ( previousIntMs[1] == SAMP_L && c_mFlag == SAMP_S) {
			vShortBeatCnt++;
			vEBeatFlag = vEBeatFlag | 0x5;
			// inc missed beat, no stats update, save current avg and II to avgstore
			mFlagToSet = SAMP_SL;
			vEBeatCnt++;	
			//Sys.println("SampleProcessing: SHORT and ECTOPIC BEAT FOUND");		
		}
		else if ( previousIntMs[1] == SAMP_S && c_mFlag == SAMP_L) {
			vLongBeatCnt++;
			vEBeatFlag = vEBeatFlag | 0x6;
			// inc missed beat, no stats update, save current avg and II to avgstore
			mFlagToSet = SAMP_LS;
			vEBeatCnt++;
				
			//Sys.println("SampleProcessing: Long and ECTOPIC BEAT FOUND");
		}
		else if ( ( previousIntMs[1] == SAMP_L && c_mFlag == SAMP_L) || 
				  ( previousIntMs[1] == SAMP_S && c_mFlag == SAMP_S) ) 	 {
			// heart rate is possibly slowing down or increasing as consecutive change in direction
			// ideally would redoo avg and stats with previous sample	
			mFlagToSet = c_mFlag;
			updateRunningStats( previousIntMs[0], currentIntMs[0], livePulse);				
		//}
		//else if ( previousIntMs[1] == SAMP_S && c_mFlag == SAMP_S)	{
		//	addSample(intMs, 1, SAMP_S); 
		//	//Sys.println("SampleProc: UNHANDLED BEAT CASE -  SS!!!!");							
		} else {
			mFlagToSet = SAMP_OK;
			// we have previous flag as LS or SL
			Sys.println("SampleProc: UNHANDLED BEAT CASE -- flags prev:"+previousIntMs[1]+" current:"+c_mFlag);
			
		}	
	}
	
	// passed an array [sample, A_k, A_k1, Q_k, Q_k1] 
	//					[0, 	1, 	   2,   3,    4]
	// must start at dataCount = 1 otherwise large offset in calc!
	function calcSD(x) {	
		var sd = 0.0;
		//var absSample = x[0].abs(); 
		// x[0] already positive
		var absSample = x[0];
		
		var cntFloat = dataCount.toFloat();
		// A(0)=0
		// A(k)=A(k-1)+ (x(k)-A(k-1))/k
		//where A is the mean value.
		// Q(0)=0
		// Q(k)=Q(k-1)+ (k-1)/k*(x(k)-A(k-1))^2 = Q(k-1) + (x(k)-A(k-1))*(x(k)-A(k))
		// Q(1)=0 since k-1=0 or x(1) = A(1)
		
		// Sample variance:
		//	s(n)^2 = Q(n)/(n-1)		
		// k = dataCount
		
		x[1] = x[2] + (absSample - x[2]) / cntFloat;
		x[3] = x[4] + (absSample - x[2]) * (absSample - x[1]);
		// A_k = A_k1 + (absSample - A_k1) / dataCount;
		// Q_k = Q_k1 + (absSample - A_k1) * (absSample - A_k);
		
		if (dataCount <= 1 ) {
			sd = 0.0;
		} else {
			//sd =  Math.sqrt( Q_k) / (dataCount - 1));
			sd =  Math.sqrt( x[3] / (cntFloat - 1));
		}
		
		// shift 
		//A_k1 = A_k;
		//Q_k1 = Q_k;
		x[2] = x[1];
		x[4] = x[3];
		
		return sd;		
	}
	
	// update the per sample stats
	function updateRunningStats(previousIntMs, intMs, livePulse) {
		// implement running equations
		// note that Math lib has stdev(data, mean) for standard deviation

		// don't need to take abs value as only being squared!
		// 0.4.4 but used elsewhere
		devMs = (intMs - previousIntMs);
		devMs = devMs.abs();

		// now see how wide the difference is between consectutive intervals
		if (devMs > maxDiffFound) { maxDiffFound = devMs;}
		if (devMs < minDiffFound) { minDiffFound = devMs;}
		
		devSqSum += devMs * devMs;
		pulseSum += livePulse;
		dataCount++;
		
		// avoid divide by 0
		if(dataCount > 1) {			
			// HRV is actually RMSSD. Use (N-1)
			mRMSSD = Math.sqrt(devSqSum.toFloat() / (dataCount - 1));
			// many people compand rmssd to a scaled range 0-100
			//0.6.5 remove toNumber
			mLnRMSSD = ($.mLogScale * (Math.ln(mRMSSD)+0.5)); //.toNumber();
			// 0.4.3
			if (mLnRMSSD < 0.0) {mLnRMSSD = 0.0;}
		}
		avgPulse = ((pulseSum.toFloat() / dataCount) + 0.5).toNumber();			
		
		mSDNN_param[0] = intMs.abs();
		mSDNN = calcSD(mSDNN_param);
		mSDSD_param[0] = devMs;
		mSDSD = calcSD(mSDSD_param); 
						
		//var str = Lang.format("Cnt, mRSSD, (A, Q, SD):, $1$, $2$, $3$, $4$, $5$, $6$, $7$, $8$",
		//	[dataCount.format("%d"), mRMSSD.format("%0.1f"), mSDNN_param[1].format("%0.2f"), mSDNN_param[3].format("%0.2f"),mSDNN.format("%0.2f"),
		//	 mSDSD_param[1].format("%0.2f"), mSDSD_param[3].format("%0.2f"), mSDSD.format("%0.2f")]);
		//$.DebugMsg( true, str);
		
		// difference more than 50ms
		// some sources say over 2 min periods, others over an hour
		// SHOULD USE DIFF
		if (devMs > 50 ) { mNN50 += 1;}
		// difference more than 20ms 
		if (devMs > 20 ) { mNN20 += 1;}
		
		// percentage scaled to 100 
		var dfp = dataCount.toFloat();			
		
		mpNN50 = (mNN50.toFloat() * 100.0) / dfp; 
		mpNN20 = (mNN20.toFloat() * 100.0) / dfp; 	
		
		//$.DebugMsg( true, "count, mNN50, mpNN50, mNN20, mpNN20: "+dataCount+","+mNN50+","+mpNN50+","+mNN20+","+mpNN20);
		//$.DebugMsg( true, "Cnt, mNN50:, "+dataCount+","+mNN50);
	}

}