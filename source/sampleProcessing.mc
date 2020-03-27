using Toybox.Application as App;
using Toybox.System as Sys;


// add here functions to post process HR data once we have it!
// This should contain all the data collection and stats generation
// sample data etc is kept in Storage and properties class

// Measurements possible

//SDNN, the standard deviation of NN intervals. Often calculated over a 24-hour period. 
//SDANN, the standard deviation of the average NN intervals calculated over short periods, usually 5 minutes. 
//	SDNN is therefore a measure of changes in heart rate due to cycles longer than 5 minutes. 
//	SDNN reflects all the cyclic components responsible for variability in the period of recording, therefore it 
//	represents total variability.
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

//sigma = sqrt (N*s(2}-s(1)^2})/N
//Where N, as mentioned above, is the size of the set of values (or can also be regarded as s0).

//Similarly for sample standard deviation,

//s= sqrt ((N*s(2)-s(1)^2) / (N*(N-1)) ).
//In a computer implementation, as the three s(j) sums become large, we need to consider round-off error, 
//arithmetic overflow, and arithmetic underflow. The method below calculates the running sums method with
// reduced rounding errors.[16] This is a "one pass" algorithm for calculating variance of n samples without the 
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

const MAX_BPM = 150; // max that will fill buffer in time below. Could be 200!!
const MAX_TIME = 6; // minutes
const LOG_SCALE = 50; // scales ln(RMSSD)

class SampleProcessing {

	// these need to be moved from ANThandler and references changed
	hidden var devMs;
	hidden var devSqSum;
	hidden var pulseSum;
	
	var dataCount;
	var avgPulse;
	var minIntervalFound;
	var maxIntervalFound;
	var mRMSSD;
	var mLnRMSSD;
	var mSDANN;
	var mSDSD; 
	var mNN50;
	var mpNN50; 
	var mNN20;
	var mpNN20;
	
	hidden var mSampleIndex;
	hidden var mApp;
	
	function initialize() {
		// do we keep big buffer of intervals here?
		// for moment define it in global space as need to use it in views
		// if we make a circular buffer then will need to make lots of calls to get data
		mApp = App.getApp();
		mApp.mIntervalSampleBuffer = new [MAX_BPM * MAX_TIME];
		resetSampleBuffer();
		resetHRVData();
	}
	
	function resetSampleBuffer() { 
		mSampleIndex = 0;
		mApp.mIntervalSampleBuffer[mSampleIndex] = 0;
		minIntervalFound = 1000;
		maxIntervalFound = 0;
	}
	
	function resetHRVData() {
		devMs = 0;
		devSqSum = 0;
		pulseSum = 0;
		dataCount = 0;	
		avgPulse = 0;
		mRMSSD = 0;
		mLnRMSSD = 0;	
		mSDANN = 0;
		mSDSD = 0; 
		mNN50 = 0;
		mpNN50 = 0; 
		mNN20 = 0;
		mpNN20 = 0;
	}
	
	function getNumberOfSamples() {
		return mSampleIndex;
	}

	function rawSampleProcessing (isTesting, livePulse, intMs, beatsInGap ) {
			// Calculate estimated ranges for reliable data
			var maxMs = 60000 / (livePulse * 0.7);
			var minMs = 60000 / (livePulse * 1.4);
			
			// need to check whether long gap is caused by multiple beats in gap and handle
			// eg missed beats ie beatsInGap > 1
						
			// Only update hrv data if testing started, & values look to be error free	
			var previousIntMs = getSample(mSampleIndex);		
			if (isTesting && 
				maxMs > intMs && 
				minMs < intMs && 
				maxMs > previousIntMs && 
				minMs < previousIntMs) {		
				
				addSample(intMs, beatsInGap);				
				updateRunningStats(previousIntMs, intMs, livePulse);			
			}					
	}

	function addSample( intervalMs, beatsInGap) {
		// might assume circular buffer?
		// input is an interval time in ms
		// this is always last entry in buufer
		mSampleIndex++;
		
		// pre process bounds for poincare plot of RR interval
		if (intervalMs > maxIntervalFound) { maxIntervalFound = intervalMs;}
		if (intervalMs < minIntervalFound) { minIntervalFound = intervalMs;}
		
		// Might want to implement circular buffer to avoid this...
		// also can notify testControl to stop testing
		if ( mSampleIndex > mApp.mIntervalSampleBuffer.size()) {
			new mApp.myException("Buffer limit reached in sample Processing");
		}
		mApp.mIntervalSampleBuffer[mSampleIndex] = intervalMs;		
		// may need more input to clean up the signal eg if beatCount gap larger than 1		
	}
	
	function getSample(index) {
		return mApp.mIntervalSampleBuffer[index];
	}
	
	// update the per sample stats
	function updateRunningStats(previousIntMs, intMs, livePulse) {
		// implement running equations
		// note that Math lib has stdev(data, mean) for standard deviation
		
		if(intMs > previousIntMs) {
			devMs = intMs - previousIntMs;
		} else {
			devMs = previousIntMs - intMs;
		}
		
		devSqSum += devMs * devMs;
		pulseSum += livePulse;
		dataCount++;
	
		if(1 < dataCount) {
			// HRV is actually RMSSD
			mRMSSD = Math.sqrt(devSqSum.toFloat() / (dataCount - 1));
			// many people compand rmssd to a scaled range 0-100
			mLnRMSSD = (LOG_SCALE * (Math.ln(mRMSSD)+0.5)).toNumber;
			avgPulse = ((pulseSum.toFloat() / dataCount) + 0.5).toNumber();
			
			mSDANN = 0;
			mSDSD = 0; 
			mNN50 = 0;
			mpNN50 = 0; 
			mNN20 = 0;
			mpNN20 = 0;
		}		
		// May need to change stats source from Ant to this module
	}

}


