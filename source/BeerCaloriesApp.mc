import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BeerCaloriesApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new BeerCaloriesView(), new BeerCaloriesDelegate() ];
    }

    // Compact view for the glance carousel; opens BeerCaloriesView on select
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new BeerGlanceView() ];
    }

}

function getApp() as BeerCaloriesApp {
    return Application.getApp() as BeerCaloriesApp;
}