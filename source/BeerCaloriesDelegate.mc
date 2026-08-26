import Toybox.WatchUi;
import Toybox.Lang;

// Returned alongside the main view so MENU opens the kcal-per-beer stepper.
(:glance)
class BeerCaloriesDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        var view = new CaloriesPickerView();
        WatchUi.pushView(view, new CaloriesPickerDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}
