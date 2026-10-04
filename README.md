# RAD Browser — راد

راد یک مرورگر Flutter برای Android و Web/PWA با تمرکز بر رابط مینیمال فارسی، حریم خصوصی، کار در شبکه داخلی ایران و تجربه قابل‌استفاده هنگام اختلال اینترنت است.

## وضعیت پروژه

**Pre-Release 1.0.0** — قابلیت‌های اصلی تکمیل شده‌اند و پروژه در مرحله بازبینی نهایی Android/Web، signing و آماده‌سازی انتشار است.

## قابلیت‌ها

- Home تمام‌صفحه مینیمال با جستجو/Address مرکزی
- مرور واقعی با WebView، Back/Forward/Refresh و Progress
- تب‌ها، Session Restore و Tab Groups
- Private Browsing بدون ثبت History/Session عادی
- History، Bookmarks و Downloads واقعی
- Reader Mode، Find in Page، Desktop Site، Share و Print/PDF
- ذخیره صفحه برای مطالعه آفلاین
- تشخیص اینترنت کامل / شبکه داخلی / آفلاین
- Iran Web با دیتای واقعی و جستجوی Local-first
- مسیر جایگزین داخلی با ذره‌بین هنگام اختلال اینترنت جهانی
- Search Bangهای داخلی
- Tracking Protection و استثناء دامنه‌ها
- HTTPS-first و کنترل Pop-up
- Site Permissions برای دوربین، میکروفون، موقعیت و اعلان‌ها
- Data Saver برای محدودکردن autoplay و preload رسانه‌ها
- پاک‌سازی داده فقط برای همان سایت
- Backup/Restore نسخه‌دار بین Android و Web
- PWA قابل نصب
- Light/Dark Mode و رابط RTL فارسی

## داده‌های ایران وب

دیتای همراه اپ فقط از سرویس‌های واقعی استفاده می‌کند. وضعیت در دسترس بودن سایت‌ها در زمان اجرا بررسی می‌شود و راد تضمین نمی‌کند یک سرویس در همه انواع اختلال شبکه در دسترس باشد.

## حریم خصوصی

راد در نسخه فعلی backend حساب کاربری یا سیستم analytics اختصاصی ندارد. History، Bookmarks، Tabs، Settings و صفحات آفلاین روی دستگاه ذخیره می‌شوند. جزئیات بیشتر در [`PRIVACY.md`](PRIVACY.md) آمده است.

## Build

CI روی هر تغییر این موارد را بررسی می‌کند:

- `flutter analyze`
- `flutter test`
- Android APK build
- Android merged-manifest permission audit
- Web release build

Package هدف Android برای انتشار: `com.sahand.rad`
