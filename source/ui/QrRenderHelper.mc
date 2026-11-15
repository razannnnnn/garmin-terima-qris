import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

module Ui {
    //! Manages incremental QR encoding + cache + 50ms Timer for UI views.
    class QrEncodeRunner {
        var matrix as Qr.QrMatrix?;
        private var _payload as String = "";
        private var _session as Qr.QrEncodeSession?;
        private var _timer as Timer.Timer?;

        function start(payload as String) as Void {
            if (payload.length() == 0) {
                reset();
                return;
            }
            if (payload.equals(_payload) && matrix != null) {
                return;
            }
            var cached = Qr.QrEncoder.getCached(payload);
            if (cached != null) {
                _payload = payload;
                matrix = cached;
                _session = null;
                stop();
                return;
            }
            if (!payload.equals(_payload) || _session == null) {
                _payload = payload;
                matrix = null;
                _session = Qr.QrEncoder.createSession(_payload);
                if (_session != null) {
                    stop();
                    var t = new Timer.Timer();
                    _timer = t;
                    t.start(method(:onTick), 50, true);
                }
            }
        }

        function stop() as Void {
            if (_timer != null) {
                (_timer as Timer.Timer).stop();
                _timer = null;
            }
        }

        function reset() as Void {
            stop();
            _payload = "";
            matrix = null;
            _session = null;
        }

        function isEncoding() as Boolean {
            return _session != null;
        }

        function onTick() as Void {
            if (_session == null) {
                stop();
                return;
            }
            var sess = _session as Qr.QrEncodeSession;
            if (sess.step()) {
                matrix = sess.matrix;
                if (matrix != null) {
                    Qr.QrEncoder.putCache(_payload, matrix as Qr.QrMatrix);
                }
                _session = null;
                stop();
                WatchUi.requestUpdate();
            }
        }
    }

    //! Shared UI helpers for IDR formatting, QR matrix rendering, and page indicators.
    class QrRenderHelper {
        //! Formats integer IDR with Indonesian dot thousands separator (e.g., 5000 -> "Rp5.000").
        static function formatIdr(amount as Number) as String {
            if (amount <= 0) {
                return "Rp0";
            }
            var s = amount.toString();
            var len = s.length();
            var out = "";
            var count = 0;
            for (var i = len - 1; i >= 0; i--) {
                var ch = s.substring(i, i + 1);
                if (ch != null) {
                    out = ch + out;
                    count++;
                    if (count == 3 && i > 0) {
                        out = "." + out;
                        count = 0;
                    }
                }
            }
            return "Rp" + out;
        }

        //! Draws a QrMatrix centered horizontally inside a white square card of maxBoxSize.
        static function drawQrCode(dc as Dc, matrix as Qr.QrMatrix, centerX as Number, topY as Number, maxBoxSize as Number) as Number {
            var n = matrix.size;
            var quiet = 2;
            var totalMods = n + quiet * 2;
            var modPx = maxBoxSize / totalMods;
            if (modPx < 2) {
                modPx = 2;
            }
            var boxSize = totalMods * modPx;
            var startX = centerX - (boxSize / 2);
            var startY = topY;

            // White background card (quiet zone)
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
            dc.fillRectangle(startX, startY, boxSize, boxSize);

            // Black QR modules (run-length batched horizontally for fast rendering)
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            var qrOriginX = startX + quiet * modPx;
            var qrOriginY = startY + quiet * modPx;
            for (var y = 0; y < n; y++) {
                var py = qrOriginY + y * modPx;
                var x = 0;
                while (x < n) {
                    if (matrix.isDark(x, y)) {
                        var runStart = x;
                        while (x < n && matrix.isDark(x, y)) {
                            x++;
                        }
                        dc.fillRectangle(qrOriginX + runStart * modPx, py, (x - runStart) * modPx, modPx);
                    } else {
                        x++;
                    }
                }
            }
            return startY + boxSize;
        }

        //! Draws a 2-dot vertical page indicator on the left edge (page 0 = Static, page 1 = Numpad).
        static function drawPageIndicator(dc as Dc, activePage as Number) as Void {
            var x = 14;
            var y0 = 186;
            var y1 = 204;

            dc.setColor(activePage == 0 ? Graphics.COLOR_WHITE : 0x55555C, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y0, activePage == 0 ? 4 : 3);

            dc.setColor(activePage == 1 ? Graphics.COLOR_WHITE : 0x55555C, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, y1, activePage == 1 ? 4 : 3);
        }

        //! Draws a centered error / setup message when QRIS is missing or invalid.
        static function drawErrorBox(dc as Dc, title as String, msg as String) as Void {
            var cx = dc.getWidth() / 2;
            var cy = dc.getHeight() / 2;
            dc.setColor(0x2A151B, Graphics.COLOR_BLACK);
            dc.fillRoundedRectangle(40, cy - 55, dc.getWidth() - 80, 110, 14);
            dc.setColor(0xFF2E63, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 38, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 6, Graphics.FONT_XTINY, msg, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}
