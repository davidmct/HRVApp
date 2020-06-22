using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;

// HRV APP MAIN

enum {
	// device types
	RES_240x240 = 0,
	RES_260x260 = 1,
	RES_280x280 = 2,
	
	// Views
	TEST_VIEW = 0,
	STATS1_VIEW = 1,
	STATS2_VIEW = 2,
	STATS3_VIEW = 3,
	//CURRENT_VIEW = 4,
	POINCARE_VIEW = 4,
	POINCARE_VIEW2 = 5,
	HISTORY_VIEW = 6,
	NUM_VIEWS = 7
}

// Colors index. Arrays start at zero
const 	WHITE = 0;
const	LT_GRAY = 1;
const	DK_GRAY = 2;
const	BLACK = 3;
const	RED = 4;
const	DK_RED = 5;
const	ORANGE = 6;
const	YELLOW = 7;
const	GREEN = 8;
const	DK_GREEN = 9;
const	BLUE = 10;
const	DK_BLUE = 11;
const	PURPLE = 12;
const	PINK = 13;
const	TRANSPARENT = 14;

// colour management

// could implement device specific colour maps here eg to 64 or fenix 3 case using tags

// index with enum for colours
var colours =[Graphics.COLOR_WHITE, Graphics.COLOR_LT_GRAY,Graphics.COLOR_DK_GRAY,Graphics.COLOR_BLACK,
				Graphics.COLOR_RED, Graphics.COLOR_DK_RED, Graphics.COLOR_ORANGE, Graphics.COLOR_YELLOW,
				Graphics.COLOR_GREEN, Graphics.COLOR_DK_GREEN,Graphics.COLOR_BLUE,Graphics.COLOR_DK_BLUE,
				Graphics.COLOR_PURPLE, //Purple. Not valid on fenix 3 or D2 Bravo. Use 0x5500AA instead.
				Graphics.COLOR_PINK, Graphics.COLOR_TRANSPARENT];
	
//var fonts = [Graphics.FONT_XTINY,Graphics.FONT_TINY,Graphics.FONT_SMALL,Graphics.FONT_MEDIUM,Graphics.FONT_LARGE,
//             Graphics.FONT_NUMBER_MILD,Graphics.FONT_NUMBER_MEDIUM,Graphics.FONT_NUMBER_HOT,Graphics.FONT_NUMBER_THAI_HOT];


// for menu construction .. and could get rid of enum and change map at some point
var mColourNumbersString = {"WHITE"=>WHITE,"LT_GRAY"=>LT_GRAY, "DK_GRAY"=>DK_GRAY,"BLACK"=>BLACK, "RED"=>RED, 
	"DK_RED"=>DK_RED, "ORANGE"=>ORANGE,	"YELLOW"=>YELLOW, "GREEN"=>GREEN, "DK_GREEN" => DK_GREEN, "BLUE" => BLUE,
	"DK_BLUE" => DK_BLUE, "PURPLE" => PURPLE, "PINK" => PINK, "TRANSPARENT" => TRANSPARENT};

// HISTORY VIEW SELECTOR

// for menu on selecting history view items
(:HistoryViaDictionary)
var mHistorySelect = {  "avgBPM"=> AVG_PULSE_INDEX, 
						"minII" => MIN_II_INDEX, "maxII" => MIN_II_INDEX,
						"minD" => MIN_DIFF_INDEX, "maxD" => MIN_DIFF_INDEX,
						"rMSSD" => RMSSD_INDEX, "LnrMSSD" => LNRMSSD_INDEX, 
						"SDNN" => SDNN_INDEX, "SDSD" => SDSD_INDEX, 
						"NN50" => NN50_INDEX, "pNN50" => PNN50_INDEX, 
						"NN20" => NN20_INDEX, "pNN20" => PNN20_INDEX, 						
					};	

//0.4.3
// use array of labels instead of dictionary
// index 0 is null case ie empty
// must be in same order as INDEX list
var mHistoryLabelList = [ "none", "avgBPM", "minII", "maxII",
						"minD", "maxD", "rMSSD", "LnrMSSD", 
						"SDNN", "SDSD", "NN50", "pNN50", 
						"NN20", "pNN20"];						

// SAMPLE PROCESSING
const MIN_BPM = 35;
const MAX_BPM = 160; // max that will fill buffer in time below. Could be 200!!
const MAX_TIME = 8; // minutes
const LOG_SCALE = 50; // scales ln(RMSSD)

// STORAGE PROPERTIES

// Results memory locations. (X) <> (X + 29)
const NUM_RESULT_ENTRIES = 30; // last 30 days
const DATA_SET_SIZE = 14; // each containing this number of entries
// for properties method of storage, arranged as arrays of results per time period
const RESULTS = "RESULTS";

// Samples needed for stats min
const MIN_SAMPLES = 20;

// HISTORY VIEW

// define history indexes and mapping strings
const TIME_STAMP_INDEX = 0;
const AVG_PULSE_INDEX = 1;
const MIN_II_INDEX = 2;
const MAX_II_INDEX = 3;
const MIN_DIFF_INDEX = 4;
const MAX_DIFF_INDEX = 5;
const RMSSD_INDEX = 6;
const LNRMSSD_INDEX = 7;
const SDNN_INDEX = 8;
const SDSD_INDEX = 9; 
const NN50_INDEX = 10;
const PNN50_INDEX = 11; 
const NN20_INDEX = 12;
const PNN20_INDEX = 13;

const MAX_DISPLAY_VAR = 3;


// TEST CONTROL

enum {
	// Tones
	TONE_KEY = 0,
	TONE_START = 1,
	TONE_STOP = 2,
	TONE_RESET = 9,
	TONE_FAILURE = 14,
	TONE_SUCCESS = 15,
	TONE_ERROR = 18,

	//Test types
	TYPE_MANUAL = false,  //runs as long as user wants up to max time
	TYPE_TIMER = true,   // to 5 mins and can be changed down or to max-time
	
	SENSOR_INTERNAL = false, // false
	SENSOR_SEARCH = true, // true
	
	// define test states
	// Ordered so we know in TESTING or further states
	TS_INIT = 1,
	TS_WAITING = 2,
	TS_READY = 3,
	TS_TESTING = 4,
	TS_ABORT = 5,
	TS_CLOSE = 6,
	TS_PAUSE = 7,
	//0.4.4 - allow one more cycle to read message
	TS_PAUSE2 = 8
}


