import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    class QrDisplayDelegate extends WatchUi.BehaviorDelegate {
        function initialize() {
            BehaviorDelegate.initialize();
        }

        function onBack() as Boolean {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }

        function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
            var key = keyEvent.getKey();
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_ESC) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
            return false;
        }

        function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
            var coords = clickEvent.getCoordinates();
            var tx = coords[0];
            var ty = coords[1];

            if (tx >= QrDisplayView.BTN_DONE_X - 15 && tx <= QrDisplayView.BTN_DONE_X + QrDisplayView.BTN_DONE_W + 15 &&
                ty >= QrDisplayView.BTN_DONE_Y - 10 && ty <= QrDisplayView.BTN_DONE_Y + QrDisplayView.BTN_DONE_H + 10) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
            return false;
        }
    }
}
