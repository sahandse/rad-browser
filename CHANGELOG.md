# Changelog

## 1.1.1 — Automatic Search Routing

- حذف انتخاب دستی Google / ذره‌بین از صفحه اصلی
- انتخاب خودکار Google هنگام دسترسی به اینترنت جهانی
- انتخاب خودکار ذره‌بین هنگام دسترسی فقط به شبکه داخلی
- استفاده از ایران‌وب/داده محلی در حالت کاملاً آفلاین
- حذف ذره‌بین از فهرست سایت‌های ایران‌وب
- افزایش نتایج Google تا ۵۰ نتیجه با بارگذاری تدریجی در UI
- یکسان‌سازی رفتار جستجو در Home و Address Bar

## 1.1.0 — Smart Search

نسخه 1.1.0 راد روی تجربه جستجوی مستقل، رسانه‌ای و فارسی تمرکز دارد.

### جستجو
- طراحی حرفه‌ای‌تر صفحه نتایج با سبک سبک‌تر و نزدیک‌تر به موتورهای جستجوی مدرن
- حذف شمارنده خشک نتایج و کارت‌های سنگین
- تب‌های «همه»، «تصاویر»، «ویدیو»، «خبر» و دسترسی سریع به «ایران‌وب»
- نتایج تصویری Grid و نوار افقی تصاویر داخل نتایج عمومی
- نتایج ویدیویی با Thumbnail و کارت 16:9
- تب خبر با منبع، عنوان، خلاصه و تصویر در صورت وجود
- Knowledge Card بر اساس متادیتای واقعی نتیجه اول (`og:title`, `og:description`, `og:image`)
- Answer Box محلی برای محاسبات ساده، ساعت و تاریخ
- جستجوهای مرتبط
- پیشنهاد زنده هنگام تایپ در Home و صفحه نتایج
- تاریخچه جستجو روی دستگاه با امکان خاموش‌کردن و پاک‌کردن از Settings
- Rank هوشمند بر اساس تطابق عبارت، HTTPS و دامنه‌های ایرانی بدون جایگزین‌کردن کامل رتبه موتور اصلی
- Lazy loading برای نتایج وب
- fallback بین موتورهای جستجو وقتی موتور انتخابی نتیجه قابل استفاده برنگرداند

### ایران‌وب
- گسترش فهرست به 126 سایت ایرانی/داخلی
- 33 دسته‌بندی موضوعی
- فیلتر دسته‌بندی، نمایش دسته هر سایت و جستجو در نام دسته
- لینک مستقیم به سایت‌ها و نمایش وضعیت دسترسی واقعی

### رابط کاربری
- Home مینیمال با لوگوی رسمی راد، ساعت و تاریخ شمسی
- فونت Vazir در رابط فارسی
- Search Box جدید با پیشنهادهای زنده
- رابط Responsive بهتر برای تصاویر در موبایل و تبلت

### Build
- Version: `1.1.0+3`
- Android package: `com.sahand.rad`
- CI: Analyze, Test, APK/AAB Release, Manifest Audit و Web Release

---

## 1.0.0 — Pre-Release

اولین نسخه عمومی راد با تمرکز بر مرور مینیمال فارسی، حریم خصوصی و دسترسی هوشمند در شرایط اینترنت عادی، شبکه داخلی و حالت آفلاین.

### مرورگر
- WebView واقعی با Back / Forward / Refresh / Progress
- نوار آدرس و جستجوی یکپارچه
- تب‌ها، Session Restore و Tab Groups
- Private Browsing
- Reader Mode
- Find in Page
- Desktop Site
- Share و Print/PDF

### داده و ذخیره‌سازی
- History و Bookmarks
- Download Manager
- ذخیره صفحات برای مطالعه آفلاین
- Backup/Restore نسخه‌دار بین Android و Web

### شبکه و ایران‌وب
- تشخیص اینترنت کامل / شبکه داخلی / آفلاین
- Iran Web با سرویس‌های واقعی
- جستجوی Local-first در شرایط شبکه داخلی
- ذره‌بین به‌عنوان مسیر جستجوی داخلی
- Search Bangهای داخلی
- FilmCase و NoraaShop با اطلاعات واقعی

### حریم خصوصی و امنیت
- Tracking Protection با Standard / Strict / Off
- استثناء Tracking برای هر دامنه
- HTTPS-first
- کنترل Pop-up
- Site Permissions
- درخواست واقعی Permission سیستم برای Camera/Microphone/Location/Notifications
- پاک‌سازی Cookie/Storage/Permissions همان سایت
- Data Saver برای محدودکردن autoplay و preload رسانه

### رابط کاربری
- Home تمام‌صفحه با لوگوی RAD و Search مرکزی
- Light/Dark Mode
- RTL فارسی
- Toolbar شناور
- Tab Switcher مینیمال
- RAD launcher و Splash اختصاصی Android
- PWA با هویت RAD

### Build و انتشار
- Android package: `com.sahand.rad`
- Version: `1.0.0+1`
- APK و AAB Release Candidate در CI
- Permission audit روی Manifest نهایی
- Release workflow محافظت‌شده با production signing
