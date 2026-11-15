import Toybox.Lang;

module Qr {
    //! Holds a generated square QR code matrix.
    class QrMatrix {
        var size as Number;
        var version as Number;
        // 1 = dark, 0 = light, stored row-major (y * size + x)
        var modules as Array<Number>;

        function initialize(sz as Number, ver as Number, mods as Array<Number>) {
            size = sz;
            version = ver;
            modules = mods;
        }

        function isDark(x as Number, y as Number) as Boolean {
            return modules[y * size + x] == 1;
        }
    }

    //! Incremental QR encoding session to stay well below Connect IQ's Watchdog limit.
    class QrEncodeSession {
        var isDone as Boolean = false;
        var matrix as QrMatrix?;

        private var _version as Number;
        private var _spec as Array<Number>;
        private var _dataBytes as Array<Number>;
        private var _gen as Array<Number>?;
        private var _dataBlocks as Array<Array<Number> >;
        private var _eccBlocks as Array<Array<Number> >;
        private var _phase as Number = 0; // 0=init, 1=rs blocks, 2=matrix
        private var _blockIdx as Number = 0;
        private var _byteOffset as Number = 0;
        private var _rsState as Array<Number>?;
        private var _rsHead as Number = 0;
        private var _finalCw as Array<Number>?;
        private var _matSize as Number = 0;
        private var _isFunc as Array<Number>?;
        private var _baseMod as Array<Number>?;

        function initialize(version as Number, spec as Array<Number>, dataBytes as Array<Number>) {
            _version = version;
            _spec = spec;
            _dataBytes = dataBytes;
            _dataBlocks = [] as Array<Array<Number> >;
            _eccBlocks = [] as Array<Array<Number> >;
        }

        //! Advances encoding by one small watchdog-safe chunk (~1,200 inner ops max).
        function step() as Boolean {
            if (isDone) {
                return true;
            }
            if (_phase == 0) {
                var ecLen = _spec[1];
                _gen = QrEncoder.rsGeneratorPolyPublic(ecLen);
                var g1Blocks = _spec[2];
                var g1Len = _spec[3];
                var g2Blocks = _spec[4];
                var g2Len = _spec[5];
                var off = 0;
                for (var b = 0; b < g1Blocks; b++) {
                    _dataBlocks.add(_dataBytes.slice(off, off + g1Len));
                    off += g1Len;
                }
                for (var b = 0; b < g2Blocks; b++) {
                    _dataBlocks.add(_dataBytes.slice(off, off + g2Len));
                    off += g2Len;
                }
                _phase = 1;
                _blockIdx = 0;
                _byteOffset = 0;
                return false;
            }
            if (_phase == 1) {
                var ecLen = _spec[1];
                if (_blockIdx >= _dataBlocks.size()) {
                    _phase = 2;
                    return false;
                }
                var blk = _dataBlocks[_blockIdx];
                if (_rsState == null) {
                    var st = new [ecLen] as Array<Number>;
                    for (var i = 0; i < ecLen; i++) { st[i] = 0; }
                    _rsState = st;
                    _rsHead = 0;
                    _byteOffset = 0;
                }
                var endByte = _byteOffset + 35;
                if (endByte > blk.size()) {
                    endByte = blk.size();
                }
                _rsHead = QrEncoder.rsStepChunk(blk, _byteOffset, endByte, ecLen, _gen as Array<Number>, _rsState as Array<Number>, _rsHead);
                _byteOffset = endByte;
                if (_byteOffset >= blk.size()) {
                    _eccBlocks.add(QrEncoder.rsFinalizeRing(_rsState as Array<Number>, _rsHead, ecLen));
                    _rsState = null;
                    _blockIdx++;
                }
                return false;
            }
            if (_phase == 2) {
                _finalCw = QrEncoder.interleaveBlocksPublic(_dataBlocks, _eccBlocks, _spec);
                _matSize = 17 + _version * 4;
                var total = _matSize * _matSize;
                _isFunc = new [total] as Array<Number>;
                _baseMod = new [total] as Array<Number>;
                for (var i = 0; i < total; i++) {
                    (_isFunc as Array<Number>)[i] = 0;
                    (_baseMod as Array<Number>)[i] = 0;
                }
                QrEncoder.placeFunctionPatternsPublic(_baseMod as Array<Number>, _isFunc as Array<Number>, _matSize, _version);
                _phase = 3;
                return false;
            }
            if (_phase == 3) {
                QrEncoder.placeCodewordsPublic(_baseMod as Array<Number>, _isFunc as Array<Number>, _matSize, _finalCw as Array<Number>);
                _phase = 4;
                return false;
            }
            // _phase == 4: mask + format/version info
            var mods = _baseMod as Array<Number>;
            var funcs = _isFunc as Array<Number>;
            QrEncoder.applyMaskInPlacePublic(mods, funcs, _matSize);
            QrEncoder.placeFormatInfoPublic(mods, _matSize, 0);
            if (_version >= 7) {
                QrEncoder.placeVersionInfoPublic(mods, _matSize, _version);
            }
            matrix = new QrMatrix(_matSize, _version, mods);
            isDone = true;
            return true;
        }
    }

    //! Pure Monkey C QR Code Encoder (Model 2, Byte Mode, ECC Level L, Versions 1-12).
    class QrEncoder {
        // [totalDataCodewords, ecPerBlock, numBlocksGroup1, dataPerBlockGroup1, numBlocksGroup2, dataPerBlockGroup2]
        private static const VERSION_SPEC = [
            [19, 7, 1, 19, 0, 0],     // V1  (21x21, max 17B)
            [34, 10, 1, 34, 0, 0],    // V2  (25x25, max 32B)
            [55, 15, 1, 55, 0, 0],    // V3  (29x29, max 53B)
            [80, 20, 1, 80, 0, 0],    // V4  (33x33, max 78B)
            [108, 26, 1, 108, 0, 0],  // V5  (37x37, max 106B)
            [136, 18, 2, 68, 0, 0],   // V6  (41x41, max 134B)
            [156, 20, 2, 78, 0, 0],   // V7  (45x45, max 154B)
            [194, 24, 2, 97, 0, 0],   // V8  (49x49, max 192B)
            [232, 30, 2, 116, 0, 0],  // V9  (53x53, max 230B)
            [274, 18, 2, 68, 2, 69],  // V10 (57x57, max 271B)
            [324, 20, 4, 81, 0, 0],   // V11 (61x61, max 321B)
            [370, 24, 2, 92, 2, 93]   // V12 (65x65, max 367B)
        ];

        private static const ALIGN_COORDS = [
            [],
            [6, 18],
            [6, 22],
            [6, 26],
            [6, 30],
            [6, 34],
            [6, 22, 38],
            [6, 24, 42],
            [6, 26, 46],
            [6, 28, 50],
            [6, 30, 54],
            [6, 32, 58]
        ];

        private static var _gfExp as Array<Number>?;
        private static var _gfLog as Array<Number>?;
        private static var _cachePayload as String = "";
        private static var _cacheMatrix as QrMatrix?;

        static function getCached(text as String) as QrMatrix? {
            if (_cacheMatrix != null && text.equals(_cachePayload)) {
                return _cacheMatrix;
            }
            return null;
        }

        static function putCache(text as String, mat as QrMatrix) as Void {
            _cachePayload = text;
            _cacheMatrix = mat;
        }

        //! Creates an incremental QrEncodeSession for UI views (watchdog-safe).
        static function createSession(text as String) as QrEncodeSession? {
            var bytes = toByteArray(text);
            var version = selectVersion(bytes.size());
            if (version < 0) {
                return null;
            }
            var spec = VERSION_SPEC[version - 1] as Array<Number>;
            var dataBytes = encodeDataCodewords(bytes, version, spec[0]);
            return new QrEncodeSession(version, spec, dataBytes);
        }

        static function rsGeneratorPolyPublic(ecLen as Number) as Array<Number> {
            return rsGeneratorPoly(ecLen);
        }

        static function rsStepChunk(data as Array<Number>, startIdx as Number, endIdx as Number, ecLen as Number, gen as Array<Number>, res as Array<Number>, head as Number) as Number {
            var exp = _gfExp as Array<Number>;
            var log = _gfLog as Array<Number>;
            for (var i = startIdx; i < endIdx; i++) {
                var factor = data[i] ^ res[head];
                res[head] = 0;
                head++;
                if (head == ecLen) {
                    head = 0;
                }
                if (factor != 0) {
                    var logFactor = log[factor];
                    var pos = head;
                    for (var j = 0; j < ecLen; j++) {
                        var g = gen[j + 1];
                        if (g != 0) {
                            res[pos] = res[pos] ^ exp[log[g] + logFactor];
                        }
                        pos++;
                        if (pos == ecLen) {
                            pos = 0;
                        }
                    }
                }
            }
            return head;
        }

        static function rsFinalizeRing(res as Array<Number>, head as Number, ecLen as Number) as Array<Number> {
            if (head == 0) {
                return res;
            }
            var ordered = new [ecLen] as Array<Number>;
            for (var i = 0; i < ecLen; i++) {
                ordered[i] = res[(head + i) % ecLen];
            }
            return ordered;
        }

        static function interleaveBlocksPublic(dataBlocks as Array<Array<Number> >, eccBlocks as Array<Array<Number> >, spec as Array<Number>) as Array<Number> {
            var ecLen = spec[1];
            var g1DataLen = spec[3];
            var g2Blocks = spec[4];
            var g2DataLen = spec[5];
            var out = [] as Array<Number>;
            var maxDataLen = g2Blocks > 0 ? g2DataLen : g1DataLen;
            var totalBlocks = dataBlocks.size();
            for (var i = 0; i < maxDataLen; i++) {
                for (var b = 0; b < totalBlocks; b++) {
                    if (i < dataBlocks[b].size()) {
                        out.add(dataBlocks[b][i]);
                    }
                }
            }
            for (var i = 0; i < ecLen; i++) {
                for (var b = 0; b < totalBlocks; b++) {
                    out.add(eccBlocks[b][i]);
                }
            }
            return out;
        }

        static function placeFunctionPatternsPublic(mods as Array<Number>, isFunc as Array<Number>, size as Number, version as Number) as Void {
            placeFunctionPatterns(mods, isFunc, size, version);
        }

        static function placeCodewordsPublic(mods as Array<Number>, isFunc as Array<Number>, size as Number, codewords as Array<Number>) as Void {
            placeCodewords(mods, isFunc, size, codewords);
        }

        static function applyMaskInPlacePublic(mods as Array<Number>, isFunc as Array<Number>, size as Number) as Void {
            applyMaskInPlace(mods, isFunc, size, 0);
        }

        static function placeFormatInfoPublic(mods as Array<Number>, size as Number, mask as Number) as Void {
            placeFormatInfo(mods, size, mask);
        }

        static function placeVersionInfoPublic(mods as Array<Number>, size as Number, version as Number) as Void {
            placeVersionInfo(mods, size, version);
        }

        //! Encodes an ASCII/UTF-8 string into a QrMatrix, or returns null if too long (>367 bytes).
        static function encode(text as String) as QrMatrix? {
            var sess = createSession(text);
            if (sess == null) {
                return null;
            }
            while (!sess.step()) {
            }
            return sess.matrix;
        }

        private static function toByteArray(text as String) as Array<Number> {
            var chars = text.toCharArray();
            var n = chars.size();
            var out = new [n] as Array<Number>;
            for (var i = 0; i < n; i++) {
                out[i] = chars[i].toNumber() & 0xFF;
            }
            return out;
        }

        private static function selectVersion(byteLen as Number) as Number {
            for (var v = 1; v <= 12; v++) {
                var totalData = (VERSION_SPEC[v - 1] as Array<Number>)[0];
                var cap = v <= 9 ? (totalData - 2) : (totalData - 3);
                if (byteLen <= cap) {
                    return v;
                }
            }
            return -1;
        }

        private static function encodeDataCodewords(bytes as Array<Number>, version as Number, totalData as Number) as Array<Number> {
            var bits = [] as Array<Number>;
            // Mode 0100 (Byte)
            appendBits(bits, 4, 4);
            // Character count
            var countBits = version <= 9 ? 8 : 16;
            appendBits(bits, bytes.size(), countBits);
            // Payload bytes
            for (var i = 0; i < bytes.size(); i++) {
                appendBits(bits, bytes[i], 8);
            }
            // Terminator (up to 4 zero bits)
            var maxBits = totalData * 8;
            var term = maxBits - bits.size();
            if (term > 4) {
                term = 4;
            }
            for (var t = 0; t < term; t++) {
                bits.add(0);
            }
            // Pad to byte boundary
            while ((bits.size() % 8) != 0) {
                bits.add(0);
            }

            var codewords = [] as Array<Number>;
            for (var b = 0; b < bits.size(); b += 8) {
                var val = 0;
                for (var k = 0; k < 8; k++) {
                    val = (val << 1) | bits[b + k];
                }
                codewords.add(val);
            }

            // Pad bytes 0xEC, 0x11
            var padToggle = true;
            while (codewords.size() < totalData) {
                codewords.add(padToggle ? 0xEC : 0x11);
                padToggle = !padToggle;
            }

            return codewords;
        }

        private static function appendBits(bits as Array<Number>, val as Number, len as Number) as Void {
            for (var i = len - 1; i >= 0; i--) {
                bits.add((val >> i) & 1);
            }
        }

        private static function ensureGfTables() as Void {
            if (_gfExp != null) {
                return;
            }
            var exp = new [512] as Array<Number>;
            var log = new [256] as Array<Number>;
            var x = 1;
            for (var i = 0; i < 255; i++) {
                exp[i] = x;
                log[x] = i;
                x = x << 1;
                if (x >= 256) {
                    x = x ^ 0x11D;
                }
            }
            for (var i = 255; i < 512; i++) {
                exp[i] = exp[i - 255];
            }
            log[0] = 0;
            _gfExp = exp;
            _gfLog = log;
        }

        private static function gfMul(a as Number, b as Number) as Number {
            if (a == 0 || b == 0) {
                return 0;
            }
            var log = _gfLog as Array<Number>;
            var exp = _gfExp as Array<Number>;
            return exp[log[a] + log[b]];
        }

        private static function rsGeneratorPoly(ecLen as Number) as Array<Number> {
            ensureGfTables();
            var exp = _gfExp as Array<Number>;
            var poly = [1] as Array<Number>;
            for (var i = 0; i < ecLen; i++) {
                var next = new [poly.size() + 1] as Array<Number>;
                for (var z = 0; z < next.size(); z++) {
                    next[z] = 0;
                }
                var root = exp[i];
                for (var j = 0; j < poly.size(); j++) {
                    next[j] = next[j] ^ poly[j];
                    next[j + 1] = next[j + 1] ^ gfMul(poly[j], root);
                }
                poly = next;
            }
            return poly;
        }

        private static function setFunc(mods as Array<Number>, isFunc as Array<Number>, size as Number, x as Number, y as Number, dark as Boolean) as Void {
            var idx = y * size + x;
            mods[idx] = dark ? 1 : 0;
            isFunc[idx] = 1;
        }

        private static function placeFinder(mods as Array<Number>, isFunc as Array<Number>, size as Number, cx as Number, cy as Number) as Void {
            for (var dy = -4; dy <= 4; dy++) {
                for (var dx = -4; dx <= 4; dx++) {
                    var xx = cx + dx;
                    var yy = cy + dy;
                    if (xx >= 0 && xx < size && yy >= 0 && yy < size) {
                        var adx = dx < 0 ? -dx : dx;
                        var ady = dy < 0 ? -dy : dy;
                        var dist = adx > ady ? adx : ady;
                        var dark = (dist != 2 && dist != 4);
                        setFunc(mods, isFunc, size, xx, yy, dark);
                    }
                }
            }
        }

        private static function placeAlignment(mods as Array<Number>, isFunc as Array<Number>, size as Number, cx as Number, cy as Number) as Void {
            for (var dy = -2; dy <= 2; dy++) {
                for (var dx = -2; dx <= 2; dx++) {
                    var adx = dx < 0 ? -dx : dx;
                    var ady = dy < 0 ? -dy : dy;
                    var dist = adx > ady ? adx : ady;
                    setFunc(mods, isFunc, size, cx + dx, cy + dy, dist != 1);
                }
            }
        }

        private static function placeFunctionPatterns(mods as Array<Number>, isFunc as Array<Number>, size as Number, version as Number) as Void {
            // Timing patterns
            for (var i = 0; i < size; i++) {
                setFunc(mods, isFunc, size, 6, i, (i % 2) == 0);
                setFunc(mods, isFunc, size, i, 6, (i % 2) == 0);
            }

            // Finder patterns
            placeFinder(mods, isFunc, size, 3, 3);
            placeFinder(mods, isFunc, size, size - 4, 3);
            placeFinder(mods, isFunc, size, 3, size - 4);

            // Alignment patterns
            var coords = ALIGN_COORDS[version - 1] as Array<Number>;
            var n = coords.size();
            for (var i = 0; i < n; i++) {
                for (var j = 0; j < n; j++) {
                    if (!((i == 0 && j == 0) || (i == 0 && j == n - 1) || (i == n - 1 && j == 0))) {
                        placeAlignment(mods, isFunc, size, coords[i], coords[j]);
                    }
                }
            }

            // Reserve format info areas
            for (var i = 0; i <= 8; i++) {
                if (i != 6) {
                    setFunc(mods, isFunc, size, 8, i, false);
                    setFunc(mods, isFunc, size, i, 8, false);
                }
            }
            for (var i = 0; i < 8; i++) {
                setFunc(mods, isFunc, size, size - 1 - i, 8, false);
                setFunc(mods, isFunc, size, 8, size - 1 - i, false);
            }
            // Dark module
            setFunc(mods, isFunc, size, 8, size - 8, true);

            // Reserve version info areas for V >= 7
            if (version >= 7) {
                for (var i = 0; i < 6; i++) {
                    for (var j = 0; j < 3; j++) {
                        setFunc(mods, isFunc, size, size - 11 + j, i, false);
                        setFunc(mods, isFunc, size, i, size - 11 + j, false);
                    }
                }
            }
        }

        private static function placeCodewords(mods as Array<Number>, isFunc as Array<Number>, size as Number, codewords as Array<Number>) as Void {
            var bitIdx = 0;
            var totalBits = codewords.size() * 8;
            var upward = true;

            for (var right = size - 1; right >= 1; right -= 2) {
                if (right == 6) {
                    right = 5;
                }
                for (var vert = 0; vert < size; vert++) {
                    var y = upward ? (size - 1 - vert) : vert;
                    for (var j = 0; j < 2; j++) {
                        var x = right - j;
                        var idx = y * size + x;
                        if (isFunc[idx] == 0) {
                            var dark = false;
                            if (bitIdx < totalBits) {
                                var cw = codewords[bitIdx >> 3];
                                dark = ((cw >> (7 - (bitIdx & 7))) & 1) == 1;
                                bitIdx++;
                            }
                            mods[idx] = dark ? 1 : 0;
                        }
                    }
                }
                upward = !upward;
            }
        }

        private static function applyMaskInPlace(mods as Array<Number>, isFunc as Array<Number>, size as Number, mask as Number) as Void {
            for (var y = 0; y < size; y++) {
                var rowOff = y * size;
                for (var x = 0; x < size; x++) {
                    var idx = rowOff + x;
                    if (isFunc[idx] == 0 && ((x + y) % 2) == 0) {
                        mods[idx] = 1 - mods[idx];
                    }
                }
            }
        }

        private static function placeFormatInfo(mods as Array<Number>, size as Number, mask as Number) as Void {
            // ECC Level L = 01 (bits: 01xxx)
            var data = (1 << 3) | mask;
            var rem = data;
            for (var i = 0; i < 10; i++) {
                rem = (rem << 1) ^ (((rem >> 9) & 1) * 0x537);
            }
            var bits = ((data << 10) | rem) ^ 0x5412;

            for (var i = 0; i <= 5; i++) {
                mods[i * size + 8] = (bits >> i) & 1;
            }
            mods[7 * size + 8] = (bits >> 6) & 1;
            mods[8 * size + 8] = (bits >> 7) & 1;
            mods[8 * size + 7] = (bits >> 8) & 1;
            for (var i = 9; i < 15; i++) {
                mods[8 * size + (14 - i)] = (bits >> i) & 1;
            }

            for (var i = 0; i < 8; i++) {
                mods[8 * size + (size - 1 - i)] = (bits >> i) & 1;
            }
            for (var i = 8; i < 15; i++) {
                mods[(size - 15 + i) * size + 8] = (bits >> i) & 1;
            }
        }

        private static function placeVersionInfo(mods as Array<Number>, size as Number, version as Number) as Void {
            var rem = version;
            for (var i = 0; i < 12; i++) {
                rem = (rem << 1) ^ (((rem >> 11) & 1) * 0x1F25);
            }
            var bits = (version << 12) | rem;

            for (var i = 0; i < 18; i++) {
                var bit = (bits >> i) & 1;
                var a = size - 11 + (i % 3);
                var b = i / 3;
                mods[b * size + a] = bit;
                mods[a * size + b] = bit;
            }
        }

        private static function computePenaltyFast(mods as Array<Number>, size as Number) as Number {
            var penalty = 0;
            var darkCount = 0;
            var total = size * size;
            for (var i = 0; i < total; i++) {
                if (mods[i] == 1) {
                    darkCount++;
                }
            }
            // Sample row runs every 2 rows for speed
            for (var y = 0; y < size; y += 2) {
                var rowOff = y * size;
                var runColor = -1;
                var runLen = 0;
                for (var x = 0; x < size; x++) {
                    var v = mods[rowOff + x];
                    if (v == runColor) {
                        runLen++;
                        if (runLen == 5) { penalty += 3; }
                        else if (runLen > 5) { penalty += 1; }
                    } else {
                        runColor = v;
                        runLen = 1;
                    }
                }
            }
            var pctDiff = ((darkCount * 100) / total) - 50;
            if (pctDiff < 0) { pctDiff = -pctDiff; }
            penalty += (pctDiff / 5) * 10;
            return penalty;
        }
    }
}
