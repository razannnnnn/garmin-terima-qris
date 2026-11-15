import Toybox.Lang;
import Toybox.Test;

const TEST_QRIS_SAMPLE = "00020101021126610014ID.CO.QRIS.WWW01189360091400000000000210ID000000010303UMI51440014ID.CO.QRIS.WWW0215ID10200000000010303UMI5204599253033605802ID5911LANDFLORIST6007JAKARTA61051011063043571";

(:test)
function testCrc16StandardVector(logger as Logger) as Boolean {
    // Standard CRC16-CCITT (False) of "123456789" is 0x29B1
    var crc = Qris.Crc16.compute("123456789");
    logger.debug("CRC(123456789) = " + crc);
    Test.assertEqual(crc, "29B1");
    return true;
}

(:test)
function testQrisStaticValidation(logger as Logger) as Boolean {
    var res = Qris.QrisProcessor.validateStaticPayload(TEST_QRIS_SAMPLE);
    Test.assertMessage(res.isValid, "Expected valid QRIS: " + res.errorMessage);
    Test.assert(res.data != null);
    var d = res.data as Qris.QrisData;
    Test.assertEqual(d.merchantName, "TESTING");
    Test.assertEqual(d.merchantCity, "JAKARTA");
    Test.assertEqual(d.currency, "360");
    Test.assertEqual(d.country, "ID");
    return true;
}

(:test)
function testQrisRejectsBadCrcAndCurrency(logger as Logger) as Boolean {
    var badCrc = TEST_QRIS_SAMPLE.substring(0, TEST_QRIS_SAMPLE.length() - 4) + "0000";
    var res1 = Qris.QrisProcessor.validateStaticPayload(badCrc);
    Test.assert(!res1.isValid);

    var res2 = Qris.QrisProcessor.validateStaticPayload("00020153038406304ABCD");
    Test.assert(!res2.isValid);
    return true;
}

(:test)
function testQrisDynamicAmountInjection(logger as Logger) as Boolean {
    var res = Qris.QrisProcessor.buildPaymentPayload(TEST_QRIS_SAMPLE, 5000, "12");
    Test.assertMessage(res.isValid, "Dynamic build failed: " + res.errorMessage);
    Test.assert(Qris.Crc16.verify(res.payload));

    var parsed = Qris.QrisParser.parse(res.payload);
    Test.assert(parsed != null);
    var d = parsed as Qris.QrisData;
    Test.assertEqual(d.pointOfInitiation, "12");
    Test.assertEqual(d.amount, "5000");
    Test.assertEqual(d.merchantName, "TESTING");

    // Static-only mode should reject amount > 0
    var rejected = Qris.QrisProcessor.buildPaymentPayload(TEST_QRIS_SAMPLE, 5000, "static_only");
    Test.assert(!rejected.isValid);
    return true;
}

(:test)
function testQrisModesFeeRejectionTrimAndFormat(logger as Logger) as Boolean {
    // Mode "11" keeps Tag 01 = "11" while injecting Tag 54
    var res11 = Qris.QrisProcessor.buildPaymentPayload(TEST_QRIS_SAMPLE, 15000, "11");
    Test.assertMessage(res11.isValid, "Mode 11 failed: " + res11.errorMessage);
    var d11 = Qris.QrisParser.parse(res11.payload) as Qris.QrisData;
    Test.assertEqual(d11.pointOfInitiation, "11");
    Test.assertEqual(d11.amount, "15000");

    // Amount 0 returns original static payload unchanged
    var res0 = Qris.QrisProcessor.buildPaymentPayload(TEST_QRIS_SAMPLE, 0, "12");
    Test.assert(res0.isValid);
    Test.assertEqual(res0.payload, TEST_QRIS_SAMPLE);

    // Payload with Tag 55 (tip/fee) must be rejected for amount injection
    var feeBody = "00020101021126180014ID.CO.QRIS.WWW53033605502015802ID5904TEST6304";
    var feePayload = feeBody + Qris.Crc16.compute(feeBody);
    var feeRes = Qris.QrisProcessor.buildPaymentPayload(feePayload, 5000, "12");
    Test.assert(!feeRes.isValid);

    // Trimming pasted whitespace and IDR formatting
    Test.assertEqual(Store.MerchantStore.trimAscii("  " + TEST_QRIS_SAMPLE + "\r\n "), TEST_QRIS_SAMPLE);
    Test.assertEqual(Ui.QrRenderHelper.formatIdr(0), "Rp0");
    Test.assertEqual(Ui.QrRenderHelper.formatIdr(5000), "Rp5.000");
    Test.assertEqual(Ui.QrRenderHelper.formatIdr(1250000), "Rp1.250.000");
    return true;
}
