import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class garmin_terima_qrisApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Store.MerchantStore.reloadFromSettings();
    }

    function onStop(state as Dictionary?) as Void {
    }

    function onSettingsChanged() as Void {
        Store.MerchantStore.reloadFromSettings();
        WatchUi.requestUpdate();
    }

    //! Page 1 (Static QRIS) is the initial screen; users slide or press DOWN for Page 2.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new Ui.StaticQrView(), new Ui.StaticQrDelegate() ];
    }

}

function getApp() as garmin_terima_qrisApp {
    return Application.getApp() as garmin_terima_qrisApp;
}
