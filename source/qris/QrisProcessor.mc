import Toybox.Lang;

module Qris {
    //! Result of QRIS validation or payload generation.
    class QrisResult {
        var isValid as Boolean;
        var payload as String;
        var errorMessage as String;
        var data as QrisData?;

        function initialize(valid as Boolean, outPayload as String, err as String, parsed as QrisData?) {
            isValid = valid;
            payload = outPayload;
            errorMessage = err;
            data = parsed;
        }
    }

    //! Provider-independent QRIS processor enforcing EMVCo & QRIS rules.
    class QrisProcessor {
        static const MAX_AMOUNT_IDR = 10000000;
        static const MAX_PAYLOAD_LEN = 360;

        //! Validates a merchant's base QRIS payload.
        static function validateStaticPayload(raw as String) as QrisResult {
            if (raw.length() == 0) {
                return new QrisResult(false, "", "Payload QRIS kosong", null);
            }
            if (raw.length() > MAX_PAYLOAD_LEN) {
                return new QrisResult(false, "", "Payload terlalu panjang", null);
            }
            if (!Crc16.verify(raw)) {
                return new QrisResult(false, "", "CRC16 QRIS tidak valid", null);
            }

            var data = QrisParser.parse(raw);
            if (data == null) {
                return new QrisResult(false, "", "Format TLV QRIS rusak", null);
            }
            if (!data.payloadFormat.equals("01")) {
                return new QrisResult(false, "", "Tag 00 harus '01'", null);
            }
            if (!data.hasMerchantAccount) {
                return new QrisResult(false, "", "Data merchant (26-45/51) hilang", null);
            }
            if (!data.currency.equals("360")) {
                return new QrisResult(false, "", "Mata uang bukan IDR (360)", null);
            }
            if (!data.country.toUpper().equals("ID")) {
                return new QrisResult(false, "", "Kode negara bukan ID", null);
            }
            if (data.merchantName.length() == 0) {
                return new QrisResult(false, "", "Nama merchant (Tag 59) kosong", null);
            }

            return new QrisResult(true, raw, "", data);
        }

        //! Builds a validated payment QRIS payload for the requested IDR amount.
        //! tag01Mode: "12" (Dynamic), "11" (Static + Amount), or "static_only".
        static function buildPaymentPayload(raw as String, amountIdr as Number, tag01Mode as String) as QrisResult {
            var baseCheck = validateStaticPayload(raw);
            if (!baseCheck.isValid || baseCheck.data == null) {
                return baseCheck;
            }

            if (amountIdr == 0) {
                return baseCheck;
            }

            if (amountIdr < 0 || amountIdr > MAX_AMOUNT_IDR) {
                return new QrisResult(false, "", "Nominal di luar batas (maks Rp10jt)", null);
            }
            if (tag01Mode.equals("static_only")) {
                return new QrisResult(false, "", "Mode Statis Saja aktif", null);
            }

            var baseData = baseCheck.data as QrisData;
            if (baseData.hasFeeTags) {
                return new QrisResult(false, "", "QRIS memiliki tag tip/biaya (55-57)", null);
            }

            var targetTag01 = tag01Mode.equals("11") ? "11" : "12";
            var amountStr = amountIdr.toString();

            var rebuilt = "";
            var inserted01 = false;
            var inserted54 = false;

            var count = baseData.entries.size();
            for (var i = 0; i < count; i++) {
                var entry = baseData.entries[i];
                var tag = entry.tag;

                if (tag.equals("63")) {
                    continue;
                } else if (tag.equals("01")) {
                    rebuilt += (new TlvEntry("01", targetTag01)).encode();
                    inserted01 = true;
                } else if (tag.equals("54")) {
                    rebuilt += (new TlvEntry("54", amountStr)).encode();
                    inserted54 = true;
                } else {
                    if (!inserted01 && tag.equals("00")) {
                        rebuilt += entry.encode();
                        rebuilt += (new TlvEntry("01", targetTag01)).encode();
                        inserted01 = true;
                        continue;
                    }
                    rebuilt += entry.encode();
                    if (tag.equals("53") && !inserted54) {
                        rebuilt += (new TlvEntry("54", amountStr)).encode();
                        inserted54 = true;
                    }
                }
            }

            if (!inserted54) {
                rebuilt += (new TlvEntry("54", amountStr)).encode();
            }

            var bodyWith6304 = rebuilt + "6304";
            var newCrc = Crc16.compute(bodyWith6304);
            var finalPayload = bodyWith6304 + newCrc;

            return validateStaticPayload(finalPayload);
        }
    }
}
