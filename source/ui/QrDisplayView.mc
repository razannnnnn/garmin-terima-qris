import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    //! Displays the generated dynamic (or static) QRIS code with amount & Selesai button (matches ui_2.jpg).
    class QrDisplayView extends WatchUi.View {
        static const BTN_DONE_X = 135;
        static const BTN_DONE_Y = 344;
        static const BTN_DONE_W = 120;
        static const BTN_DONE_H = 32;

        private var _merchantName as String;
        private var _amount as Number;
        private var _payload as String;
        private var _runner as QrEncodeRunner;

        function initialize(merchantName as String, amount as Number, payload as String) {
            View.initialize();
            _merchantName = merchantName;
            _amount = amount;
            _payload = payload;
            _runner = new QrEncodeRunner();
        }

        function onShow() as Void {
            _runner.start(_payload);
        }

        function onHide() as Void {
            _runner.stop();
        }

        function onUpdate(dc as Dc) as Void {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            var cx = dc.getWidth() / 2;

            // Header: a.n. <MERCHANT>
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 22, Graphics.FONT_XTINY, "a.n. " + _merchantName, Graphics.TEXT_JUSTIFY_CENTER);

            if (_runner.matrix != null) {
                var bottomY = QrRenderHelper.drawQrCode(dc, _runner.matrix as Qr.QrMatrix, cx, 50, 244);
                if (_amount > 0) {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(cx, bottomY + 6, Graphics.FONT_LARGE, QrRenderHelper.formatIdr(_amount), Graphics.TEXT_JUSTIFY_CENTER);
                }
            } else if (_runner.isEncoding()) {
                dc.setColor(0x9A9AA0, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 175, Graphics.FONT_SMALL, "Membuat QR...", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                QrRenderHelper.drawErrorBox(dc, "Gagal Encode QR", "Payload terlalu besar");
            }

            // Selesai pill button
            dc.setColor(0x2E2E34, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(BTN_DONE_X, BTN_DONE_Y, BTN_DONE_W, BTN_DONE_H, 16);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, BTN_DONE_Y + BTN_DONE_H / 2, Graphics.FONT_XTINY, "Selesai", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
