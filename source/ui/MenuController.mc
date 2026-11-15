import Toybox.Lang;
import Toybox.WatchUi;

module Ui {
    //! Native Menu2 controller for Merchant Switcher, Quick Presets, History, and Merchant Info.
    class MenuController {
        static function openMainMenu(sourcePage as Number) as Void {
            var menu = new WatchUi.Menu2({ :title => "WristPay QRIS" });
            var active = Store.MerchantStore.getActiveMerchant();
            var mSub = active != null ? active.displayName : "Belum diatur";

            menu.addItem(new WatchUi.MenuItem("Pilih Merchant", mSub, :switch_merchant, null));
            menu.addItem(new WatchUi.MenuItem("Nominal Cepat", "Rp5rb - Rp100rb", :quick_presets, null));
            menu.addItem(new WatchUi.MenuItem("Riwayat QR", "Catatan lokal", :history, null));
            menu.addItem(new WatchUi.MenuItem("Info Merchant", "Status & kota", :merchant_info, null));

            WatchUi.pushView(menu, new MainMenuDelegate(sourcePage), WatchUi.SLIDE_LEFT);
        }

        static function openMerchantPicker() as Void {
            var menu = new WatchUi.Menu2({ :title => "Pilih Merchant" });
            var list = Store.MerchantStore.getMerchants();
            if (list.size() == 0) {
                menu.addItem(new WatchUi.MenuItem("Kosong", "Isi di App Connect IQ", :none, null));
            } else {
                for (var i = 0; i < list.size(); i++) {
                    var m = list[i];
                    var sub = m.isValid ? (m.isDemo ? "Demo QRIS" : m.city) : m.errorMessage;
                    menu.addItem(new WatchUi.MenuItem(m.displayName, sub, i, null));
                }
            }
            WatchUi.pushView(menu, new MerchantPickerDelegate(), WatchUi.SLIDE_LEFT);
        }

        static function openQuickPresets() as Void {
            var menu = new WatchUi.Menu2({ :title => "Nominal Cepat" });
            var presets = [5000, 10000, 15000, 20000, 25000, 50000, 100000];
            for (var i = 0; i < presets.size(); i++) {
                var amt = presets[i];
                menu.addItem(new WatchUi.MenuItem(QrRenderHelper.formatIdr(amt), "Buat QRIS Dinamis", amt, null));
            }
            WatchUi.pushView(menu, new PresetPickerDelegate(), WatchUi.SLIDE_LEFT);
        }

        static function openHistory() as Void {
            var menu = new WatchUi.Menu2({ :title => "Riwayat QR" });
            var records = Store.HistoryStore.getRecords();
            if (records.size() == 0) {
                menu.addItem(new WatchUi.MenuItem("Belum ada riwayat", "QR yang dibuat muncul di sini", :none, null));
            } else {
                for (var i = 0; i < records.size(); i++) {
                    var rec = records[i];
                    var amt = rec["amount"] as Number;
                    var merch = rec["merchant"] as String;
                    var time = rec["time"] as String;
                    var label = amt > 0 ? QrRenderHelper.formatIdr(amt) : "QR Statis";
                    menu.addItem(new WatchUi.MenuItem(label, merch + " - " + time, :none, null));
                }
                menu.addItem(new WatchUi.MenuItem("Hapus Riwayat", "Bersihkan catatan lokal", :clear_history, null));
            }
            WatchUi.pushView(menu, new HistoryMenuDelegate(), WatchUi.SLIDE_LEFT);
        }

        static function openMerchantInfo() as Void {
            var menu = new WatchUi.Menu2({ :title => "Info Merchant" });
            var m = Store.MerchantStore.getActiveMerchant();
            if (m == null) {
                menu.addItem(new WatchUi.MenuItem("Status", "Belum ada merchant", :none, null));
            } else {
                menu.addItem(new WatchUi.MenuItem("Nama", m.displayName, :none, null));
                menu.addItem(new WatchUi.MenuItem("Kota", m.city.length() > 0 ? m.city : "-", :none, null));
                menu.addItem(new WatchUi.MenuItem("Validasi", m.isValid ? "Valid (CRC OK)" : m.errorMessage, :none, null));
                menu.addItem(new WatchUi.MenuItem("Mode Tag 01", Store.MerchantStore.getTag01Mode(), :none, null));
            }
            WatchUi.pushView(menu, new SimpleBackDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
        function initialize(sourcePage as Number) {
            Menu2InputDelegate.initialize();
        }

        function onSelect(item as WatchUi.MenuItem) as Void {
            var id = item.getId();
            if (id == :switch_merchant) {
                MenuController.openMerchantPicker();
            } else if (id == :quick_presets) {
                MenuController.openQuickPresets();
            } else if (id == :history) {
                MenuController.openHistory();
            } else if (id == :merchant_info) {
                MenuController.openMerchantInfo();
            }
        }
    }

    class MerchantPickerDelegate extends WatchUi.Menu2InputDelegate {
        function initialize() {
            Menu2InputDelegate.initialize();
        }

        function onSelect(item as WatchUi.MenuItem) as Void {
            var id = item.getId();
            if (id instanceof Number) {
                Store.MerchantStore.setActiveByListIndex(id as Number);
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                WatchUi.requestUpdate();
            }
        }
    }

    class PresetPickerDelegate extends WatchUi.Menu2InputDelegate {
        function initialize() {
            Menu2InputDelegate.initialize();
        }

        function onSelect(item as WatchUi.MenuItem) as Void {
            var id = item.getId();
            if (id instanceof Number) {
                var amt = id as Number;
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                var v = new AmountInputView(amt);
                WatchUi.switchToView(v, new AmountInputDelegate(v), WatchUi.SLIDE_UP);
            }
        }
    }

    class HistoryMenuDelegate extends WatchUi.Menu2InputDelegate {
        function initialize() {
            Menu2InputDelegate.initialize();
        }

        function onSelect(item as WatchUi.MenuItem) as Void {
            if (item.getId() == :clear_history) {
                Store.HistoryStore.clear();
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            }
        }
    }

    class SimpleBackDelegate extends WatchUi.Menu2InputDelegate {
        function initialize() {
            Menu2InputDelegate.initialize();
        }
    }
}
