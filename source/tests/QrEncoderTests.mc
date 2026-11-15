import Toybox.Lang;
import Toybox.Test;

(:test)
function testQrEncoderShortAndQris(logger as Logger) as Boolean {
    var m1 = Qr.QrEncoder.encode("HELLO WORLD");
    Test.assert(m1 != null);
    var mat1 = m1 as Qr.QrMatrix;
    Test.assertEqual(mat1.version, 1);
    Test.assertEqual(mat1.size, 21);

    // Top-left finder pattern corner should be dark (1) and separator (7,0) light (0)
    Test.assert(mat1.isDark(0, 0));
    Test.assert(!mat1.isDark(7, 0));

    // Full QRIS dynamic payload (~190 bytes -> Version 8 or 9)
    var res = Qris.QrisProcessor.buildPaymentPayload(TEST_QRIS_SAMPLE, 25000, "12");
    Test.assert(res.isValid);
    var m2 = Qr.QrEncoder.encode(res.payload);
    Test.assert(m2 != null);
    var mat2 = m2 as Qr.QrMatrix;
    logger.debug("QRIS QR version=" + mat2.version + " size=" + mat2.size);
    Test.assert(mat2.version >= 7 && mat2.version <= 10);
    Test.assert(mat2.isDark(0, 0));
    Test.assert(mat2.isDark(mat2.size - 1, 0));
    Test.assert(mat2.isDark(0, mat2.size - 1));
    return true;
}
