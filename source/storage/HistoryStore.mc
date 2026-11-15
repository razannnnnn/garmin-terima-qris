import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

module Store {
    //! Stores local QR generation records (never falsely marks payments as paid).
    class HistoryStore {
        private static const STORAGE_KEY = "wp_history_v1";
        private static const MAX_ITEMS = 20;

        static function addRecord(merchantName as String, amountIdr as Number) as Void {
            var list = getRecords();
            var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var timeStr = now.hour.format("%02d") + ":" + now.min.format("%02d") +
                          " " + now.day.format("%02d") + "/" + now.month.format("%02d");

            var entry = {
                "merchant" => merchantName,
                "amount" => amountIdr,
                "time" => timeStr,
                "status" => "QR Dibuat"
            } as Dictionary<String, Object>;

            var updated = [entry] as Array<Dictionary<String, Object> >;
            var limit = list.size() < (MAX_ITEMS - 1) ? list.size() : (MAX_ITEMS - 1);
            for (var i = 0; i < limit; i++) {
                updated.add(list[i]);
            }
            Storage.setValue(STORAGE_KEY, updated);
        }

        static function getRecords() as Array<Dictionary<String, Object> > {
            var val = Storage.getValue(STORAGE_KEY);
            if (val instanceof Array) {
                return val as Array<Dictionary<String, Object> >;
            }
            return [] as Array<Dictionary<String, Object> >;
        }

        static function clear() as Void {
            Storage.deleteValue(STORAGE_KEY);
        }
    }
}
