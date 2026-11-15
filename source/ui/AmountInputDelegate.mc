import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    //! Input delegate for Page 2 (Stepper Amount Picker): handles step pills, +/- buttons, swipe/UP-DOWN, and QR generation.
    class AmountInputDelegate extends WatchUi.BehaviorDelegate {
        private var _view as AmountInputView;

        function initialize(view as AmountInputView) {
            BehaviorDelegate.initialize();
            _view = view;
        }

        private function goToStaticPage() as Void {
            WatchUi.switchToView(new StaticQrView(), new StaticQrDelegate(), WatchUi.SLIDE_DOWN);
        }

        private function generateAndShowQr() as Void {
            var merchant = Store.MerchantStore.getActiveMerchant();
            if (merchant == null) {
                _view.setError("Atur QRIS di Connect IQ");
                return;
            }
            if (!merchant.isValid) {
                _view.setError(merchant.errorMessage);
                return;
            }

            var amount = _view.getAmount();
            var mode = Store.MerchantStore.getTag01Mode();
            var res = Qris.QrisProcessor.buildPaymentPayload(merchant.rawPayload, amount, mode);
            if (!res.isValid) {
                _view.setError(res.errorMessage);
                return;
            }

            Store.HistoryStore.addRecord(merchant.displayName, amount);
            var qrView = new QrDisplayView(merchant.displayName, amount, res.payload);
            WatchUi.pushView(qrView, new QrDisplayDelegate(), WatchUi.SLIDE_UP);
        }

        function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_DOWN || dir == WatchUi.SWIPE_RIGHT) {
                goToStaticPage();
                return true;
            }
            return false;
        }

        function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
            var key = keyEvent.getKey();
            if (key == WatchUi.KEY_UP) {
                goToStaticPage();
                return true;
            } else if (key == WatchUi.KEY_DOWN || key == WatchUi.KEY_MENU) {
                MenuController.openMainMenu(1);
                return true;
            } else if (key == WatchUi.KEY_ENTER) {
                generateAndShowQr();
                return true;
            }
            return false;
        }

        function onMenu() as Boolean {
            MenuController.openMainMenu(1);
            return true;
        }

        function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
            var coords = clickEvent.getCoordinates();
            var tx = coords[0];
            var ty = coords[1];

            if (ty >= AmountInputView.STEP_Y && ty <= AmountInputView.STEP_Y + AmountInputView.STEP_H) {
                for (var i = 0; i < AmountInputView.STEP_VALUES.size(); i++) {
                    var sx = AmountInputView.STEP_START_X + i * (AmountInputView.STEP_W + AmountInputView.STEP_GAP);
                    if (tx >= sx && tx <= sx + AmountInputView.STEP_W) {
                        _view.setStepIndex(i);
                        return true;
                    }
                }
            }

            if (tx >= AmountInputView.BTN_INC_X && tx <= AmountInputView.BTN_INC_X + AmountInputView.BTN_INC_W &&
                ty >= AmountInputView.BTN_INC_Y && ty <= AmountInputView.BTN_INC_Y + AmountInputView.BTN_INC_H) {
                _view.stepUp();
                return true;
            }

            if (tx >= AmountInputView.BTN_DEC_X && tx <= AmountInputView.BTN_DEC_X + AmountInputView.BTN_DEC_W &&
                ty >= AmountInputView.BTN_DEC_Y && ty <= AmountInputView.BTN_DEC_Y + AmountInputView.BTN_DEC_H) {
                _view.stepDown();
                return true;
            }

            if (tx >= AmountInputView.BTN_CLR_X && tx <= AmountInputView.BTN_CLR_X + AmountInputView.BTN_CLR_W &&
                ty >= AmountInputView.BTN_CLR_Y && ty <= AmountInputView.BTN_CLR_Y + AmountInputView.BTN_CLR_H) {
                _view.clearAmount();
                return true;
            }

            if (tx >= AmountInputView.BTN_QR_X && tx <= AmountInputView.BTN_QR_X + AmountInputView.BTN_QR_W &&
                ty >= AmountInputView.BTN_QR_Y && ty <= AmountInputView.BTN_QR_Y + AmountInputView.BTN_QR_H) {
                generateAndShowQr();
                return true;
            }

            return false;
        }
    }
}
