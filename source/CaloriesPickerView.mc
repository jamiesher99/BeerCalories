import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// UP / DOWN step the value, START saves, BACK discards. Pushed on top of the
// main view, so it isn't subject to the widget base-view input restrictions.
(:glance)
class CaloriesPickerView extends WatchUi.View {

    private var _value as Number;

    function initialize() {
        View.initialize();
        _value = getCaloriesPerBeer();
    }

    function adjust(delta as Number) as Void {
        _value = clampCaloriesPerBeer(_value + delta);
        WatchUi.requestUpdate();
    }

    function save() as Void {
        Storage.setValue(CALORIES_PER_BEER_KEY, _value);
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.20, Graphics.FONT_XTINY, "KCAL PER BEER",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.44, Graphics.FONT_NUMBER_MEDIUM, _value.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.68, Graphics.FONT_XTINY,
            "UP +" + CALORIES_PER_BEER_STEP.format("%d") + "   DOWN -" + CALORIES_PER_BEER_STEP.format("%d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(width / 2, height * 0.80, Graphics.FONT_XTINY, "START to save",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

(:glance)
class CaloriesPickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as CaloriesPickerView;

    function initialize(view as CaloriesPickerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // UP on a button watch, swipe up on a touch one
    function onPreviousPage() as Boolean {
        _view.adjust(CALORIES_PER_BEER_STEP);
        return true;
    }

    function onNextPage() as Boolean {
        _view.adjust(-CALORIES_PER_BEER_STEP);
        return true;
    }

    function onSelect() as Boolean {
        _view.save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Leaving without pressing START discards the change
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
