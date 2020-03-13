using Toybox.WatchUi as Ui;

class ResetMenuDelegate extends Ui.Menu2InputDelegate {

    function initialize() { Menu2InputDelegate.initialize();}

    function onSelect(item) {
        var id = item.getId();
    
     	if( id.equals("settings")) {
			Ui.pushView(new Ui.Confirmation("Reset settings?"), new SettingsDelegate(), Ui.SLIDE_LEFT);
        }
        else if (id.equals("results")) {
			Ui.pushView(new Ui.Confirmation("Clear results?"), new ResultsDelegate(), Ui.SLIDE_LEFT);
        }
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
 
    function onDone() {
        Ui.popView(Ui.SLIDE_DOWN);
    } 
    
}