# RAD Browser 1.0 — Release Checklist

## Product

- [x] Home مینیمال تمام‌صفحه با لوگو و Search/Address
- [x] Browser واقعی + Tabs + Tab Groups + Session Restore
- [x] Private Browsing
- [x] History / Bookmarks / Downloads
- [x] Reader / Find in Page / Desktop / Share / Print-PDF
- [x] Offline Reading
- [x] Iran Web + Local-first Search + Zarebin fallback
- [x] Internal-only / Offline network modes
- [x] Tracking Protection / HTTPS-first / Pop-up control
- [x] Site Permissions و پاک‌سازی داده همان سایت
- [x] Data Saver
- [x] Backup / Restore Android ↔ Web
- [x] PWA

## Data

- [x] بدون دیتای demo/mock در تجربه اصلی
- [x] FilmCase و NoraaShop با اطلاعات واقعی
- [x] Iran Web با سرویس‌های واقعی و وضعیت دسترسی runtime
- [x] categories.json واقعی و نسخه‌دار

## Privacy & Security

- [x] PRIVACY.md
- [x] Private Mode بدون History/Session معمولی
- [x] Runtime permission prompt برای Camera/Microphone/Location/Notifications
- [x] حذف READ_EXTERNAL_STORAGE
- [x] حذف WRITE_EXTERNAL_STORAGE
- [x] حذف REQUEST_INSTALL_PACKAGES
- [x] Manifest audit در CI
- [x] HTTPS-first قابل تنظیم
- [x] Tracking Protection قابل تنظیم

## Android

- [x] Package target: com.sahand.rad
- [x] App label: راد
- [x] RAD launcher icon
- [x] RAD light/dark splash
- [x] Version: 1.0.0+1
- [x] Debug APK CI build
- [x] Release APK dry-run build در CI
- [x] Release AAB dry-run build در CI
- [ ] Production keystore Secrets ثبت شده باشد
- [ ] Signed Release APK/AAB با certificate نهایی ساخته شود

## Web / PWA

- [x] Web release build
- [x] manifest.json RTL/Farsi
- [x] standalone PWA
- [x] RAD SVG icon
- [x] Web artifact CI

## Release Pipeline

- [x] Manual guarded release workflow
- [x] Tag باید با pubspec version یکی باشد
- [x] SHA256SUMS تولید می‌شود
- [x] publish=true بدون signing secrets fail می‌شود
- [x] APK + AAB + Web ZIP در Release Candidate قرار می‌گیرند
- [ ] GitHub Release v1.0.0 منتشر شود

## Required GitHub Secrets before publish

- RAD_KEYSTORE_BASE64
- RAD_KEYSTORE_PASSWORD
- RAD_KEY_ALIAS
- RAD_KEY_PASSWORD

تا قبل از ثبت این چهار Secret و تأیید نهایی، Release عمومی انجام نشود.
