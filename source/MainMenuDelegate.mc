using Toybox.WatchUi as Ui;

class MainMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId();
    
     	if( item.getId().equals("test")) {
            Ui.pushView(new Rez.Menus.TestTypeMenu(), new TestTypeMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if( item.getId().equals("settings") ) {

            Ui.pushView(new Rez.Menus.SettingsMenu(), new SettingsMenuDelegate(), Ui.SLIDE_LEFT);
        }
        else if( item.getId().equals("about"))  {
            Ui.pushView(new Rez.Menus.AboutMenu(), new EmptyMenuDelegate(), Ui.SLIDE_LEFT);
        }
    }
}