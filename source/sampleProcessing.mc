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

class SampleProcessing {

	// these need to be moved from ANThandler and references changed
	hidden var devMs;
	hidden var devSqSum;
	hidden var pulseSum;
	
	hidden var mSDNN_param = [0, 0.0, 0.0, 0.0, 0.0];
	hidden var mSDSD_param = [0, 0.0, 0.0, 0.0, 0.0];
	
	hidden var mStartThreshold = false;
	
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
	
	// 0.4.6 variables for ectopic beats
	var vLongBeatCnt;
	var vShortBeatCnt;
	var vEBeatCnt;
	var vRunningAvg;
	
	// keep a record of averages calculated in circular buffer
	var aAvgStore = new [MAX_NUMBERBEATSGRAPH];
	// associated value of II to make beat graph simpler
	// NOTE need to write current avg into this buffer when ectopic and not update avg
	var aIIValue = new [MAX_NUMBERBEATSGRAPH];
	//var aAvgStoreIndex;

	// bit flags for samples exceeding limits
	var vUpperFlag;
	var vLowerFlag;
	
	// index always points to next available slot
	hidden var mSampleIndex;
	
	function initialize() {
		// do we keep big buffer of intervals here?
		// for moment define it in global space as need to use it in views
		// if we make a circular buffer then will need to make lots of calls to get data
		$._mApp.mIntervalSampleBuffer = new [MAX_BPM * MAX_TIME];
		//aAvgStore = new [MAX_NUMBERBEATSGRAPH];
		//aIIValue = new [MAX_NUMBERBEATSGRAPH];
		clearAvgBuffer();		
		resetSampleBuffer();
		resetHRVData();
	}
	
	function resetSampleBuffer() { 
		mSampleIndex = 0;
		$._mApp.mIntervalSampleBuffer[0] = 0;
		clearAvgBuffer();
		mStartThreshold = false;
		minIntervalFound = 2000; // around 30 BPM
		maxIntervalFound = 0;
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
		vRunningAvg = 0.0;

		// need to be int
		vUpperFlag = 0;
		vLowerFlag = 0;
	}
	
	function clearAvgBuffer() {
		var length = aAvgStore.size();
		
		// TEST
		//var dataAvg = [900, 950, 960, 950, 900, 890, 900, 950, 925, 900];
		//var dataII =  [910, 990, 900, 1000, 980, 990, 840, 900, 925, 910];
		
		for (var i = 0; i < length; i++) {
			//aAvgStore[i] = dataAvg[i]; //0.0;
			//aIIValue[i] = dataII[i]; //0;	
			aAvgStore[i] = 0.0;
			aIIValue[i] = 0;	
		}			
	}
	
	function getNumberOfSamples() {
		// starts at zero
		return mSampleIndex;
	}
	
	function setNumberOfSamples(index) {
		mSampleIndex = index;
	}
	
	function getCurrentEntry() {
		var index;
		index = getNumberOfSamples();
		if (index == 0) {
			return 0;
		} else {
			return getSample(index-1);
		}
	}
	
	// move buffers to right so slot 0 free for new entry
	function shiftAvgBuffer() {
		var length = aAvgStore.size();
		for (var i = length-1; i > 0; i--) {
			aAvgStore[i] = aAvgStore[i-1];
			aIIValue[i] = aIIValue[i-1];	
		}			
	}	

	function addAverage( mAvg, mSample) {
		// Might choose to add complexity to this depending how ectopic algo works out
		shiftAvgBuffer();
		aAvgStore[0] =	mAvg;
		aIIValue[0] = mSample;
	}


    // Work out for each sample what the average value of previous 5 points is
(:newSampleProcessing)
	// function to return average of N samples from buffer starting at current sample
	// Need to skip ectopic beats in past and if we run out of buffer do best we can!
	// Would need two episodes in last 10 beats to fail
	// returns float
	
	// USE aAVGStore. See if modify AddAverage to replicate if this handled ectopic beats (by just adding unadjusted average
	// would have to use differential average then avg(n) = (a0+ ...+a4)/5 = avg(n-1) + (a5-a0)/5
	// a0 calculated after 5 samples
	
	// Actual imp. We have a known running average which only has good known beats in it
	// mNumSamples points to next free slot, this intMs (sampleIn) would go in there
	// mRAvg is current running average before this sample is added
	// use differential average then avg(n) = (a0+ ...+a4)/5 = avg(n-1) + (a5-a0)/5
	// we need to look back through buffer finding II(n-x) where x gives us the 5th non ectopic sample
	// II(mNumSamples-1) = a(1) if not ectopic etc. Find a(5)
	// a(0) = sampleIn
	// keep samples found just in case less than 5 which is filter length 
	
	// may have to change to use S, OK; L, OK ie brief fluctuation 
	
    function fCalcAvgValues( mRAvg, sampleIn, mNumSamples) {  
    	var mIIVal = new [5]; // found II sample for samples average 
    	var mFoundCount = 0;
    	// Assume we have shifted bits already before average called.
    	var mFlagOffset = 1; // most recent entry is low bit
    	var newAvg = 0.0;
    	var mFound = false;
    	
    	//Sys.println("fCalcAvgValues: called with Avg"+mRAvg+", sampleIn "+sampleIn+", mNumSamples "+mNumSamples);
    	
    	// for case when we find insufficient data
    	mIIVal[0] = sampleIn;
    	
    	// Limited to either bottom of buffer or 32 bits of flag
    	// All we need to do is from mNumberSamples -1 look for II's that are not flagged going back in time
    	// however as this range might include ectopci beats need to skip those
    	var i = mNumSamples-1;
    	while (!mFound && i >= 0 && mFlagOffset < 32) {
    		if ( ((1 << mFlagOffset) & vLowerFlag) or 
    		     ((1 << mFlagOffset) & vUpperFlag) ) {
    			// bad entry so need to move on further back
    			//Sys.println("fCalcAvgValues: skip sample # :"+i+", mFlagOffset: "+mFlagOffset);
    			i--;
    			mFlagOffset++;    		
    		} else {
    			// Good sample	
    			mFoundCount++;
    			mIIVal[mFoundCount] = $._mApp.mIntervalSampleBuffer[i];
    			
    			//Sys.println("fCalcAvgValues: Add sample # :"+i+", mFlagOffset: "+mFlagOffset+", mFoundCount: "+mFoundCount+", mIIVal[]:"+mIIVal);
    			
    			i--;
    			mFlagOffset++;
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
	// function to return average of N samples from buffer starting at index
	// for now just use simplistic sum and divide approach
	// Need to skip ectopic beats in past
	// returns float
	
	// THIS COULD USE aAVGStore and AddAverage if this handled ectopic beats (by just adding unadjusted average
	// would have to use differential average then avg(n) = (a0+ ...+a4)/5 = avg(n-1) + (a5-a0)/5
	// a0 calculated after 5 samples
	function fRunningAverage( start, length, samplesAvailable) {
		var avg = 0.0;
		var iterations = length; // default value - we have enough samples
		var sum = 0;
		
		// how many samples do we have in buffer from start. Number samples also next free slot so -1
		var cSamples = getNumberOfSamples();
		if ((start + length) > (cSamples - 1)) {
			// not enough samples for length so make do
			iterations = cSamples - 1 - (start+length);
		}
		
		var i;
		for (i=0; i < iterations; i++) {
			sum += $._mApp.mIntervalSampleBuffer[start+i];
		}
	
		avg = sum.toFloat() / iterations;
		
		Sys.println("Running Average of "+iterations+" samples gives "+avg+" starting from "+start);
		return avg;	
	}

(:newSampleProcessing) 	
	function fNormalCase(_vRunningAvg, _previousIntMs, _intMs, _mSampleIndex, _livePulse) {
		// add sample to II and stats, update running avg add this and II to avg buffers
		// update running avg ... mSampleIndex points to next free slot, this intMs would go in there
		vRunningAvg = fCalcAvgValues( _vRunningAvg, _intMs, _mSampleIndex);	
		// add sample to II store
		addSample(_intMs, 1); 
		// add and shift avg buffer and II store
		addAverage( _vRunningAvg, _intMs);
		// Update stats!
		updateRunningStats( _previousIntMs, _intMs, _livePulse);	
	}
			
(:newSampleProcessing) 	
	function rawSampleProcessing (isTesting, livePulse, intMs, beatsInGap ) {
		//Sys.println("v0.4.7 rawSampleProcessing called. mSampleIndex is = "+mSampleIndex);
		
		// Only update hrv data if testing started, & values look to be error free	
		if ((!isTesting) || (livePulse == 0)) {
			// Don't capture data if not testing OR
			// livePulse== 0 could happen on first loop - avoids divide by 0
			// If we still have an interval could create BPM from that...
			// Sys.println("rawSampleProcessing(): livePulse 0 - discarding");
			return;
		}
						
		// Given ANT sensor only provides one interval then we should probably ignore this sample
		if (beatsInGap != null && beatsInGap != 1) {$.DebugMsg( true, "C-"+mSampleIndex+"B:"+beatsInGap+" t:"+intMs);}
				
		// Sample #n arrived
		
		// Calculate estimated ranges for reliable data based on current pulse
		var maxMs = 60000 / (livePulse * 0.7);
		var minMs = 60000 / (livePulse * 1.4);
	
		// special case of 1st sample as previous will be zero!
		// make sure not stupid number
		if (mSampleIndex == 0) {
			if ( maxMs > intMs && minMs < intMs) { 				
				addSample(intMs, null); 
				vUpperFlag = 0;
				vLowerFlag = 0;
				// oldest sample for average!
				addAverage( intMs, intMs);
				vRunningAvg = intMs;
			}
			return;
		}
		
		// If n=0 then as now
		// if n < filter length
		//		status  = oK for current sample
		//		add sample
		//		update stats and rtn

		var previousIntMs = getSample(mSampleIndex-1);			
		if (mSampleIndex < 5) {
			Sys.println("mSampleIndex less than 5");
			if ( maxMs > intMs && minMs < intMs) { 
			
				Sys.println("avgStore index ="+mSampleIndex);
				addAverage( vRunningAvg / (mSampleIndex+1), intMs);	
				
				// add sample an inc pointer!!			
				addSample(intMs, null); 
				// No need to update vLower and vUpper flags as not testing
				updateRunningStats(previousIntMs, intMs, livePulse);
				vRunningAvg += intMs;
			}
			Sys.println("<5 return");
			return;
		} else if (mSampleIndex == 5) {
			vRunningAvg = aAvgStore[0];	
			Sys.println("Initial average from store ="+vRunningAvg+", store is "+aAvgStore);		
		}
		
		//Sys.println("Should only get here on 5 or more");
		
		// now should have pipeline of averages and values of II
		
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

		// will only get here if more than 5 samples arrived
		if (!mStartThreshold) {
			mStartThreshold = true; 
			//// update avg cal based on last 5 samples ignoring ectopic
			//vRunningAvg = fCalcAvgValues( vRunningAvg, intMs, mSampleIndex);	
			//// add and shift avg buffer and II store
			//addAverage( vRunningAvg, intMs);
			//// add sample to II store
			//addSample(intMs, null); 
			//// Update stats!
			//updateRunningStats(previousIntMs, intMs, livePulse);	
			fNormalCase(vRunningAvg, previousIntMs, intMs, mSampleIndex, livePulse);
		} else {
			// fall through here on 7th sample
			
			// 		Add sample??
			//		Test against threshold
			//		Set status of sample
			//		check this and last sample against status combinations and take action
			//		if not OK then rtn else ???
			
			// Test sample against runningAvg and threshold	
			var lowFlag  = 0;
			var highFlag = 0;
		
			// test against over threshold. Note these are % but factional ie < 1
			// updated values in JSON not to be integers. Could do x100 here
			var mDelta = (intMs.toFloat() - vRunningAvg) / vRunningAvg;
			if ((mDelta > 0) && (mDelta > $._mApp.vUpperThresholdSet)) {
				highFlag = 1;						
			} else if ((mDelta < 0) && (mDelta.abs() > $._mApp.vLowerThresholdSet)) {
				lowFlag = 1;
			}
			
			// status combinations and action
			// OK, OK -> add latest sample to stats
			// OK S -> wait
			// OK L -> wait
			// L S -> inc ectopic, missed beat
			// L L -> inc, heart slowing down?
			// S L -> inc, double beat
			// S S -> inc, ??? maybe change of rate up	
						// update this samples state
			vUpperFlag = vUpperFlag << 1 | highFlag;
			vLowerFlag = vLowerFlag << 1 | lowFlag;
			
			var mUp = vUpperFlag & 0x3;
			var mDown = vLowerFlag & 0x3;
						
			// may have to change to use S, OK; L, OK ie brief fluctuation
			// would need to pull in previous sample 
			
			// create switch selector
			var mUD = mUp << 2 | mDown;
			Sys.println("SampleProc: mDelta :"+format("$1$%",[(100*mDelta).format("%d")])+" flags U and D: "+mUp+", "+mDown+" switch = "+mUD+" avg="+vRunningAvg);
			
			switch (mUD) { //Up, down value = order of samples with most recent on left
				case 0 : // 00,00 = Ok, OK
				case 2 : // 00,10 = OK, S 
				case 8 : // 10,00 = OK, L
					fNormalCase(vRunningAvg, previousIntMs, intMs, mSampleIndex, livePulse);
				break;
				case 3: // Odd case S, S OR
				case 12: // Odd case L, L 
					// We have had two long beats or two short beats in a row
					// we ignore case that if we find LL or SS that the other flag could have data - shouldn't happen though as can't
					// exceed both thresholds :-)
					// Assume this maybe a trend
					// Update running average with current II (need to think of correcting previous avg's running and store
					// don't update stats and save avg and II into both buffers
					Sys.println("SampleProc: TWO LONG OR TWO SHORT beats!!!!");						
					// TBD could add both samples into buffer, clear lower 2 bits of flags and redo average 					
				break;	
				case 4:	// 01,00 = L, OK
					vLongBeatCnt++;
					Sys.println("SampleProcessing: LONG BEAT FOUND");	
					// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
					// add sample to II store
					addSample(intMs, 1); 
					// add and shift avg buffer and II store
					addAverage( vRunningAvg, intMs);	
				case 1: // OK, S = 0001
					vShortBeatCnt++;
					Sys.println("SampleProcessing: SHORT BEAT FOUND");	
					// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
					// add sample to II store
					addSample(intMs, 1); 
					// add and shift avg buffer and II store
					addAverage( vRunningAvg, intMs);						
				break;
				case 6: // L, S = 0110 inc long as well
					vLongBeatCnt++;
					// inc missed beat, no stats update, save current avg and II to avgstore
					addSample(intMs, 1); 
					// add and shift avg buffer and II store
					addAverage( vRunningAvg, intMs);
					vEBeatCnt++;
						
					Sys.println("SampleProcessing: Long and ECTOPIC BEAT FOUND");				
				break;
				case 9: // S, L = 1001 inc short as well
					vShortBeatCnt++;
					// inc missed beat, no stats update, save current avg and II to avgstore
					addSample(intMs, 1); 
					// add and shift avg buffer and II store
					addAverage( vRunningAvg, intMs);
					vEBeatCnt++;	
					Sys.println("SampleProcessing: SHORT and ECTOPIC BEAT FOUND");
				break;
				default: //5, 7 10, 11, 13, 14, 15	
					// 5 = 0101= simultaneous L, S
					// 7 = 0111 = SS and a Ok, L not possible
					// 11 = 1011 = L, OK and S, S 
					// 13 = 1101 = LL, ok,S
					// 14 = 1110
					// 15 == 1111					
					// shouldn't be here
					addSample(intMs, 1); 
					Sys.println("SampleProc: UNHANDLED BEAT CASE!!!!");			
				break;
			}	// end switch
			
			//Sys.println("mUp and mDown are "+mUp+", "+mDown);	
		
		} // end thresholding process
				
		//Sys.println("Sample end: new avgStore: "+aAvgStore+" aIIValue = "+aIIValue);

	// end new rawSampleProcessing
	}
	
(:discard)	
	function oldTestCases() {
				// OK OK or L,OK or S, OK. Last two shouldn't happen in real case
			if ( (( mUp + mDown) == 0) or  // 0
				 (mUp == 0 && mDown == 2) or // 2
				 (mUp == 2 && mDown == 0) ) { // 8
				// add sample to II and stats, update running avg add this and II to avg buffers
				// update running avg ... mSampleIndex points to next free slot, this intMs would go in there
				vRunningAvg = fCalcAvgValues( vRunningAvg, intMs, mSampleIndex);	
				// add sample to II store
				addSample(intMs, 1); 
				// add and shift avg buffer and II store
				addAverage( vRunningAvg, intMs);
				// Update stats!
				updateRunningStats(previousIntMs, intMs, livePulse);				
			} else
			// Odd case L, L or S, S
			if (mUp == 3 or mDown == 3) { // 12 or 3
				// We have had two long beats or two short beats in a row
				// we ignore case that if we find LL or SS that the other flag could have data - shouldn't happen though as can't
				// exceed both thresholds :-)
				// Assume this maybe a trend
				// Update running average with current II (need to think of correcting previous avg's running and store
				// don't update stats and save avg and II into both buffers
				Sys.println("SampleProc: TWO LONG OR TWO SHORT beats!!!!");
			} else
			// OK, L or OK, S
			if ((mUp == 1 && mDown == 0) or (mUp == 0 && mDown == 1)) { // 4 or 1
				// wait for next sample and don't update running avg, save current avg and II into avgstore, add II to main buffer
				// add sample to II store
				addSample(intMs, 1); 
				// add and shift avg buffer and II store
				addAverage( vRunningAvg, intMs);
			} else
			// L, S
			if (mUp == 2 && mDown == 1) { // 9
				// inc missed beat, no stats update, save current avg and II to avgstore
				addSample(intMs, 1); 
				// add and shift avg buffer and II store
				addAverage( vRunningAvg, intMs);
				vLongBeatCnt++;
			} else 
			// S, L
			if (mUp == 1 && mDown == 2) { // 6
				// inc double beat, no stats update
				// save current avg and II to avgstore			
				addSample(intMs, 1); 
				// add and shift avg buffer and II store
				addAverage( vRunningAvg, intMs);			
				vDoubleBeatCnt++;
			} else {
				// shouldn't be here
				addSample(intMs, 1); 
				Sys.println("SampleProc: UNHANDLED BEAT CASE!!!!");
				
				// have S, OK and L, OK in test case. In real life unlikely!
			}
	}
	

(:oldSampleProcessing)	
	function rawSampleProcessing (isTesting, livePulse, intMs, beatsInGap ) {
		// shouldn't capture data
		if (!isTesting) {return;}
		
		if (livePulse == 0) {
			// could happen on first loop - avoids divide by 0
			// If we still have an interval could create BPM from that...
			//Sys.println("rawSampleProcessing(): livePulse 0 - discarding");
			return;
		}
		
		// Calculate estimated ranges for reliable data
		var maxMs = 60000 / (livePulse * 0.7);
		var minMs = 60000 / (livePulse * 1.4);
		
		// Given ANT sensor only provides one interval then we should probably ignore this sample
		if (beatsInGap != null && beatsInGap != 1) {$.DebugMsg( true, "C-"+mSampleIndex+"B:"+beatsInGap+" t:"+intMs);}
		
		// need to check whether long gap is caused by multiple beats in gap and handle
		// eg missed beats ie beatsInGap > 1
					
		// Only update hrv data if testing started, & values look to be error free	
		
		// special case of 1st sample as previous will be zero!
		// make sure not stupid number
		if (mSampleIndex == 0) {
			if ( maxMs > intMs && minMs < intMs) { 				
				addSample(intMs, null); 
			}
			return;
		}
		
		var previousIntMs = getSample(mSampleIndex-1);	
		//Sys.println("S p "+ previousIntMs + " i " +intMs);
		// 0.4.3 remove check of previous as should be OK by defintion!!	
		if (maxMs > intMs && minMs < intMs ){ // && 
			//maxMs > previousIntMs && minMs < previousIntMs) {		
			addSample(intMs, beatsInGap);				
			updateRunningStats(previousIntMs, intMs, livePulse);			
		} else {
			// debug
			$.DebugMsg( true, "C-"+mSampleIndex+" R "+intMs+" H "+maxMs+" L "+minMs );
		}				
	}

	function addSample( intervalMs, beatsInGap) {
		// might assume circular buffer?
		// input is an interval time in ms
				
		// 1st sample needs to by pass processing
		//if (beatsInGap == null) { }
		
		// pre process bounds for poincare plot of RR interval
		// first sample will have null beatsInGap so ignore as 
		if (beatsInGap != null && intervalMs > maxIntervalFound) { maxIntervalFound = intervalMs;}
		if (beatsInGap != null && intervalMs < minIntervalFound) { minIntervalFound = intervalMs;}
		
		// Might want to implement circular buffer to avoid this...
		// also can notify testControl to stop testing
		if ( mSampleIndex > $._mApp.mIntervalSampleBuffer.size()) {
			new $._mApp.myException("Buffer limit reached in sample Processing");
		}
		$._mApp.mIntervalSampleBuffer[mSampleIndex] = intervalMs;	
		mSampleIndex++;	
		// may need more input to clean up the signal eg if beatCount gap larger than 1		
		//Sys.println("Sample count: "+mSampleIndex);
	}
	
	function getSample(index) {
		return $._mApp.mIntervalSampleBuffer[index];
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
			mLnRMSSD = (LOG_SCALE * (Math.ln(mRMSSD)+0.5)).toNumber();
			// 0.4.3
			if (mLnRMSSD < 0) {mLnRMSSD = 0;}
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


