import Toybox.Lang;

module Qris {
    //! Represents a single EMVCo TLV entry (Tag, Value).
    class TlvEntry {
        var tag as String;
        var value as String;

        function initialize(t as String, v as String) {
            tag = t;
            value = v;
        }

        function encode() as String {
            var len = value.length();
            var lenStr = len < 10 ? ("0" + len.toString()) : len.toString();
            return tag + lenStr + value;
        }
    }

    //! Parsed representation of an EMVCo QRIS payload.
    class QrisData {
        var entries as Array<TlvEntry>;
        var payloadFormat as String = "";
        var pointOfInitiation as String = "";
        var merchantName as String = "";
        var merchantCity as String = "";
        var currency as String = "";
        var country as String = "";
        var amount as String = "";
        var crc as String = "";
        var hasMerchantAccount as Boolean = false;
        var hasFeeTags as Boolean = false;

        function initialize() {
            entries = [] as Array<TlvEntry>;
        }
    }

    //! Strict EMVCo TLV parser for QRIS payloads.
    class QrisParser {
        //! Parses a raw QRIS string into QrisData, or returns null if malformed.
        static function parse(raw as String) as QrisData? {
            var totalLen = raw.length();
            if (totalLen < 12) {
                return null;
            }

            var data = new QrisData();
            var idx = 0;

            while (idx < totalLen) {
                if (idx + 4 > totalLen) {
                    return null;
                }
                var tag = raw.substring(idx, idx + 2);
                var lenStr = raw.substring(idx + 2, idx + 4);
                if (tag == null || lenStr == null || !isTwoDigits(tag) || !isTwoDigits(lenStr)) {
                    return null;
                }

                var valLen = lenStr.toNumber();
                if (valLen == null || valLen < 0 || idx + 4 + valLen > totalLen) {
                    return null;
                }

                var val = raw.substring(idx + 4, idx + 4 + valLen);
                if (val == null) {
                    return null;
                }

                var entry = new TlvEntry(tag, val);
                data.entries.add(entry);
                assignKnownField(data, tag, val);

                idx += 4 + valLen;
            }

            return data;
        }

        private static function assignKnownField(data as QrisData, tag as String, val as String) as Void {
            if (tag.equals("00")) {
                data.payloadFormat = val;
            } else if (tag.equals("01")) {
                data.pointOfInitiation = val;
            } else if (tag.equals("53")) {
                data.currency = val;
            } else if (tag.equals("54")) {
                data.amount = val;
            } else if (tag.equals("55") || tag.equals("56") || tag.equals("57")) {
                data.hasFeeTags = true;
            } else if (tag.equals("58")) {
                data.country = val;
            } else if (tag.equals("59")) {
                data.merchantName = val;
            } else if (tag.equals("60")) {
                data.merchantCity = val;
            } else if (tag.equals("63")) {
                data.crc = val;
            } else {
                var tagNum = tag.toNumber();
                if (tagNum != null && ((tagNum >= 26 && tagNum <= 45) || tagNum == 51)) {
                    data.hasMerchantAccount = true;
                }
            }
        }

        private static function isTwoDigits(s as String) as Boolean {
            if (s.length() != 2) {
                return false;
            }
            var chars = s.toCharArray();
            for (var i = 0; i < 2; i++) {
                var c = chars[i].toNumber();
                if (c < 48 || c > 57) {
                    return false;
                }
            }
            return true;
        }
    }
}
