PRODUCT REQUIREMENTS DOCUMENT (PRD)

Universal WristPay

Version: 1.0
Status: Initial Draft
Platform: Garmin Connect IQ
Target Device: Garmin Forerunner 165
Development Language: Monkey C
Product Category: FinTech / QRIS Payment Utility

---

1. Product Overview

1.1 Product Description

Universal WristPay is a personal QRIS payment application designed for Garmin smartwatches.

The application allows merchants to generate and display QR payment codes directly from their smartwatch by entering a custom transaction amount.

The primary objective is to provide a convenient, portable, and provider-independent QRIS payment experience without requiring merchants to use their smartphones for every transaction.

The application aims to support QRIS merchants from different Indonesian payment service providers and acquiring banks.

1.2 Product Vision

To transform a Garmin smartwatch into a compact QRIS payment terminal that enables merchants to generate and display payment QR codes directly from their wrist.

1.3 Core Value Proposition

- Enter payment amounts directly on a Garmin smartwatch.
- Generate QR codes with transaction amounts.
- Support multiple QRIS merchant providers.
- Display payment QR codes without opening a smartphone.
- Provide a simple and fast payment workflow.

---

2. Product Goals

The primary goals are:

1. Develop a standalone Garmin Connect IQ application.
2. Enable manual transaction amount input.
3. Support QRIS static payload parsing.
4. Investigate compliant static-to-dynamic QRIS conversion.
5. Support QRIS merchant payloads from multiple providers.
6. Generate QR codes directly from transaction data.
7. Display scannable QR codes on the Garmin Forerunner 165.
8. Maintain a lightweight application with minimal resource consumption.

2.1 Non-Goals

The initial release will not:

- Act as a payment processor.
- Hold or transfer customer funds.
- Replace official merchant acquiring services.
- Independently confirm successful payments without an authorized verification mechanism.
- Bypass QRIS or payment provider security requirements.

---

3. Target Platform

Primary Device

Garmin Forerunner 165

Target hardware characteristics:

- Display: 390 × 390 pixels.
- Display technology: AMOLED.
- Operating environment: Garmin Connect IQ.
- Application language: Monkey C.

Development Environment

- Kali Linux.
- Visual Studio Code.
- Garmin Connect IQ SDK.
- Monkey C extension.
- Garmin Connect IQ Simulator.

---

4. Core Features and Functional Requirements

FR-01: QRIS Merchant Registration

The application must allow users to register one or more existing QRIS merchant codes.

Requirements:

- Accept QRIS payload input.
- Parse QRIS merchant information.
- Validate the QRIS payload structure.
- Store registered merchant profiles.
- Allow users to switch between registered merchants.

FR-02: Manual Amount Input

Users must be able to enter a custom payment amount directly from their smartwatch.

Requirements:

- Provide an amount input interface.
- Support numeric input.
- Support Indonesian Rupiah (IDR).
- Provide increment and decrement controls.
- Provide quick amount presets.
- Validate minimum and maximum supported amounts.

Example:

Input: IDR 25,000

Selected merchant: Merchant A

FR-03: Universal QRIS Processing Engine

The application must implement a provider-independent QRIS processing engine based on the applicable QRIS and EMVCo specifications.

Requirements:

- Parse EMVCo QR payloads.
- Identify merchant information.
- Identify relevant transaction fields.
- Preserve required merchant and acquirer data.
- Support applicable transaction amount fields.
- Recalculate CRC16 when a payload is modified.
- Validate the generated payload before QR rendering.

Important technical constraint:

Adding a transaction amount to a static QRIS payload does not automatically make it an officially valid dynamic QRIS transaction.

The application must verify compatibility with applicable QRIS rules and the merchant's acquirer requirements. Unsupported transformations must be rejected rather than presented as successful payment QR codes.

FR-04: QR Code Generation

The application must generate a QR image from a validated payment payload.

Requirements:

- Generate QR codes locally when technically feasible.
- Support QR error correction.
- Use high-contrast black-and-white rendering.
- Optimize QR dimensions for the Forerunner 165 display.
- Avoid unnecessary interface elements while displaying the QR code.

FR-05: QR Display Interface

The application must provide a dedicated payment display screen.

Information displayed:

- Generated QR code.
- Transaction amount.
- Selected merchant.
- Payment instructions.

The QR code must receive maximum available screen space.

FR-06: Merchant Profile Management

Users must be able to:

- Add merchant profiles.
- Edit merchant names.
- Replace QRIS payloads.
- Select an active merchant.
- Delete merchant profiles.

FR-07: Transaction History

The application should optionally store locally:

- Transaction amount.
- Merchant profile.
- Transaction creation time.
- QR generation status.

The application must not mark a payment as successful merely because a QR code has been generated.

FR-08: Payment Verification

Payment verification is an optional advanced feature.

Possible integration methods:

- Official payment provider APIs.
- Authorized merchant transaction notifications.
- Secure backend payment status verification.

No payment status should be represented as confirmed without reliable transaction evidence.

---

5. User Experience and Application Flow

Main Application Flow

1. Open Universal WristPay.
2. Select a merchant profile.
3. Enter the transaction amount.
4. Review the transaction details.
5. Generate the payment QR code.
6. Display the QR code.
7. Customer scans the QR code.
8. Customer completes payment.
9. Merchant verifies payment through an authorized source.

Proposed Screen Structure

Screen 1: Dashboard

- Application name.
- Active merchant.
- Generate Payment option.
- Merchant Management.
- Transaction History.

Screen 2: Amount Input

- Numeric amount.
- Increment/decrement controls.
- Quick amount presets.
- Generate QR button.

Screen 3: Payment Confirmation

- Merchant name.
- Transaction amount.
- Confirmation button.

Screen 4: QR Display

- Large QR code.
- Transaction amount.
- Merchant identification.
- Back button.

Screen 5: Merchant Management

- Registered merchants.
- Add merchant.
- Edit merchant.
- Delete merchant.

---

6. Technical Architecture

Proposed Architecture

Garmin Application:

- User interface.
- Amount input.
- Merchant profile selection.
- QRIS payload processing.
- QR code generation.
- QR rendering.

Optional Backend:

- Merchant integration.
- Payment provider API communication.
- Secure credential management.
- Payment status verification.

Architecture Diagram

flowchart TD
A[Garmin Forerunner 165]
B[Universal WristPay]
C[Merchant Manager]
D[Amount Input]
E[QRIS Processing Engine]
F[QR Code Generator]
G[QR Display]

    A --> B
    B --> C
    B --> D
    C --> E
    D --> E
    E --> F
    F --> G

    E -. Optional .-> H[Secure Backend]
    H -. Authorized Integration .-> I[Payment Provider]

Technology Stack

Component| Technology
Smartwatch application| Monkey C
Development SDK| Garmin Connect IQ SDK
QRIS processing| EMVCo-compatible parser
QR generation| Lightweight QR encoder
Backend| Optional Node.js or Python
Database| Local storage / SQLite on backend
API communication| HTTPS
Testing| Connect IQ Simulator

---

7. Security Requirements

Security is a critical requirement because the application handles payment-related information.

Requirements:

- Never store payment API secrets directly in the smartwatch application.
- Validate all QRIS payloads before rendering.
- Preserve merchant identification data.
- Reject malformed or unsupported QRIS payloads.
- Protect backend credentials.
- Use HTTPS for backend communication.
- Never claim payment success without verification.
- Avoid modifying transaction data in ways that violate payment network requirements.

---

8. Performance Requirements

The application should:

- Launch quickly.
- Respond smoothly to physical button interactions.
- Generate QR codes with minimal processing overhead.
- Minimize memory consumption.
- Avoid unnecessary network requests.
- Work offline for supported static QRIS display operations.
- Remain stable during extended QR display sessions.

The generated QR must be tested using real payment applications and different smartphone cameras.

---

9. Development Roadmap

Phase 1 — Foundation

- Set up Connect IQ SDK.
- Configure Monkey C development environment.
- Create the Garmin application project.
- Test application deployment on the simulator.
- Confirm Forerunner 165 compatibility.

Phase 2 — QRIS Parser

- Implement EMVCo payload parsing.
- Extract merchant information.
- Implement CRC validation.
- Build QRIS payload validation.
- Test with multiple legitimate QRIS merchant samples.

Phase 3 — Amount Input

- Develop numeric input interface.
- Implement quick amount presets.
- Add amount validation.
- Implement merchant profile selection.

Phase 4 — QR Code Engine

- Implement QR encoding.
- Generate QR codes from validated payloads.
- Optimize QR rendering.
- Test scanning reliability.

Phase 5 — Semi-Dynamic QRIS Investigation

- Investigate applicable QRIS transaction specifications.
- Determine whether static QRIS payloads can legally and technically support the intended amount behavior.
- Evaluate acquirer compatibility.
- Reject unsupported transformations.
- Investigate official dynamic QRIS integration if required.

Phase 6 — Testing and Optimization

- Test on Garmin simulator.
- Test on actual Forerunner 165 hardware.
- Test QR scanning using multiple payment applications.
- Test different QRIS merchant providers.
- Optimize memory and performance.
- Perform security testing.

Phase 7 — Personal Deployment

- Build the final application.
- Generate the Garmin application package.
- Install the application on the personal device.
- Document the installation and configuration process.

---

10. Minimum Viable Product (MVP)

The first working release should contain:

Feature| Priority
Garmin Connect IQ application| Critical
QRIS merchant registration| Critical
Manual amount input| Critical
QRIS payload parser| Critical
CRC validation| Critical
QR code generation| Critical
QR code display| Critical
Multiple merchant profiles| High
Semi-dynamic QRIS compatibility| Research / Critical for intended final behavior
Payment verification| Future
Transaction history| Future

MVP Acceptance Criteria

The MVP is considered technically functional when:

1. The application runs on Garmin Forerunner 165.
2. Users can register a QRIS merchant payload.
3. Users can enter a custom amount.
4. The application validates the merchant payload.
5. The application generates a valid QR code for the supported payment mode.
6. The QR code can be scanned by compatible payment applications.
7. Unsupported static-to-dynamic transformations are clearly rejected.
8. The application does not falsely report successful transactions.

---

11. Project Risks and Constraints

Risk| Mitigation
Static QRIS cannot support the intended dynamic behavior| Validate against QRIS specifications and acquirer rules
Different merchant providers use different data| Use a standards-based parser and provider compatibility tests
QR code is difficult to scan on a watch| Optimize QR size and contrast
Garmin memory limitations| Use lightweight algorithms
QRIS modification rejected by payment apps| Reject unsupported payloads and investigate official dynamic integration
No payment verification API| Use authorized merchant transaction records

---

12. Future Enhancements

Potential future features:

- Dynamic QRIS integration through authorized payment providers.
- Payment notification system.
- Transaction history synchronization.
- Merchant profile synchronization.
- Custom payment presets.
- Optional smartphone companion application.
- Multi-currency support if supported by the payment infrastructure.

---

13. Final Product Definition

Universal WristPay is intended to become a lightweight, provider-independent QRIS payment utility for Garmin smartwatches.

Its primary innovation is enabling merchants to initiate payment QR generation directly from their smartwatch through a simple amount-input interface.

The project will prioritize standards compliance, QR scanning reliability, security, and compatibility with Garmin hardware.

Development principle: Build a universal QRIS foundation first, then implement semi-dynamic payment functionality only through technically valid and authorized payment mechanisms.
