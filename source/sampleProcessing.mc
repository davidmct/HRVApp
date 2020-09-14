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

class SampleProcessing {

	// these need to be moved from ANThandler and references changed
	hidden var devMs;
	hidden var devSqSum;
	hidden var pulseSum;
	
	hidden var mSDNN_param = [0, 0.0, 0.0, 0.0, 0.0];
	hidden var mSDSD_param = [0, 0.0, 0.0, 0.0, 0.0];
	
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
	
	// index always points to next available slot
	hidden var mSampleIndex;
	
	function initialize() {
		// do we keep big buffer of intervals here?
		// for moment define it in global space as need to use it in views
		// if we make a circular buffer then will need to make lots of calls to get data
		$._mApp.mIntervalSampleBuffer = new [MAX_BPM * MAX_TIME];
		resetSampleBuffer();
		resetHRVData();
	}
	
	function resetSampleBuffer() { 
		mSampleIndex = 0;
		$._mApp.mIntervalSampleBuffer[0] = 0;
		minIntervalFound = 2000; // around 30 BPM
		maxIntervalFound = 0;
	}
	
	function resetHRVData() {
		resetSampleBuffer();
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
	
(:newSampleProcessing)
	// function to threshold data and set flags on interval status
	function fThresholdSample() {
	
	
	
	
	}

(:newSampleProcessing) 	
	function rawSampleProcessing (isTesting, livePulse, intMs, beatsInGap ) {
		Sys.println("new sampling called");

		if (!isTesting) || (livePulse == 0) {
			// Don't capture data if not testing OR
			// livePulse== 0 could happen on first loop - avoids divide by 0
			// If we still have an interval could create BPM from that...
			// Sys.println("rawSampleProcessing(): livePulse 0 - discarding");
			return;
		}
		
		// Given ANT sensor only provides one interval then we should probably ignore this sample
		if (beatsInGap != null && beatsInGap != 1) {$.DebugMsg( true, "C-"+mSampleIndex+"B:"+beatsInGap+" t:"+intMs);}
		
		// Calculate estimated ranges for reliable data
		var maxMs = 60000 / (livePulse * 0.7);
		var minMs = 60000 / (livePulse * 1.4);
						
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
	// end new rawSampleProcessing
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


