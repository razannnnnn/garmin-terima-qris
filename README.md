# Universal WristPay (`garmin-terima-qris`)

> **Bilingual Documentation:** [English](#english) | [Bahasa Indonesia](#bahasa-indonesia)

---

<a name="english"></a>
## English

**Universal WristPay** is a standalone **Garmin Connect IQ** watch application written in **Monkey C** for the **Garmin Forerunner 165** (`fr165`, 390×390 AMOLED). It turns your Garmin smartwatch into a portable **QRIS (Quick Response Code Indonesian Standard)** merchant display supporting both **Static QRIS** and **Dynamic/Amount-Injected QRIS** completely offline on the watch.

### Features
- **2-Page Navigation (Touch Swipe & Physical `UP`/`DOWN` Buttons):**
  - **Page 1 — Static QRIS:** Immediately displays the active merchant's static QRIS code on launch (`a.n. <MERCHANT>`).
  - **Page 2 — Stepper Amount Picker:** Thumb-friendly `+` / `-` stepper with selectable step sizes (**`500`**, **`1rb`**, **`5rb`**, **`10rb`**), `C` reset, and **`TAMPILKAN QR`** button.
- **On-Device QR Code Encoder:** Pure Monkey C QR Code generator (Model 2, Byte mode, ECC Level L, Versions 1–12) with incremental 50ms `Timer` chunking to stay within Connect IQ's Watchdog limit.
- **EMVCo / QRIS Processing Engine:**
  - Strict TLV parsing (`00`–`63`) and **CRC16-CCITT (False)** verification.
  - Validates IDR currency (`53 = 360`), country (`58 = ID`), merchant name (`59`), and merchant account info (`26`–`45` / `51`).
  - Rejects malformed payloads or conflicting tip/convenience fee tags (`55`–`57`).
  - Injects `Tag 54` (transaction amount), updates `Tag 01` (`12` Dynamic or `11` Static+Amount, configurable), and recalculates `Tag 63` (CRC16).
- **Phone Configuration via Garmin Connect IQ App:** Configure up to **5 merchant slots** (optional display name + raw QRIS payload), active merchant, and `Tag 01` mode from your smartphone; changes sync automatically via `onSettingsChanged()`.
- **Local QR History & Menu (`Menu2`):** Switch merchants, pick quick presets, view merchant validation info, and inspect local QR generation logs (`QR Dibuat` — never falsely marks payments as paid).

### Project Structure
```text
garmin-terima-qris/
├── manifest.xml                 # Connect IQ manifest (fr165, watch-app, minApiLevel 5.2.0)
├── monkey.jungle                # Build configuration
├── resources/
│   ├── settings/
│   │   ├── properties.xml       # Default app properties (5 merchant slots, Tag 01 mode, demo toggle)
│   │   └── settings.xml         # Connect IQ mobile app settings UI schema
│   ├── strings/strings.xml      # App name & settings labels
│   └── drawables/               # Launcher icon
└── source/
    ├── garmin-terima-qrisApp.mc # AppBase lifecycle & onSettingsChanged()
    ├── qris/
    │   ├── Crc16.mc             # CRC16-CCITT (0x1021, 0xFFFF)
    │   ├── QrisParser.mc        # EMVCo TLV parser
    │   └── QrisProcessor.mc     # QRIS validation & amount injection
    ├── qr/
    │   └── QrEncoder.mc         # Pure Monkey C QR encoder + incremental QrEncodeSession
    ├── storage/
    │   ├── MerchantStore.mc     # Syncs & validates merchant slots from phone settings
    │   └── HistoryStore.mc      # Local QR generation log (max 20 entries)
    ├── ui/
    │   ├── StaticQrView.mc      # Page 1: Static QRIS display
    │   ├── StaticQrDelegate.mc  # Page 1 swipe/button handler
    │   ├── AmountInputView.mc   # Page 2: Stepper amount picker (500/1rb/5rb/10rb)
    │   ├── AmountInputDelegate.mc
    │   ├── QrDisplayView.mc     # Dynamic QRIS display + Selesai button
    │   ├── QrDisplayDelegate.mc
    │   ├── QrRenderHelper.mc    # QrEncodeRunner, IDR formatter, QR matrix renderer
    │   └── MenuController.mc    # Menu2 (Switch Merchant, Presets, History, Info)
    └── tests/
        ├── QrisTests.mc         # CRC16, parser, processor, trim & IDR format tests
        └── QrEncoderTests.mc    # QR encoder unit tests
```

### Build & Run Unit Tests
**Prerequisites:** Garmin Connect IQ SDK (tested on `9.3.0`), Java JRE/JDK, and a Monkey C developer key (`developer_key`).

```powershell
$sdk = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.3.0-2026-10-20-95888f262\bin"
$key = "$env:USERPROFILE\developer_key"

# 1. Build & run unit tests in Connect IQ Simulator
& "$sdk\monkeyc.bat" -d fr165 -f monkey.jungle -o bin\WristPay-test.prg -y $key -t -w
Start-Process "$sdk\simulator.exe"
Start-Sleep -Seconds 4
& "$sdk\monkeydo.bat" bin\WristPay-test.prg fr165 /t

# 2. Build device binary (.prg) for USB sideload
& "$sdk\monkeyc.bat" -d fr165 -f monkey.jungle -o bin\WristPay.prg -y $key -w

# 3. Build release export package (.iq) for Connect IQ Developer Dashboard
& "$sdk\monkeyc.bat" -e -r -f monkey.jungle -o bin\WristPay.iq -y $key -w
```

### Setup Your Own QRIS (DANA / GoPay / Bank / etc.)
1. Decode your static merchant QRIS image using a raw-text QR scanner app (preserving exact uppercase/lowercase characters, starting with `000201...` and ending with `6304XXXX`).
2. Upload `bin\WristPay.iq` to the [Garmin Connect IQ Developer Dashboard](https://apps.garmin.com/developer/dashboard) as a **Beta App** and install it on your watch via the Garmin Connect IQ mobile app.
3. Open **Garmin Connect IQ → My Watch Apps → WristPay QRIS → Settings** on your phone.
4. Paste the raw QRIS string into **Merchant 1 - Payload QRIS** and tap **Save**.

---

<a name="bahasa-indonesia"></a>
## Bahasa Indonesia

**Universal WristPay** adalah aplikasi smartwatch **Garmin Connect IQ** berbasis **Monkey C** untuk **Garmin Forerunner 165** (`fr165`, layar AMOLED 390×390). Aplikasi ini mengubah jam Garmin Anda menjadi media tampilan pembayaran **QRIS** portabel yang mendukung **QRIS Statis** maupun **QRIS Nominal (Dinamis)** secara offline langsung di jam.

### Fitur Utama
- **Navigasi 2 Halaman (Geser / Swipe & Tombol Fisik `UP`/`DOWN`):**
  - **Halaman 1 — QRIS Statis:** Langsung menampilkan QRIS statis merchant aktif saat aplikasi dibuka (`a.n. <MERCHANT>`).
  - **Halaman 2 — Pemilih Nominal Stepper:** Tombol besar `+` / `-` dengan pilihan kelipatan **`500`**, **`1rb`**, **`5rb`**, **`10rb`**, tombol reset **`C`**, dan tombol **`TAMPILKAN QR`**.
- **QR Code Encoder Lokal:** Generator QR Code murni Monkey C (Model 2, Byte mode, ECC Level L, Versi 1–12) dengan pemrosesan bertahap (`Timer` 50ms) agar aman dari batas Watchdog Garmin.
- **Engine QRIS / EMVCo:**
  - Parsing TLV ketat (`00`–`63`) dan validasi **CRC16-CCITT (False)**.
  - Memastikan mata uang IDR (`53 = 360`), kode negara (`58 = ID`), nama merchant (`59`), dan data akun merchant (`26`–`45` / `51`).
  - Menolak payload rusak atau payload dengan tag tip/biaya (`55`–`57`) saat injeksi nominal.
  - Menyisipkan `Tag 54` (nominal transaksi), memperbarui `Tag 01` (`12` Dinamis atau `11` Statis+Nominal, dapat diatur), dan menghitung ulang `Tag 63` (CRC16).
- **Pengaturan dari HP (Garmin Connect IQ App):** Mendukung hingga **5 slot merchant** (nama opsional + payload QRIS), pemilihan merchant aktif, dan mode `Tag 01` yang otomatis tersinkronisasi ke jam lewat `onSettingsChanged()`.
- **Riwayat QR Lokal & Menu (`Menu2`):** Ganti merchant, nominal cepat, info validasi merchant, dan catatan pembuatan QR lokal (`QR Dibuat` — tidak pernah mengklaim pembayaran berhasil tanpa verifikasi).

### Cara Build & Menjalankan Unit Test
**Prasyarat:** Garmin Connect IQ SDK (`9.3.0`), Java JRE/JDK, dan file signing key (`developer_key`).

```powershell
$sdk = "$env:APPDATA\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.3.0-2026-10-20-95888f262\bin"
$key = "$env:USERPROFILE\developer_key"

# 1. Build & jalankan unit test di Simulator
& "$sdk\monkeyc.bat" -d fr165 -f monkey.jungle -o bin\WristPay-test.prg -y $key -t -w
Start-Process "$sdk\simulator.exe"
Start-Sleep -Seconds 4
& "$sdk\monkeydo.bat" bin\WristPay-test.prg fr165 /t

# 2. Build file .prg untuk sideload USB
& "$sdk\monkeyc.bat" -d fr165 -f monkey.jungle -o bin\WristPay.prg -y $key -w

# 3. Build file .iq untuk upload ke Connect IQ Developer Dashboard
& "$sdk\monkeyc.bat" -e -r -f monkey.jungle -o bin\WristPay.iq -y $key -w
```

### Cara Memasukkan QRIS Anda (DANA / GoPay / Bank / dll.)
1. Scan gambar QRIS statis Anda memakai aplikasi QR scanner yang menampilkan **teks mentah** (*raw text*, pastikan huruf besar/kecil asli tidak berubah, berawalan `000201...` dan berakhiran `6304XXXX`).
2. Upload `bin\WristPay.iq` ke [Garmin Connect IQ Developer Dashboard](https://apps.garmin.com/developer/dashboard) sebagai **Beta App**, lalu install ke jam lewat aplikasi **Garmin Connect IQ** di HP.
3. Di HP, buka **Garmin Connect IQ → My Watch Apps → WristPay QRIS → Settings**.
4. Tempelkan teks QRIS Anda ke kolom **Merchant 1 - Payload QRIS**, lalu tekan **Save**.

> [!NOTE]
> *Disclaimer:* Aplikasi ini hanya menampilkan QRIS berdasarkan payload merchant Anda dan tidak bertindak sebagai pemroses pembayaran. Selalu pastikan notifikasi pembayaran masuk di aplikasi merchant/bank Anda.
