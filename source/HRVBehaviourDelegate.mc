using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

class HRVBehaviourDelegate extends Ui.BehaviorDelegate {

    var app;
    
    function initialize() {
		BehaviorDelegate.initialize();
		app = App.getApp();
	}
       
    function onSelect() {
    	// same as enter, tap or click
    	return onEnter();  
    }
    
    function onBack() {
    	// same as escape
    	return onEscape();
    }
	
	function onNextPage() {
		// down or swipe UP
		Ui.switchToView(app.plusView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_LEFT));
		return true;
    }

    function onPreviousPage() {
		// Up or swipe down
		Ui.switchToView(app.subView(), new HRVBehaviourDelegate(), slide(Ui.SLIDE_RIGHT));
		return true;
    }


    // handle other key presses
    function onKey(event) {

    	if(Ui.KEY_ENTER == event.getKey()) {
			// menu key
			onEnter();
		}
		else if(Ui.KEY_ESC == event.getKey()) {
			// same as back
			onEscape();
      	}
      	else if(Ui.KEY_MENU == event.getKey()) {
			onMenu();
      	}
      	else if(Ui.KEY_POWER == event.getKey()) {
			onPower();
		}
		return true;
	}

    function slide(direction) {

    	//if((Ui.SLIDE_LEFT == direction || Ui.SLIDE_UP == direction) && GRAPH_VIEW == app.viewNum) {
    	if(Ui.SLIDE_LEFT == direction && GRAPH_VIEW == app.viewNum) {

    		return Ui.SLIDE_IMMEDIATE;
		}
    	//else if((Ui.SLIDE_RIGHT == direction || Ui.SLIDE_DOWN == direction) && GRAPH_VIEW == app.viewNum) {
    	else if(Ui.SLIDE_RIGHT == direction && GRAPH_VIEW == app.viewNum) {

    		return Ui.SLIDE_IMMEDIATE;
    	}
    	else {

    		return direction;
    	}
    }

    function onEnter() {

		if(0 < app.viewNum) {

			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
			return true;
		}
		else if(app.isNotSaved && MIN_SAMPLES < app.dataCount) {

			Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
			return true;
    	}
    	else if(app.isFinished) {

    		app.resetTest();
    		Ui.requestUpdate();
    	}
    	else if(app.isTesting || app.isWaiting) {

    		app.stopTest();
    		Ui.requestUpdate();
    	}
    	else if(!app.isAntRx){

    		app.alert(TONE_ERROR);
    	}
    	else {

    		app.startTest();
    		app.stopViewTimer();
    		app.updateSeconds();
    	}

    	app.resetGreenTimer();
    	return true;
	}

	function onMenu() {

		app.stopGreenTimer();
		app.stopViewTimer();
		Ui.pushView(new Rez.Menus.MainMenu(), new MainMenuDelegate(), Ui.SLIDE_LEFT);
		return true;
    }

	function onEscape() {

		if(TEST_VIEW == app.viewNum) {

			if(app.isTesting) {

				app.stopTest();
			}
			if(app.isFinished && app.isNotSaved && MIN_SAMPLES < app.dataCount) {
				app.isClosing = true;
				Ui.pushView(new Ui.Confirmation("Save result?"), new SaveDelegate(), Ui.SLIDE_LEFT);
			}
			else {
				app.onStop( null);
				Ui.popView(Ui.SLIDE_RIGHT);
			}
		}
		else {

			Ui.switchToView(app.getView(TEST_VIEW), new HRVBehaviourDelegate(), Ui.SLIDE_RIGHT);
		}
		return true;
	}

	function onPower() {

		app.resetGreenTimer();
		return true;
	}


}
