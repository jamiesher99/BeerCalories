import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Lang;

// Referenced by AppBase.getInitialView(), which the compiler builds into the
// glance scope as well, so the symbol has to resolve there too.
(:glance)
class BeerCaloriesView extends WatchUi.View {

    private var _timer as Timer.Timer?;
    private var _foamPhase as Float = 0.0;

    // Bubbles rising through the beer. Positions are fractions of the liquid
    // area: x 0=left wall..1=right wall, y 0=liquid surface..1=glass bottom.
    private var _bubbleX as Array<Float> = [0.28, 0.50, 0.68, 0.40, 0.58, 0.35];
    private var _bubbleY as Array<Float> = [0.10, 0.55, 0.85, 0.35, 0.95, 0.70];
    private var _bubbleSpeed as Array<Float> = [0.028, 0.021, 0.033, 0.017, 0.026, 0.030];
    private var _bubbleR as Array<Number> = [2, 2, 1, 2, 2, 1];

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:onTimerTick), 90, true);
    }

    // Stop the animation timer so a backgrounded widget doesn't drain battery
    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTimerTick() as Void {
        _foamPhase += 0.25;

        for (var i = 0; i < _bubbleY.size(); i++) {
            var y = _bubbleY[i] - _bubbleSpeed[i];
            _bubbleY[i] = y < 0.0 ? 1.0 : y;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawBeerMug(dc, width, height);
        drawCalorieInfo(dc, width, height);
    }

    // Largest number font whose 3-line block still fits the band under the mug,
    // so nothing is clipped by the bezel on small or round screens.
    private function pickNumberFont(dc as Dc, band as Float, captionH as Number) as Graphics.FontDefinition {
        var candidates = [
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM
        ];
        for (var i = 0; i < candidates.size(); i++) {
            if (dc.getFontHeight(candidates[i]) + captionH * 2 <= band) {
                return candidates[i];
            }
        }
        return Graphics.FONT_SMALL;
    }

    private function drawCalorieInfo(dc as Dc, width as Number, height as Number) as Void {
        var calories = getActiveCalories();
        var beers = getBeersEarned();

        var bandTop = height * 0.47;
        var bandBottom = height * 0.88;
        var captionH = dc.getFontHeight(Graphics.FONT_XTINY);
        var numberFont = pickNumberFont(dc, bandBottom - bandTop, captionH);
        var numberH = dc.getFontHeight(numberFont);

        // Centre the whole block in the band rather than stacking from the top
        var y = bandTop + ((bandBottom - bandTop) - (numberH + captionH * 2)) / 2;

        // Number fonts contain only digits and separators, so the word "beers"
        // has to be drawn separately in a text font.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y, numberFont, beers.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y + numberH, Graphics.FONT_XTINY, "BEERS EARNED", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, y + numberH + captionH, Graphics.FONT_XTINY,
            calories.format("%d") + " active kcal", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Half-width of the tapered glass at vertical fraction t (0=rim, 1=base)
    private function wallHalfWidth(t as Float, topHalfW as Float, bottomHalfW as Float) as Float {
        return topHalfW + (bottomHalfW - topHalfW) * t;
    }

    private function drawBeerMug(dc as Dc, width as Number, height as Number) as Void {
        var cx = width / 2.0;

        var glassTop = height * 0.10;
        var glassBottom = height * 0.44;
        var glassHeight = glassBottom - glassTop;
        var topHalfW = width * 0.155;
        var bottomHalfW = width * 0.112;

        var foamTop = glassTop + glassHeight * 0.04;
        var foamHeight = glassHeight * 0.16;
        var liquidTop = foamTop + foamHeight;
        var liquidTopT = (liquidTop - glassTop) / glassHeight;
        var liquidHeight = glassBottom - liquidTop;

        // --- handle ---
        var handleRadius = width * 0.065;
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            (cx + wallHalfWidth(0.42, topHalfW, bottomHalfW) + handleRadius * 0.6).toNumber(),
            (glassTop + glassHeight * 0.42).toNumber(),
            handleRadius.toNumber(),
            Graphics.ARC_CLOCKWISE,
            110,
            250
        );

        // --- liquid ---
        var liquidTopHalfW = wallHalfWidth(liquidTopT, topHalfW, bottomHalfW) - 3;
        var baseHalfW = bottomHalfW - 3;
        // Bright amber so it survives quantisation to white on 1-bit MIP screens
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [(cx - liquidTopHalfW).toNumber(), liquidTop.toNumber()],
            [(cx + liquidTopHalfW).toNumber(), liquidTop.toNumber()],
            [(cx + baseHalfW).toNumber(), (glassBottom - 3).toNumber()],
            [(cx - baseHalfW).toNumber(), (glassBottom - 3).toNumber()]
        ]);

        // --- rising bubbles ---
        // Dark against the liquid, so they stay visible once the amber
        // collapses to white on monochrome displays.
        dc.setColor(0x804000, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < _bubbleY.size(); i++) {
            var t = _bubbleY[i];
            var by = liquidTop + t * liquidHeight;
            var rowHalfW = wallHalfWidth(liquidTopT + t * (1.0 - liquidTopT), topHalfW, bottomHalfW) - 5;
            var bx = cx - rowHalfW + _bubbleX[i] * rowHalfW * 2;
            dc.fillCircle(bx.toNumber(), by.toNumber(), _bubbleR[i]);
        }

        // --- foam ---
        var foamLeft = cx - wallHalfWidth(liquidTopT, topHalfW, bottomHalfW) + 2;
        var foamRight = cx + wallHalfWidth(liquidTopT, topHalfW, bottomHalfW) - 2;
        var foamWidth = foamRight - foamLeft;
        dc.setColor(0xF5EEDC, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(foamLeft.toNumber(), foamTop.toNumber(), foamWidth.toNumber(), foamHeight.toNumber());

        var bumpCount = 5;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < bumpCount; i++) {
            var bx = foamLeft + (i + 0.5) * (foamWidth / bumpCount);
            var by = foamTop + Math.sin(_foamPhase + i * 1.3) * 2.0;
            dc.fillCircle(bx.toNumber(), by.toNumber(), 4);
        }

        // Separator under the head — on mono screens foam and beer are both
        // white, so without this the head disappears into the liquid.
        dc.setPenWidth(2);
        dc.setColor(0x804000, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(foamLeft.toNumber(), liquidTop.toNumber(), foamRight.toNumber(), liquidTop.toNumber());

        // --- glass outline ---
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine((cx - topHalfW).toNumber(), glassTop.toNumber(), (cx - bottomHalfW).toNumber(), glassBottom.toNumber());
        dc.drawLine((cx + topHalfW).toNumber(), glassTop.toNumber(), (cx + bottomHalfW).toNumber(), glassBottom.toNumber());
        dc.drawLine((cx - bottomHalfW).toNumber(), glassBottom.toNumber(), (cx + bottomHalfW).toNumber(), glassBottom.toNumber());

        // glass shine
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(
            (cx - topHalfW * 0.7).toNumber(), (glassTop + 6).toNumber(),
            (cx - bottomHalfW * 0.7).toNumber(), (glassBottom - 10).toNumber()
        );
    }

}
