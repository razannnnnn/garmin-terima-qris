import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;

module Store {
    class MerchantProfile {
        var slotIndex as Number;
        var displayName as String;
        var city as String;
        var rawPayload as String;
        var isValid as Boolean;
        var errorMessage as String;
        var isDemo as Boolean;

        function initialize(idx as Number, name as String, cty as String, raw as String, valid as Boolean, err as String, demo as Boolean) {
            slotIndex = idx;
            displayName = name;
            city = cty;
            rawPayload = raw;
            isValid = valid;
            errorMessage = err;
            isDemo = demo;
        }
    }

    //! Syncs and validates merchant QRIS profiles from Connect IQ App Settings into Application.Storage.
    class MerchantStore {
        private static const STORAGE_ACTIVE_KEY = "wp_active_idx";
        private static const STORAGE_PROP_ACTIVE_KEY = "wp_prop_active_idx";
        private static const DEMO_QRIS = "00020101021126610014ID.CO.QRIS.WWW01189360091400000000000210ID000000010303UMI51440014ID.CO.QRIS.WWW0215ID10200000000010303UMI5204599253033605802ID5911LANDFLORIST6007JAKARTA61051011063043571";

        private static var _merchants as Array<MerchantProfile> = [] as Array<MerchantProfile>;
        private static var _activeIndex as Number = 0;

        static function reloadFromSettings() as Void {
            var list = [] as Array<MerchantProfile>;
            var aliasKeys = ["m1_alias", "m2_alias", "m3_alias", "m4_alias", "m5_alias"];
            var payloadKeys = ["m1_payload", "m2_payload", "m3_payload", "m4_payload", "m5_payload"];

            for (var i = 0; i < 5; i++) {
                var raw = trimAscii(getStringProp(payloadKeys[i]));
                var customName = trimAscii(getStringProp(aliasKeys[i]));
                if (raw.length() > 0) {
                    var res = Qris.QrisProcessor.validateStaticPayload(raw);
                    var name = customName.length() > 0 ? customName : ("Merchant " + (i + 1).toString());
                    var city = "";
                    if (res.isValid && res.data != null) {
                        var d = res.data as Qris.QrisData;
                        if (customName.length() == 0) {
                            name = d.merchantName;
                        }
                        city = d.merchantCity;
                    }
                    list.add(new MerchantProfile(i, name, city, raw, res.isValid, res.errorMessage, false));
                }
            }

            if (list.size() == 0 && getBoolProp("enable_demo_merchant", true)) {
                var demoRes = Qris.QrisProcessor.validateStaticPayload(DEMO_QRIS);
                var demoName = "LANDFLORIST";
                var demoCity = "JAKARTA";
                if (demoRes.isValid && demoRes.data != null) {
                    var d = demoRes.data as Qris.QrisData;
                    demoName = d.merchantName;
                    demoCity = d.merchantCity;
                }
                list.add(new MerchantProfile(0, demoName, demoCity, DEMO_QRIS, demoRes.isValid, demoRes.errorMessage, true));
            }

            _merchants = list;

            var propActive = getNumProp("active_merchant_index", 0);
            var prevPropActive = Storage.getValue(STORAGE_PROP_ACTIVE_KEY);
            var storedActive = Storage.getValue(STORAGE_ACTIVE_KEY);
            var targetSlot = propActive;
            if (prevPropActive instanceof Number && (prevPropActive as Number) == propActive && storedActive instanceof Number) {
                targetSlot = storedActive as Number;
            } else {
                Storage.setValue(STORAGE_PROP_ACTIVE_KEY, propActive);
                Storage.setValue(STORAGE_ACTIVE_KEY, propActive);
            }

            var matchedPos = 0;
            for (var i = 0; i < _merchants.size(); i++) {
                if (_merchants[i].slotIndex == targetSlot) {
                    matchedPos = i;
                    break;
                }
            }
            _activeIndex = matchedPos;
        }

        static function getMerchants() as Array<MerchantProfile> {
            return _merchants;
        }

        static function getActiveMerchant() as MerchantProfile? {
            if (_merchants.size() == 0) {
                return null;
            }
            if (_activeIndex < 0 || _activeIndex >= _merchants.size()) {
                _activeIndex = 0;
            }
            return _merchants[_activeIndex];
        }

        static function setActiveByListIndex(idx as Number) as Void {
            if (idx >= 0 && idx < _merchants.size()) {
                _activeIndex = idx;
                Storage.setValue(STORAGE_ACTIVE_KEY, _merchants[idx].slotIndex);
            }
        }

        static function getTag01Mode() as String {
            var m = getNumProp("amount_tag01_mode", 0);
            if (m == 1) {
                return "11";
            } else if (m == 2) {
                return "static_only";
            }
            return "12";
        }

        static function trimAscii(s as String) as String {
            var chars = s.toCharArray();
            var start = 0;
            var end = chars.size() - 1;
            while (start <= end) {
                var c = chars[start].toNumber();
                if (c == 32 || c == 9 || c == 10 || c == 13) { start++; }
                else { break; }
            }
            while (end >= start) {
                var c = chars[end].toNumber();
                if (c == 32 || c == 9 || c == 10 || c == 13) { end--; }
                else { break; }
            }
            if (start > end) {
                return "";
            }
            var sub = s.substring(start, end + 1);
            return sub != null ? sub : "";
        }

        private static function getStringProp(key as String) as String {
            try {
                var v = Properties.getValue(key);
                if (v instanceof String) {
                    return (v as String);
                }
            } catch (e) {
            }
            return "";
        }

        private static function getBoolProp(key as String, fallback as Boolean) as Boolean {
            try {
                var v = Properties.getValue(key);
                if (v instanceof Boolean) {
                    return (v as Boolean);
                }
            } catch (e) {
            }
            return fallback;
        }

        private static function getNumProp(key as String, fallback as Number) as Number {
            try {
                var v = Properties.getValue(key);
                if (v instanceof Number) {
                    return (v as Number);
                }
            } catch (e) {
            }
            return fallback;
        }
    }
}
