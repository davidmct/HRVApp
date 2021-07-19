using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Time;
using Toybox.Application.Storage as Store;
using HRVStorageHandler as mStorage;

(:LargeExclude)
// Version for small memory devices to dump strings
module DumpData {

    function f_dumpData(){
		// Dump all interval data to txt file on device
		DumpIntervals();
		DumpHist(); 
		DumpHRV();
	}

	function writeStrings(_type, _mNumBlocks, _mRemainder, _size) {
		var mString;
		var index = 0;
		var mSp;
		var separator = ",";
	
		mString = ( _type == 0 ? "II:," : "Flags:,");

		for (var i=0; i < _mNumBlocks; i++) {
			for (var j=0; j< _size; j++) {
				mSp = mIntervalSampleBuffer[index];
				mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
				mString += mSp.toString()+separator;	
				index++;			
			}
			Sys.println(mString);
			mString = "";		
		}
		mString = "";
		// Write tail end of buffer
		index = _size * _mNumBlocks;
		for (var i=0; i < _mRemainder; i++) {	
				mSp = mIntervalSampleBuffer[index];
				mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
				mString += mSp.toString()+separator;
				index++;						
		}	
		Sys.println(mString);
	
	}
	
	function DumpIntervals() {
		// to reduce write time group up the data
		var BLOCK_SIZE = 40;
		
		if (mSampleProc == null) { return;}
		
		var mNumEntries = mSampleProc.getNumberOfSamples();

		mStorage.PrintStats();
				
		if (mNumEntries > $.mIntervalSampleBuffer.size() - 1) {
			// v1.0.3 used to stop print - now dump full buffer instead
			mNumEntries = $.mIntervalSampleBuffer.size() - 1;
		}
		if (mNumEntries <= 0) { return;}
		
		var mNumBlocks = mNumEntries / BLOCK_SIZE ;
		var mRemainder = mNumEntries % BLOCK_SIZE ;

		Sys.println("Dumping intervals");
		
		//if (mDebugging == true) {
		//	Sys.println("DumpIntervals: mNumEntries, blocks, remainder: " + mNumEntries+","+ mNumBlocks+","+ mRemainder);				
		//}
		
		// save memory by removing code lines
		// type 0 = II, 1 = flags
		writeStrings(0, mNumBlocks, mRemainder, BLOCK_SIZE);		
		writeStrings(1, mNumBlocks, mRemainder, BLOCK_SIZE);
	}
	
	// put all valid History entries into LOG
	function DumpHist() {
	
		var mMsg =  "";
		// load results array from store
		// returns true if successful and $.resultsIndex != 0 
		mStorage.retrieveResults();
		if ( $.results == null || $.resultsIndex ==0) {Sys.println("no Hist dump"); return;}

		// Labels
		mMsg = "History: time; Avg HR, Min_II, Max_II, Min Diff, Max Diff, RMSSD, LogHRV, SDNN, SDSD, NN50, pNN50, NN20, pNN20";
		Sys.println(mMsg);		
		
		// dump all data -- could just do this but format unfriendly for table
		//Sys.println( $.results);
						
		// Now iterate through the non-zero time stamps
		var index = 0;
		for (var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			index = i * DATA_SET_SIZE;
			mMsg = "";
			if ($.results[index] == 0) {
				// no entry in array
				continue;
			}
			for ( var j = 0; j < DATA_SET_SIZE; j++) {
				mMsg = mMsg+ $.results[index+j]+", ";
			} 
			Sys.println(mMsg);		
		}
			
		mMsg = null;
		$.results = null;		
		return;	
			
	}		
	
	function DumpHRV() {
		var mHRV;
		var mMsg =  "";
		
		if (Toybox.Application has :Storage) {
			mHRV = Store.getValue("resultsArrayW");
		} else {
			return;
		}
		
		if (mHRV == null) { return;}
		Sys.println("Dump HRV log [date, value]:");
		
		for (var i=0; i < mHRV.size(); i += 2) {
			if (mHRV[i] == 0) { continue;}
			mMsg = mHRV[i]+ ", " + mHRV[i+1] + ", ";
			Sys.println(mMsg);	
		}
		
		mMsg = null;
		mHRV = null;
	
	}
}


(:SmallExclude)
// Version for large memory devices to dump strings
module DumpData {

	var mNumBlocks;
	var mRemainder;
	var mNumEntries;
	var mBlkSize; //block size is assumed to be 640 if maxbuffer = 3200 
		
	// stub for HRVApp when using large devices
    function f_dumpData(){
    	return;
	}
	
	// Work out how many blocks to be used and remainder (truncated block at end)
	function sizeBlocks() {

		mBlkSize = $.mMaxBuf / 5; //block size is assumed to be 640 if maxbuffer = 3200 
	
		mNumEntries = $.mSampleProc.getNumberOfSamples();	
		if (mNumEntries > $.mIntervalSampleBuffer.size() - 1) {
			// v1.0.3 used to stop print - now dump full buffer instead
			mNumEntries = $.mIntervalSampleBuffer.size() - 1;
		}
		
		if (mNumEntries <= 0) { return false;}
		
// TEST CODE FORCE mNumEntries to buffer size
		// fill backend of buffer
		Sys.println("******************TEST VERSION OF DUMP******************");
		for( var ab=mNumEntries; ab < $.mIntervalSampleBuffer.size(); ab++) {
			$.mIntervalSampleBuffer[ab] = 123;
		}
		mNumEntries = $.mIntervalSampleBuffer.size() - 1;
// END FORCE TEST CODE
				
		mNumBlocks = mNumEntries / mBlkSize ;
		mRemainder = mNumEntries % mBlkSize ;	
		
		return true; // blocks to write	
	}
	
	// Timer driven write of a block of data from intervals or flags depending on type
	// Assume we have 5 calls roughly to dump each buffer so worst case completes in 1 second on a 100ms timer
	// Returns true if completed dump
	// Parameters: _type = 0 for intervals, 1 for flags; _mBlk is count of which block to write
	function writeStrings( _type, _mBlk) {

		var index = _mBlk * mBlkSize; 
		var mString ="";
								
		if (_mBlk == 0) {
			// write string prefix
			mString = ( _type == 0 ? "II:" : "Flags:");
			Sys.println(mString);
		}	
	
		// are we doing a full block or remainder if it exists
		if (_mBlk <= mNumBlocks) {
			partWrite( _type, index, mBlkSize);
		} else {
			partWrite( _type, index, mRemainder);
			return true; // done
		}
		
		return false;
	}

	function partWrite( _type, base, mLen) {
		var mString ="";
		var mSp;
		var separator = ",";
		var index = base;
		
		switch( _type) {
		case 0: 
			for (var j=0; j< mLen; j++) {
				mSp = $.mIntervalSampleBuffer[index] & 0x0FFF;
				index++;			
				mString += mSp.toString()+separator;				
			}		
			break;
		case 1:
			for (var j=0; j< mLen; j++) {
				mSp = ($.mIntervalSampleBuffer[index] >> 12) & 0xF;
				index++;			
				mString += mSp.toString()+separator;				
			}		
			break;
		}

		//for (var j=0; j< mBlockS; j++) {
		//	mSp = mIntervalSampleBuffer[index];
		//	index++;
		//	mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
		//	mString += mSp.toString()+separator;				
		//}
		
		Sys.println(mString);
		//mString = "";	
	}

		
	// put all valid History entries into LOG
	function DumpHist() {
	
		var mMsg =  "";
		// load results array from store
		// returns true if successful and $.resultsIndex != 0 
		mStorage.retrieveResults();
		if ( $.results == null || $.resultsIndex ==0) {Sys.println("no Hist dump"); return;}

		// Labels
		mMsg = "History: time; Avg HR, Min_II, Max_II, Min Diff, Max Diff, RMSSD, LogHRV, SDNN, SDSD, NN50, pNN50, NN20, pNN20";
		Sys.println(mMsg);		
		
		// dump all data -- could just do this but format unfriendly for table
		//Sys.println( $.results);
						
		// Now iterate through the non-zero time stamps
		var index = 0;
		for (var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			index = i * DATA_SET_SIZE;
			mMsg = "";
			if ($.results[index] == 0) {
				// no entry in array
				continue;
			}
			for ( var j = 0; j < DATA_SET_SIZE; j++) {
				mMsg = mMsg+ $.results[index+j]+", ";
			} 
			Sys.println(mMsg);		
		}
			
		mMsg = null;
		$.results = null;		
		return;	
			
	}		
	
	function DumpHRV() {
		var mHRV;
		var mMsg =  "";
		
		if (Toybox.Application has :Storage) {
			mHRV = Store.getValue("resultsArrayW");
		} else {
			return;
		}
		
		if (mHRV == null) { return;}
		Sys.println("Dump HRV log [date, value]:");
		
		for (var i=0; i < mHRV.size(); i += 2) {
			if (mHRV[i] == 0) { continue;}
			mMsg = mHRV[i]+ ", " + mHRV[i+1] + ", ";
			Sys.println(mMsg);	
		}
		
		mMsg = null;
		mHRV = null;
	
	}

}

(:discard)
// Save of old code
module DumpData {

	// stub for HRVApp when using large devices
    function f_dumpData(){
    	return;
	}

	function partWrite( _type, base, mLen) {
		var mString ="";
		var mSp;
		var separator = ",";
		var index = base;
		
		switch( _type) {
		case 0: 
			for (var j=0; j< mLen; j++) {
				mSp = $.mIntervalSampleBuffer[index] & 0x0FFF;
				index++;			
				mString += mSp.toString()+separator;				
			}		
			break;
		case 1:
			for (var j=0; j< mLen; j++) {
				mSp = ($.mIntervalSampleBuffer[index] >> 12) & 0xF;
				index++;			
				mString += mSp.toString()+separator;				
			}		
			break;
		}

		//for (var j=0; j< mBlockS; j++) {
		//	mSp = mIntervalSampleBuffer[index];
		//	index++;
		//	mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
		//	mString += mSp.toString()+separator;				
		//}
		
		Sys.println(mString);
		//mString = "";	
	}

	function writeStrings(_type, _mNumBlocks, _mRemainder, mBlockS) {
	    // Block size for dump to debug of intervals
  		//var BLOCK_SIZE = 40;
		var mString;
		var base = 0;
		var mSp;
		var separator = ",";
	
		mString = ( _type == 0 ? "II:" : "Flags:");
		Sys.println(mString);

		for (var i=0; i < _mNumBlocks; i++) {
			partWrite( _type, base, mBlockS);
			base += mBlockS;
//Sys.println("base="+base);
		}
		
//Sys.println("Do tail");
		
		//mString = "";
		// Write tail end of buffer
		base = mBlockS * _mNumBlocks;
		partWrite( _type, base, _mRemainder);
		
		//for (var i=0; i < _mRemainder; i++) {	
		//		mSp = $.mIntervalSampleBuffer[base+i];
		//		mSp = ( _type == 0) ? mSp & 0x0FFF : (mSp >> 12) & 0xF;				
		//		mString += mSp.toString()+separator;						
		//}	
		//Sys.println(mString);
	
	}

	
	function DumpIntervals() {
		// to reduce write time group up the data
		var BLOCK_SIZE = 40;
		
		if ($.mSampleProc == null) { return;}
		
		var mNumEntries = $.mSampleProc.getNumberOfSamples();

		mStorage.PrintStats();
				
		if (mNumEntries > $.mIntervalSampleBuffer.size() - 1) {
			Sys.println("Buffer overrun - no dump");
			return;
		}
		if (mNumEntries <= 0) { return;}
		
		// TEST CODE FORCE mNumEntries to buffer size
		// fill backend of buffer
		Sys.println("******************TEST VERSION OF DUMP******************");
		for( var ab=mNumEntries; ab < $.mIntervalSampleBuffer.size(); ab++) {
			$.mIntervalSampleBuffer[ab] = 123;
		}
		mNumEntries = $.mIntervalSampleBuffer.size() - 1;
		// END FORCE TEST CODE
		
		var mNumBlocks = mNumEntries / BLOCK_SIZE ;
		var mRemainder = mNumEntries % BLOCK_SIZE ;
		//var mString = "II:, ";
		//var i;
		//var base;
		//var mSp;		

		Sys.println("Dumping intervals");
		
		//if (mDebugging == true) {
		Sys.println("DumpIntervals: mNumEntries, blocks, remainder: " + mNumEntries+","+ mNumBlocks+","+ mRemainder);				
		//}
		
		// save memory by removing code lines
		// type 0 = II, 1 = flags
		writeStrings(0, mNumBlocks, mRemainder, BLOCK_SIZE);		
		writeStrings(1, mNumBlocks, mRemainder, BLOCK_SIZE);
	}
	
	// put all valid History entries into LOG
	function DumpHist() {
	
		var mMsg =  "";
		// load results array from store
		// returns true if successful and $.resultsIndex != 0 
		mStorage.retrieveResults();
		if ( $.results == null || $.resultsIndex ==0) {Sys.println("no Hist dump"); return;}

		// Labels
		mMsg = "History: time; Avg HR, Min_II, Max_II, Min Diff, Max Diff, RMSSD, LogHRV, SDNN, SDSD, NN50, pNN50, NN20, pNN20";
		Sys.println(mMsg);		
		
		// dump all data -- could just do this but format unfriendly for table
		//Sys.println( $.results);
						
		// Now iterate through the non-zero time stamps
		var index = 0;
		for (var i = 0; i < NUM_RESULT_ENTRIES; i++) {
			index = i * DATA_SET_SIZE;
			mMsg = "";
			if ($.results[index] == 0) {
				// no entry in array
				continue;
			}
			for ( var j = 0; j < DATA_SET_SIZE; j++) {
				mMsg = mMsg+ $.results[index+j]+", ";
			} 
			Sys.println(mMsg);		
		}
			
		mMsg = null;
		$.results = null;		
		return;	
			
	}		
	
	function DumpHRV() {
		var mHRV;
		var mMsg =  "";
		
		if (Toybox.Application has :Storage) {
			mHRV = Store.getValue("resultsArrayW");
		} else {
			return;
		}
		
		if (mHRV == null) { return;}
		Sys.println("Dump HRV log [date, value]:");
		
		for (var i=0; i < mHRV.size(); i += 2) {
			if (mHRV[i] == 0) { continue;}
			mMsg = mHRV[i]+ ", " + mHRV[i+1] + ", ";
			Sys.println(mMsg);	
		}
		
		mMsg = null;
		mHRV = null;
	
	}

}