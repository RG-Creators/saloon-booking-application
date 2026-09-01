# 💈 Saloon Booking Application

> 💈 Comprehensive SaaS Saloon & Spa Booking Platform featuring Multi-Tenant Laravel Backend, Flutter Customer Mobile App, and Flutter Salon Owner App.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-11.x-FF2D20?logo=laravel&logoColor=white)](https://laravel.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![DevPulse AI Guarded](https://img.shields.io/badge/Security-DevPulse%20AI%20Guarded-059669.svg)](https://github.com)
[![Status: Active Development](https://img.shields.io/badge/Status-Active%20Development-3b82f6.svg)](https://github.com)

---

## 📖 Table of Contents
- [🌟 Architecture Overview](#-architecture-overview)
- [📱 Applications & Modules](#-applications--modules)
- [✨ Key Features](#-key-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [🚀 Getting Started](#-getting-started)
  - [Backend Setup (Laravel)](#1-backend-setup-laravel)
  - [Customer Mobile App Setup (Flutter)](#2-customer-mobile-app-setup-flutter)
  - [Salon Owner App Setup (Flutter)](#3-salon-owner-app-setup-flutter)
- [🔒 Security & Zero-Trust Governance](#-security--zero-trust-governance)
- [📄 License](#-license)

---

## 🌟 Architecture Overview

The **Saloon Booking Application** ecosystem is architected as a complete multi-tenant booking and management solution:

```
                               ┌─────────────────────────────┐
                               │     Laravel REST API        │
                               │   (Multi-Tenant Backend)    │
                               └──────────────┬──────────────┘
                                              │
                     ┌────────────────────────┴────────────────────────┐
                     ▼                                                 ▼
      ┌─────────────────────────────┐                   ┌─────────────────────────────┐
      │     Customer Mobile App     │                   │     Salon Owner App         │
      │       (Flutter / Dart)      │                   │     (Flutter / Dart)        │
      ├─────────────────────────────┤                   ├─────────────────────────────┤
      │ • Browse salons & stylists  │                   │ • Real-time calendar schedule│
      │ • Instant slot booking      │                   │ • Staff & service assignment │
      │ • Live appointment tracking │                   │ • Earnings & financial ledger│
      │ • Payment integration       │                   │ • Customer CRM & analytics   │
      └─────────────────────────────┘                   └─────────────────────────────┘
```

---

## 📱 Applications & Modules

| Module | Directory | Technology | Description |
| :--- | :--- | :--- | :--- |
| **Backend API** | [`/backend`](./backend) | Laravel / PHP | Multi-tenant core API, MySQL database, booking engine, and auth services. |
| **Customer App** | [`/customer_app`](./customer_app) | Flutter / Dart | Native iOS & Android app for clients to discover salons, select services, and book slots. |
| **Owner App** | [`/owner_app`](./owner_app) | Flutter / Dart | Dedicated management console for salon owners, staff management, and appointment rosters. |
| **Documentation** | [`/docs`](./docs) | Markdown / PRD | Product Requirement Documents (PRD), architectural specs, and API contracts. |

---

## ✨ Key Features

- 📅 **Real-Time Booking & Slot Management:** Dynamic time-slot reservation with double-booking prevention and instant confirmation.
- 👥 **Multi-Tenant Salon CRM:** Supports multiple salon locations, individual stylist rosters, service pricing tiers, and operating hours.
- 📊 **Owner Dashboard & Ledger:** Visual analytics on daily appointments, revenue charts, staff commissions, and customer retention.
- 🔔 **Notifications & Reminders:** Automated push notifications and booking status updates.
- 🛡️ **Zero-Trust Security:** Built with strict environment variable isolation, sanitized API endpoints, and role-based permissions (RBAC).

---

## 🛠️ Tech Stack

- **Mobile Clients:** Flutter 3.x, Dart 3.x, Provider / Riverpod state management.
- **Backend API:** Laravel 11.x, PHP 8.2+, Eloquent ORM.
- **Database:** MySQL / PostgreSQL with full relational migrations.
- **Security & Pipeline:** DevPulse AI Security Core, SHA-256 Audit Trail.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.19.0`)
- [PHP](https://www.php.net/) (`>= 8.2`) & [Composer](https://getcomposer.org/)
- [MySQL](https://www.mysql.com/) or Docker

---

### 1. Backend Setup (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```
*The API will be available at `http://localhost:8000`.*

---

### 2. Customer Mobile App Setup (Flutter)
```bash
cd customer_app
flutter pub get
flutter run
```

---

### 3. Salon Owner App Setup (Flutter)
```bash
cd owner_app
flutter pub get
flutter run
```

---

## 🔒 Security & Zero-Trust Governance

- **Zero Plaintext Secrets:** All API keys, database credentials, and payment tokens are stored exclusively in `.env` files and never committed to version control.
- **Continuous Audit:** Every commit and release is checked against local security scanners with SHA-256 tamper-evident verification.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
