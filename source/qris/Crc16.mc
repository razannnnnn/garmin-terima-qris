import Toybox.Lang;

//! CRC16-CCITT (False) calculator for EMVCo / QRIS Tag 63.
//! Polynomial: 0x1021, Initial value: 0xFFFF, No final XOR.
module Qris {
    class Crc16 {
        private static const HEX_CHARS = "0123456789ABCDEF";

        //! Computes 4-character uppercase hex CRC16-CCITT for an ASCII string.
        static function compute(data as String) as String {
            var crc = 0xFFFF;
            var chars = data.toCharArray();
            var len = chars.size();

            for (var i = 0; i < len; i++) {
                var b = chars[i].toNumber() & 0xFF;
                crc = crc ^ (b << 8);
                for (var bit = 0; bit < 8; bit++) {
                    if ((crc & 0x8000) != 0) {
                        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
                    } else {
                        crc = (crc << 1) & 0xFFFF;
                    }
                }
            }

            return toHex4(crc);
        }

        //! Verifies that a QRIS payload ends with "6304" + matching 4-hex CRC16.
        static function verify(payload as String) as Boolean {
            var len = payload.length();
            if (len < 8) {
                return false;
            }
            var tagAndLen = payload.substring(len - 8, len - 4);
            if (tagAndLen == null || !tagAndLen.equals("6304")) {
                return false;
            }
            var body = payload.substring(0, len - 4);
            var expectedCrc = payload.substring(len - 4, len);
            if (body == null || expectedCrc == null) {
                return false;
            }
            var computed = compute(body);
            return computed.equals(expectedCrc.toUpper());
        }

        private static function toHex4(val as Number) as String {
            var out = "";
            for (var shift = 12; shift >= 0; shift -= 4) {
                var nibble = (val >> shift) & 0x0F;
                var ch = HEX_CHARS.substring(nibble, nibble + 1);
                if (ch != null) {
                    out += ch;
                }
            }
            return out;
        }
    }
}
