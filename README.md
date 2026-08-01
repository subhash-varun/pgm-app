# 🏢 PG Manager - Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen?style=for-the-badge)](https://flutter.dev)
[![Download APK](https://img.shields.io/badge/Download-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://drive.google.com/drive/folders/1Iijz5p_xi0bBxLKiCwBOYzi5Mrw_yBsh?usp=sharing)
[![License](https://img.shields.io/badge/License-Proprietary-blue?style=for-the-badge)](#)

A modern, cross-platform mobile application designed for Paying Guest (PG) property owners, administrators, and staff to manage properties, rooms, tenants, rent ledgers, maintenance tickets, and inventory with ease.

---

## 📲 Download

Grab the latest Android build directly — no build setup required.

**➡️ [Download APK (Google Drive)](https://drive.google.com/drive/folders/1Iijz5p_xi0bBxLKiCwBOYzi5Mrw_yBsh?usp=sharing)**

> **Note:** Since the app isn't distributed via the Play Store, Android may warn about installing from an unknown source. Enable *"Install unknown apps"* for your file manager/browser when prompted, then open the downloaded `.apk` to install.

---

## 🌟 Key Features

### 📊 Dashboard & Real-Time Analytics
* **Key Metrics**: Monitor occupancy rates, total active tenants, pending rent balances, and maintenance status at a glance.
* **Interactive Charts**: Visual analytics powered by `fl_chart` showing monthly revenue trends and room availability ratios.

### 👥 Tenant Lifecycle & Offboarding Management
* **Directory & Filtering**: Search and filter tenants by status (`ACTIVE`, `ON_NOTICE`, `EXITED`).
* **Tenant Profiles**: Complete records including contact details, room allocation, security deposit, emergency contacts, and ID proofs.
* **Notice & Exit Workflows**: Initiate notice periods and calculate automated final exit settlements (deposit refunds minus pending dues).

### 🏠 Room & Property Management
* **Room Inventory**: Track room availability, capacity, sharing type, floor details, and pricing.
* **Status Tracking**: Filter rooms by status (`AVAILABLE`, `OCCUPIED`, `MAINTENANCE`) and room types.
* **Quick Allocations**: Easily assign or reassign tenants to rooms.

### 💰 Financials & Rent Ledger System
* **Monthly Rent Ledgers**: Generate and manage monthly rent ledgers for all active tenants.
* **Payment Processing**: Record payments with multiple payment methods (UPI, Cash, Bank Transfer, Cheque) and custom notes.
* **Dues & Overdue Tracking**: Real-time identification of overdue payments with automated ledger balance updates.

### 🛠️ Maintenance Request Workflow
* **Ticket Tracking**: Manage maintenance issues categorized by priority (`LOW`, `MEDIUM`, `HIGH`, `URGENT`) and status (`PENDING`, `IN_PROGRESS`, `RESOLVED`, `CANCELLED`).
* **Staff Assignment**: Assign maintenance tickets directly to relevant staff members.

### 📦 Asset & Inventory Control
* **Property Assets**: Catalog furniture, appliances, and amenities across properties.
* **Quantity & Status Monitoring**: Track stock counts and maintenance status of inventory items.

### 🔐 Security & Role-Based Access Control (RBAC)
* **JWT Authentication**: Secure login with automatic token refresh and session persistence via Dio interceptors.
* **Granular Permissions**: Dynamic feature access control based on user roles (`SUPER_ADMIN`, `ADMIN`, `STAFF`).
* **Role & User Management**: Admin interface to create roles and configure permission matrices.

### 🔔 Notifications & Preferences
* **In-App Notifications**: Real-time notifications for payment reminders, maintenance updates, and tenant alerts.
* **Preferences**: Custom notification toggles and unread counters.

### 🎨 Modern UI & Dark Mode
* **Design System**: Customized Material 3 theme (`AppTheme`) supporting system-matched light and dark modes.

---

## 🏗️ Architecture & Project Structure

The project follows a clean, layered architectural pattern:

```text
lib/
├── core/                  # Core infrastructure & configuration
│   ├── api_client.dart    # Dio HTTP client, baseUrl, and auth interceptors
│   ├── api_logger.dart    # Custom logging interceptor for API requests
│   ├── auth_service.dart  # Global authentication state store
│   ├── formatters.dart    # Currency, date, and text formatting utilities
│   └── theme.dart         # Material 3 light/dark theme definitions
├── models/                # Data models with JSON serialization
│   ├── tenant.dart        # Tenant & settlement summary models
│   ├── room.dart          # Room & occupancy models
│   ├── payment.dart       # Payment transaction models
│   ├── rent_ledger.dart   # Monthly rent ledger models
│   ├── maintenance_request.dart # Maintenance ticket models
│   ├── inventory_item.dart# Inventory item models
│   ├── staff.dart         # Staff member models
│   ├── app_notification.dart # Notification models
│   └── user.dart          # User, Admin, Role & Permission models
├── services/              # API communication layer
│   └── api_services.dart  # Strongly typed REST API calls via Dio
├── widgets/               # Reusable UI components & dialogs
└── screens/               # Application views organized by feature
    ├── admin/             # System admin & user management
    ├── auth/              # Login & security screens
    ├── inventory/         # Inventory management screens
    ├── notifications/     # Notification list & preference settings
    ├── payments/          # Rent ledger & payment tracking
    ├── permissions/       # RBAC permission management
    ├── profile_screen.dart# User profile & account details
    ├── roles/             # Role configuration screens
    ├── rooms/             # Room list, filter & editor screens
    ├── staff/             # Staff directory & assignment
    └── tenants/           # Tenant list, notice dialog & exit settlement
```

---

## 🛠️ Tech Stack & Dependencies

* **Framework**: [Flutter](https://flutter.dev) (SDK `^3.11.1`)
* **Language**: [Dart](https://dart.dev)
* **HTTP Client**: [`dio: ^5.7.0`](https://pub.dev/packages/dio) - Advanced HTTP requests with request/response interceptors.
* **Local Storage**: [`shared_preferences: ^2.3.3`](https://pub.dev/packages/shared_preferences) - Token & settings storage.
* **Data Visualization**: [`fl_chart: ^0.69.0`](https://pub.dev/packages/fl_chart) - Interactive charts for financial and occupancy dashboards.
* **Localization & Formatting**: [`intl: ^0.19.0`](https://pub.dev/packages/intl) - Currency and date formatting.
* **Icons**: [`cupertino_icons: ^1.0.8`](https://pub.dev/packages/cupertino_icons)

---

## 🚀 Getting Started

### Option 1: Install the Pre-Built APK
The fastest way to try the app on Android — no setup required.

1. Open the **[APK download folder](https://drive.google.com/drive/folders/1Iijz5p_xi0bBxLKiCwBOYzi5Mrw_yBsh?usp=sharing)** on your Android device (or download and transfer the file).
2. Download the latest `.apk` file.
3. Allow installation from unknown sources if prompted, then install and launch the app.

### Option 2: Build from Source

#### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (`3.11.x` or higher)
* [Dart SDK](https://dart.dev/get-dart) installed
* Android Studio / VS Code with Flutter extension
* An active backend instance (or connection to the deployed Spring Boot backend)

#### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/subhash-varun/pgm-app.git
   cd pgm_app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint**
   The application communicates with the backend via `lib/core/api_client.dart`. The default production endpoint is:
   ```dart
   static const String baseUrl = 'https://pgm-backend-1.onrender.com';
   ```
   For local backend testing (e.g., Spring Boot running locally), update `baseUrl`:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8080'; // Android Emulator
   // static const String baseUrl = 'http://localhost:8080'; // iOS Simulator / Web
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```

5. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

---

## 🔌 API & Integration Details

* **Authentication Token Handling**: Authentication tokens (`Bearer <token>`) are injected into request headers automatically via Dio interceptor.
* **401 Unauthorized Interception**: Expired sessions clear saved tokens and prompt user re-authentication automatically.
* **Standardized Pagination**: Uses a unified `PageData<T>` wrapper for paginated endpoints (`content`, `totalElements`, `totalPages`, etc.).

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
