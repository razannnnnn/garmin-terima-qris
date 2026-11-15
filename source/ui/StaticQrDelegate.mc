import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    //! Input delegate for Page 1 (Static QRIS): supports swipe, UP/DOWN buttons, and Menu.
    class StaticQrDelegate extends WatchUi.BehaviorDelegate {
        function initialize() {
            BehaviorDelegate.initialize();
        }

        private function goToAmountPage() as Void {
            var v = new AmountInputView(0);
            WatchUi.switchToView(v, new AmountInputDelegate(v), WatchUi.SLIDE_UP);
        }

        function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_UP || dir == WatchUi.SWIPE_LEFT) {
                goToAmountPage();
                return true;
            }
            return false;
        }

        function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
            var key = keyEvent.getKey();
            if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_ENTER) {
                goToAmountPage();
                return true;
            } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_MENU) {
                MenuController.openMainMenu(0);
                return true;
            }
            return false;
        }

        function onMenu() as Boolean {
            MenuController.openMainMenu(0);
            return true;
        }

        function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
            var coords = clickEvent.getCoordinates();
            var y = coords[1];
            if (y < 60) {
                MenuController.openMainMenu(0);
                return true;
            } else if (y > 335) {
                goToAmountPage();
                return true;
            }
            return false;
        }
    }
}
