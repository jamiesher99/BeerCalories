import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Lang;

// Compact strip shown in the glance carousel, next to Training Status / HRV.
// Glances run in a restricted memory scope, so this deliberately draws a
// simplified mug — no handle, bubbles, or animation — rather than reusing
// BeerCaloriesView. Pressing START on the glance opens the full animated view.
(:glance)
class BeerGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        var calories = getActiveCalories();
        var beers = getBeersEarned();

        var mugWidth = h * 0.55;
        drawMiniMug(dc, mugWidth, h);

        var textX = mugWidth + w * 0.04;
        var topY = h * 0.30;
        var bottomY = h * 0.76;

        // Number fonts hold only digits, so the word is drawn separately and
        // positioned using the measured width of the number.
        var value = beers.format("%.1f");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, topY, Graphics.FONT_GLANCE_NUMBER, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var valueWidth = dc.getTextWidthInPixels(value, Graphics.FONT_GLANCE_NUMBER);
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX + valueWidth + w * 0.02, topY, Graphics.FONT_GLANCE, "beers",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, bottomY, Graphics.FONT_GLANCE, calories.format("%d") + " active kcal",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawMiniMug(dc as Dc, boxWidth as Float, h as Number) as Void {
        var cx = boxWidth / 2.0;
        var top = h * 0.12;
        var bottom = h * 0.88;
        var topHalfW = boxWidth * 0.34;
        var bottomHalfW = boxWidth * 0.25;

        var foamH = (bottom - top) * 0.22;
        var liquidTop = top + foamH;
        var liquidHalfW = topHalfW + (bottomHalfW - topHalfW) * (foamH / (bottom - top));

        // liquid
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [(cx - liquidHalfW).toNumber(), liquidTop.toNumber()],
            [(cx + liquidHalfW).toNumber(), liquidTop.toNumber()],
            [(cx + bottomHalfW).toNumber(), bottom.toNumber()],
            [(cx - bottomHalfW).toNumber(), bottom.toNumber()]
        ]);

        // foam head
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle((cx - topHalfW).toNumber(), top.toNumber(),
            (topHalfW * 2).toNumber(), foamH.toNumber());

        // separator so foam and beer stay distinct on monochrome screens
        dc.setPenWidth(2);
        dc.setColor(0x804000, Graphics.COLOR_TRANSPARENT);
        dc.drawLine((cx - liquidHalfW).toNumber(), liquidTop.toNumber(),
            (cx + liquidHalfW).toNumber(), liquidTop.toNumber());

        // glass outline
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine((cx - topHalfW).toNumber(), top.toNumber(), (cx - bottomHalfW).toNumber(), bottom.toNumber());
        dc.drawLine((cx + topHalfW).toNumber(), top.toNumber(), (cx + bottomHalfW).toNumber(), bottom.toNumber());
        dc.drawLine((cx - bottomHalfW).toNumber(), bottom.toNumber(), (cx + bottomHalfW).toNumber(), bottom.toNumber());
    }
}
