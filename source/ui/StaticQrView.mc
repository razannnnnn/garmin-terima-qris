import Toybox.Graphics;
import Toybox.WatchUi;

module Ui {
    //! Page 1: Displays the active merchant's Static QRIS immediately on launch.
    class StaticQrView extends WatchUi.View {
        private var _runner as QrEncodeRunner;

        function initialize() {
            View.initialize();
            _runner = new QrEncodeRunner();
        }

        function onShow() as Void {
            syncMerchantQr();
        }

        function onHide() as Void {
            _runner.stop();
        }

        private function syncMerchantQr() as Void {
            var merchant = Store.MerchantStore.getActiveMerchant();
            if (merchant == null || !merchant.isValid) {
                _runner.reset();
                return;
            }
            _runner.start(merchant.rawPayload);
        }

        function onUpdate(dc as Dc) as Void {
            syncMerchantQr();
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            var cx = dc.getWidth() / 2;
            var merchant = Store.MerchantStore.getActiveMerchant();

            if (merchant == null) {
                QrRenderHelper.drawErrorBox(dc, "Belum Ada Merchant", "Atur QRIS di App\nGarmin Connect IQ");
                QrRenderHelper.drawPageIndicator(dc, 0);
                return;
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, 24, Graphics.FONT_XTINY, "a.n. " + merchant.displayName, Graphics.TEXT_JUSTIFY_CENTER);

            if (!merchant.isValid) {
                QrRenderHelper.drawErrorBox(dc, "QRIS Tidak Valid", merchant.errorMessage);
            } else if (_runner.matrix != null) {
                QrRenderHelper.drawQrCode(dc, _runner.matrix as Qr.QrMatrix, cx, 64, 266);
            } else if (_runner.isEncoding()) {
                dc.setColor(0x9A9AA0, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, 185, Graphics.FONT_SMALL, "Membuat QR...", Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                QrRenderHelper.drawErrorBox(dc, "Gagal Encode QR", "Payload terlalu besar");
            }

            QrRenderHelper.drawPageIndicator(dc, 0);
        }
    }
}
