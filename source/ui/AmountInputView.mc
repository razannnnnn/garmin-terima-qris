import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    //! Page 2: Garmin-style vertical stepper picker (▲ / ▼ + 1rb/5rb/10rb step) for custom QRIS amount.
    class AmountInputView extends WatchUi.View {
        static const STEP_VALUES = [500, 1000, 5000, 10000];
        static const STEP_LABELS = ["500", "1rb", "5rb", "10rb"];

        static const STEP_Y = 54;
        static const STEP_H = 34;
        static const STEP_W = 60;
        static const STEP_GAP = 8;
        static const STEP_START_X = 63; // (390 - (4*60 + 3*8)) / 2

        static const BTN_INC_X = 95;
        static const BTN_INC_Y = 102;
        static const BTN_INC_W = 200;
        static const BTN_INC_H = 54;

        static const BTN_DEC_X = 95;
        static const BTN_DEC_Y = 222;
        static const BTN_DEC_W = 200;
        static const BTN_DEC_H = 54;

        static const BTN_CLR_X = 64;
        static const BTN_CLR_Y = 290;
        static const BTN_CLR_W = 52;
        static const BTN_CLR_H = 44;

        static const BTN_QR_X = 124;
        static const BTN_QR_Y = 290;
        static const BTN_QR_W = 202;
        static const BTN_QR_H = 44;

        private var _amount as Number = 0;
        private var _stepIdx as Number = 0;
        private var _errorBanner as String = "";

        function initialize(initialAmount as Number) {
            View.initialize();
            _amount = initialAmount;
        }

        function getAmount() as Number {
            return _amount;
        }

        function setAmount(val as Number) as Void {
            _amount = val;
            _errorBanner = "";
            WatchUi.requestUpdate();
        }

        function setError(msg as String) as Void {
            _errorBanner = msg;
            WatchUi.requestUpdate();
        }

        function setStepIndex(idx as Number) as Void {
            if (idx >= 0 && idx < STEP_VALUES.size()) {
                _stepIdx = idx;
                _errorBanner = "";
                WatchUi.requestUpdate();
            }
        }

        function stepUp() as Void {
            _errorBanner = "";
            var step = STEP_VALUES[_stepIdx];
            var next = _amount + step;
            if (next <= Qris.QrisProcessor.MAX_AMOUNT_IDR) {
                _amount = next;
            } else {
                _amount = Qris.QrisProcessor.MAX_AMOUNT_IDR;
                _errorBanner = "Maks Rp10.000.000";
            }
            WatchUi.requestUpdate();
        }

        function stepDown() as Void {
            _errorBanner = "";
            var step = STEP_VALUES[_stepIdx];
            var next = _amount - step;
            _amount = next > 0 ? next : 0;
            WatchUi.requestUpdate();
        }

        function clearAmount() as Void {
            _errorBanner = "";
            _amount = 0;
            WatchUi.requestUpdate();
        }

        function onUpdate(dc as Dc) as Void {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            var cx = dc.getWidth() / 2;

            // Step Selector Pills: 500 | 1rb | 5rb | 10rb
            for (var i = 0; i < STEP_LABELS.size(); i++) {
                var sx = STEP_START_X + i * (STEP_W + STEP_GAP);
                var isActive = (i == _stepIdx);
                dc.setColor(isActive ? 0x00A859 : 0x28282D, Graphics.COLOR_BLACK);
                dc.fillRoundedRectangle(sx, STEP_Y, STEP_W, STEP_H, 17);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(sx + STEP_W / 2, STEP_Y + STEP_H / 2, Graphics.FONT_XTINY, STEP_LABELS[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            // Increment (+) Button
            dc.setColor(0x28282D, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(BTN_INC_X, BTN_INC_Y, BTN_INC_W, BTN_INC_H, 16);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, BTN_INC_Y + BTN_INC_H / 2, Graphics.FONT_MEDIUM, "+", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Center Amount Display
            var amountText = QrRenderHelper.formatIdr(_amount);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 189, Graphics.FONT_LARGE, amountText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Decrement (-) Button
            dc.setColor(0x28282D, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(BTN_DEC_X, BTN_DEC_Y, BTN_DEC_W, BTN_DEC_H, 16);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, BTN_DEC_Y + BTN_DEC_H / 2, Graphics.FONT_MEDIUM, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Bottom Action Row: C + TAMPILKAN QR
            dc.setColor(0x28282D, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(BTN_CLR_X, BTN_CLR_Y, BTN_CLR_W, BTN_CLR_H, 22);
            dc.setColor(0xFF2E63, Graphics.COLOR_TRANSPARENT);
            dc.drawText(BTN_CLR_X + BTN_CLR_W / 2, BTN_CLR_Y + BTN_CLR_H / 2, Graphics.FONT_SMALL, "C", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(0x00A859, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(BTN_QR_X, BTN_QR_Y, BTN_QR_W, BTN_QR_H, 22);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(BTN_QR_X + BTN_QR_W / 2, BTN_QR_Y + BTN_QR_H / 2, Graphics.FONT_XTINY, "TAMPILKAN QR", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (_errorBanner.length() > 0) {
                dc.setColor(0xFF2E63, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 344, Graphics.FONT_XTINY, _errorBanner, Graphics.TEXT_JUSTIFY_CENTER);
            }

            QrRenderHelper.drawPageIndicator(dc, 1);
        }
    }
}
