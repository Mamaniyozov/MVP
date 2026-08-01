# Flutter Offline-First Storage & Persistence Architecture Assessment

## 1. Executive Summary

Ushbu hujjat "Hisob" B2C shaxsiy moliya ilovasi mobil mijozida (`mobile/`, Flutter) **Offline-First** (Internet ulanishisiz ishlash va ma'lumotlarni mahalliy keshga saqlash) mexanizmini tatbiq etish uchun ma'lumotlar bazasi texnologiyalarining tahlilini taqdim etadi.

---

## 2. Storage Options Comparison

| Mezon | Hive / Isar | SQLite (sqflite / Drift) | Shared Preferences / Secure Storage |
| :--- | :--- | :--- | :--- |
| **Ma'lumot Turi** | NoSQL / Object Box / Key-Value | Relational SQL (Jadvallar) | Oddiy Key-Value (String/Int) |
| **Tezlik (Read/Write)** | 🚀 O'ta yuqori (In-Memory indexing) | ⚡ O'rta / Yuqori (Disk I/O) | ⚡ O'rta |
| **Nativ Bog'liqlik** | Pure Dart (Nativ C++ shart emas) | Nativ C++ SQLite kutubxonasi | Nativ SDK (SharedPreferences/NSUserDefaults) |
| **Murakkab Query'lar** | Indekslar bo'yicha tezkor filter | SQL `JOIN`, `GROUP BY`, `HAVING` | Qo'llab-quvvatlanmaydi |
| **Tavsiya Etilgan Soha** | **JSON kesh, Transaksiyalar & Tokenlar** | Katta hajmli relational ma'lumotlar | Faqat JWT Tokenlar & Theme sozlamalari |

---

## 3. Recommended Senior Architecture Strategy

### Primary Offline Storage Engine: **Hive (Pure Dart Key-Value / Box)**

1. **API Response Caching (Kesh):**
   - Categories, Cards, Budgets va Transactions ro'yxatlarini HTTP muvaffaqiyatidan so'ng Hive box'lariga (`categories_box`, `cards_box`, `transactions_box`) saqlash.
   - Internet ulanmagan holatda Riverpod Controller'lar ma'lumotni to'g'ridan-to'g'ri Hive box'idan tezkor o'qiydi.

2. **Secure Token Storage:**
   - JWT Auth tokenlar (`access`, `refresh`) xavfsiz holda `flutter_secure_storage` (Android KeyStore & iOS Keychain) orqali saqlanadi.

3. **Optimistic Offline Sync Queue:**
   - Foydalanuvchi offlayn rejimda yangi tranzaksiya yoki maqsad qo'shganda, so'rov `offline_mutations_box` navbatiga yoziladi.
   - Internet qaytishi bilan (Connectivity Listener) navbatdagi so'rovlar fonda backend API (`/api/v1/transactions/`) ga jo'natiladi.

---

## 4. Implementation Steps Roadmap

1. `mobile/pubspec.yaml` ga `hive` va `hive_flutter` bog'liqliklarini kiritish.
2. `core/storage/hive_service.dart` va `hive_adapters` model konvertorlarini yaratish.
3. Repozitoriyalarni (Data Layer) Internet mavjudligiga qarab **Cache-First** yoki **Network-First** rejimiga o'tkazish.
