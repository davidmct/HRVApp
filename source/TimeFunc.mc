using Toybox.Application as App;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Timer;
using Toybox.System as Sys;

    function timerFormat(time) {
    	var hour = time / 3600;
		var min = (time / 60) % 60;
		var sec = time % 60;
		if(0 < hour) {
			return format("$1$:$2$:$3$",[hour.format("%01d"),min.format("%02d"),sec.format("%02d")]);
		}
		else {
			return format("$1$:$2$",[min.format("%01d"),sec.format("%02d")]);
		}
    }

	function clockFormat(time) 	{
		var hour = (time / 3600) % 24;
		var min = (time / 60) % 60;
		var sec = time % 60;
		var meridiem = "";
		if(System.getDeviceSettings().is24Hour) {
			if(0 == time) {
				hour = 24;
			}
			else {
				hour = hour % 24;
			}
			return format("$1$$2$",[hour.format("%02d"),min.format("%02d")]);
		}
		else {
			if(12 > hour) {
				meridiem = "AM";
			}
			else {
				meridiem = "PM";
			}
			hour = 1 + (hour + 11) % 12;
			return format("$1$:$2$:$3$ $4$",[hour.format("%01d"),
				min.format("%02d"),sec.format("%02d"),meridiem]);
		}
	}


    function timeNow() {
    	return (Time.now().value() + System.getClockTime().timeZoneOffset);
    }

    function timeToday() {
    	return (timeNow() - (timeNow() % 86400));
    }
