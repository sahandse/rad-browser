import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sites_path = root / 'assets/data/iran_sites.json'
cats_path = root / 'assets/data/categories.json'

sites_doc = json.loads(sites_path.read_text(encoding='utf-8'))
cats_doc = json.loads(cats_path.read_text(encoding='utf-8'))

new_categories = [
    ('insurance','بیمه','verified_user',15),
    ('hospital','بیمارستان و مراکز درمانی','local_hospital',16),
    ('downloads','دانلود و اپلیکیشن','download',17),
    ('hosting','هاستینگ و خدمات کسب‌وکار','dns',18),
    ('taxi','تاکسی و پیک اینترنتی','local_taxi',19),
    ('ai','هوش مصنوعی','auto_awesome',20),
    ('music','موسیقی و پادکست','headphones',21),
    ('food','سفارش غذا','restaurant',22),
    ('books','کتاب و کتابخوان','menu_book',23),
    ('travel','بلیت و گردشگری','flight',24),
    ('discount','تخفیف و خرید اقتصادی','local_offer',25),
    ('jobs','کاریابی','work',26),
    ('email','ایمیل','mail',27),
    ('dictionary','دیکشنری و ترجمه','translate',28),
    ('sports','ورزش','sports_soccer',29),
    ('upload','آپلود فایل','cloud_upload',30),
    ('classifieds','نیازمندی‌ها','view_list',31),
    ('utilities','خدمات آنلاین کاربردی','construction',32),
]
existing_cats = {c['id'] for c in cats_doc.get('categories', [])}
for cid,title,icon,order in new_categories:
    if cid not in existing_cats:
        cats_doc['categories'].append({'id':cid,'title':title,'icon':icon,'order':order})
cats_doc['categories'].sort(key=lambda x: x.get('order',99))
cats_doc['version'] = int(cats_doc.get('version', 1)) + 1

new_sites = [
('bertina-search','جستجوگر برتینا','https://search.bertina.ir/','search',['برتینا','جستجوگر ایرانی'],78),
('shadbin','جستجوگر شادبین','https://shaadbin.ir/','search',['شادبین','جستجوگر ایرانی'],77),
('gerdoo','جستجوگر گردو','https://gerdoo.me/','search',['گردو','جستجوگر ایرانی'],76),
('tax','سازمان امور مالیاتی کشور','https://www.intamedia.ir/','government',['مالیات','اظهارنامه','مودیان'],80),
('sana','سامانه ثنا','https://sana.adliran.ir/','government',['ثنا','قوه قضاییه','ابلاغ قضایی'],79),
('epolice','خدمات الکترونیک پلیس','https://www.epolice.ir/','government',['پلیس','انتظامی','خدمات پلیس'],78),
('sabteahval','سازمان ثبت احوال','https://www.sabteahval.ir/','government',['ثبت احوال','کارت ملی','شناسنامه'],77),
('ssaa','سازمان ثبت اسناد و املاک','https://www.ssaa.ir/','government',['ثبت اسناد','املاک','سند'],76),
('adliran','درگاه خدمات الکترونیک قضایی','https://www.adliran.ir/','government',['عدلیه','قضایی','دادگستری'],75),
('tracking-post','رهگیری مرسولات پستی','https://tracking.post.ir/','government',['رهگیری مرسوله','پست'],74),
('postbank','پست بانک ایران','https://www.postbank.ir/','banking',['پست بانک','بانک'],79),
('refah-bank','بانک رفاه کارگران','https://www.refah-bank.ir/','banking',['بانک رفاه','بانک'],78),
('banksepah','بانک سپه','https://www.banksepah.ir/','banking',['بانک سپه','بانک'],77),
('bki','بانک کشاورزی','https://www.bki.ir/','banking',['بانک کشاورزی','بانک'],76),
('bank-maskan','بانک مسکن','https://www.bank-maskan.ir/','banking',['بانک مسکن','بانک'],75),
('sb24','بانک سامان','https://www.sb24.com/','banking',['بانک سامان','بانک'],74),
('bpi','بانک پاسارگاد','https://www.bpi.ir/','banking',['بانک پاسارگاد','بانک'],73),
('centinsur','بیمه مرکزی','https://www.centinsur.ir/','insurance',['بیمه','استعلام بیمه'],70),
('iraninsurance','بیمه ایران','https://iraninsurance.ir/','insurance',['بیمه ایران','بیمه'],69),
('dana-insurance','بیمه دانا','https://www.dana-insurance.com/','insurance',['بیمه دانا','بیمه'],68),
('azki','ازکی','https://www.azki.com/','insurance',['ازکی','بیمه','مقایسه بیمه'],67),
('bimeh-com','بیمه‌دات‌کام','https://bimeh.com/','insurance',['بیمه','خرید بیمه'],66),
('milad-hospital','بیمارستان میلاد','https://miladhospital.com/','hospital',['بیمارستان میلاد','درمان'],65),
('farabi-hospital','بیمارستان فارابی','https://farabih.tums.ac.ir/','hospital',['فارابی','بیمارستان','چشم پزشکی'],64),
('tehran-heart','مرکز قلب تهران','https://thc.tums.ac.ir/','hospital',['مرکز قلب تهران','بیمارستان'],63),
('farsnews','خبرگزاری فارس','https://farsnews.ir/','news',['فارس','خبرگزاری','اخبار'],78),
('khabaronline','خبرآنلاین','https://www.khabaronline.ir/','news',['خبرآنلاین','خبر'],77),
('asriran','عصر ایران','https://www.asriran.com/','news',['عصر ایران','خبر'],76),
('shargh','روزنامه شرق','https://www.sharghdaily.com/','news',['شرق','روزنامه','خبر'],75),
('peivast','پیوست','https://peivast.com/','news',['پیوست','فناوری','خبر'],74),
('basalam','باسلام','https://basalam.com/','shopping',['باسلام','فروشگاه','بازار'],75),
('technolife','تکنولایف','https://www.technolife.com/','shopping',['تکنولایف','فروشگاه','موبایل'],74),
('okala','اکالا','https://okala.com/','shopping',['اکالا','سوپرمارکت','خرید'],73),
('elanza','الانزا','https://elanza.com/','shopping',['الانزا','آرایشی','فروشگاه'],72),
('cafebazaar','کافه‌بازار','https://cafebazaar.ir/','downloads',['کافه بازار','اپلیکیشن','دانلود'],70),
('myket','مایکت','https://myket.ir/','downloads',['مایکت','اپلیکیشن','دانلود'],69),
('soft98','سافت ۹۸','https://soft98.ir/','downloads',['سافت 98','نرم افزار','دانلود'],68),
('yasdl','یاس دانلود','https://www.yasdl.com/','downloads',['یاس دانلود','نرم افزار'],67),
('downloadha','دانلودها','https://www.downloadha.com/','downloads',['دانلودها','نرم افزار'],66),
('parspack','پارس‌پک','https://parspack.com/','hosting',['پارس پک','هاست','سرور'],65),
('didar','دیدار CRM','https://didar.me/','hosting',['دیدار','CRM','کسب و کار'],64),
('snapp-taxi','اسنپ','https://snapp.ir/','taxi',['اسنپ','تاکسی اینترنتی'],64),
('tapsi','تپسی','https://tapsi.ir/','taxi',['تپسی','تاکسی اینترنتی'],63),
('alopeyk','الوپیک','https://alopeyk.com/','taxi',['الوپیک','پیک','ارسال'],62),
('hoosha','هوشا','https://hoosha.com/','ai',['هوشا','هوش مصنوعی','AI'],60),
('zigap','زیگپ','https://zigap.ir/','ai',['زیگپ','هوش مصنوعی','چت بات'],59),
('ivira','ویرا','https://ivira.ai/','ai',['ویرا','هوش مصنوعی','AI'],58),
('gapgpt','گپ‌جی‌پی‌تی','https://gapgpt.app/','ai',['گپ جی پی تی','هوش مصنوعی'],57),
('filmnet','فیلم‌نت','https://filmnet.ir/','video',['فیلم نت','فیلم','سریال'],69),
('namasha','نماشا','https://www.namasha.com/','video',['نماشا','ویدیو'],68),
('beeptunes','بیپ‌تونز','https://beeptunes.com/','music',['بیپ تونز','موسیقی'],60),
('upmusic','آپ موزیک','https://upmusics.com/','music',['آپ موزیک','موسیقی'],59),
('snappfood','اسنپ‌فود','https://snappfood.ir/','food',['اسنپ فود','غذا','سفارش غذا'],60),
('delino','دلینو','https://www.delino.com/','food',['دلینو','غذا','سفارش غذا'],59),
('igap','آی‌گپ','https://www.igap.net/','communication',['آی گپ','پیام رسان'],65),
('eitaa','ایتا','https://eitaa.com/','communication',['ایتا','پیام رسان'],64),
('gap','گپ','https://gap.im/','communication',['گپ','پیام رسان'],63),
('fidibo','فیدیبو','https://fidibo.com/','books',['فیدیبو','کتاب','کتابخوان'],60),
('taaghche','طاقچه','https://taaghche.com/','books',['طاقچه','کتاب','کتابخوان'],59),
('ketabrah','کتابراه','https://www.ketabrah.ir/','books',['کتابراه','کتاب'],58),
('alibaba','علی‌بابا','https://www.alibaba.ir/','travel',['علی بابا','بلیت','سفر'],62),
('mrbilit','مستربلیط','https://mrbilit.com/','travel',['مستربلیط','بلیت','سفر'],61),
('raja','رجا','https://www.raja.ir/','travel',['رجا','قطار','بلیت'],60),
('takhfifan','تخفیفان','https://takhfifan.com/','discount',['تخفیفان','تخفیف'],55),
('mopon','موپن','https://www.mopon.ir/','discount',['موپن','کد تخفیف'],54),
('doctoreto','دکترتو','https://doctoreto.com/','health',['دکترتو','پزشک','نوبت'],62),
('drdr','دکتردکتر','https://drdr.ir/','health',['دکتردکتر','پزشک','نوبت'],61),
('nobat','نوبت‌آی‌آر','https://nobat.ir/','health',['نوبت','پزشک'],60),
('jobinja','جابینجا','https://jobinja.ir/','jobs',['جابینجا','کاریابی','استخدام'],60),
('jobvision','جاب‌ویژن','https://jobvision.ir/','jobs',['جاب ویژن','کاریابی','استخدام'],59),
('iranestekhdam','ایران استخدام','https://iranestekhdam.ir/','jobs',['ایران استخدام','کاریابی'],58),
('mailfa','میل‌فا','https://mailfa.com/','email',['میل فا','ایمیل'],50),
('chmail','چاپار','https://accounts.chmail.ir/','email',['چاپار','ایمیل'],49),
('abadis','آبادیس','https://abadis.ir/','dictionary',['آبادیس','دیکشنری','ترجمه'],55),
('targoman','ترگمان','https://targoman.ir/','dictionary',['ترگمان','ترجمه'],54),
('varzesh3','ورزش سه','https://www.varzesh3.com/','sports',['ورزش سه','فوتبال','ورزش'],60),
('football360','فوتبال ۳۶۰','https://football360.ir/','sports',['فوتبال 360','فوتبال'],59),
('uploadkon','آپلودکن','https://uploadkon.ir/','upload',['آپلودکن','آپلود فایل'],50),
('picofile','پیکوفایل','https://www.picofile.com/','upload',['پیکوفایل','آپلود فایل'],49),
('uupload','یوآپلود','https://uupload.ir/','upload',['یوآپلود','آپلود فایل'],48),
('divar','دیوار','https://divar.ir/','classifieds',['دیوار','نیازمندی','آگهی'],60),
('sheypoor','شیپور','https://www.sheypoor.com/','classifieds',['شیپور','نیازمندی','آگهی'],59),
('iau','دانشگاه آزاد اسلامی','https://www.iau.ac.ir/','education',['دانشگاه آزاد','دانشگاه'],58),
('sharif','دانشگاه صنعتی شریف','https://www.sharif.edu/','education',['شریف','دانشگاه'],57),
('aut','دانشگاه صنعتی امیرکبیر','https://aut.ac.ir/','education',['امیرکبیر','دانشگاه'],56),
('time-ir','تایم دات آی‌آر','https://www.time.ir/','utilities',['تاریخ','ساعت','تقویم','اوقات شرعی'],55),
('achareh','آچاره','https://achareh.ir/','utilities',['آچاره','خدمات منزل'],54),
('bahesab','با حساب','https://www.bahesab.ir/','utilities',['با حساب','محاسبه آنلاین'],53),
('roshd','شبکه رشد','https://www.roshd.ir/','education',['رشد','آموزش','دانش آموز'],55),
('kanoon','قلم‌چی','https://www.kanoon.ir/','education',['قلم چی','آزمون','آموزش'],54),
]

existing_ids = {s['id'] for s in sites_doc.get('sites', [])}
for sid,name,url,cat,keywords,priority in new_sites:
    if sid in existing_ids:
        continue
    sites_doc['sites'].append({
        'id': sid,
        'name': name,
        'url': url,
        'category': cat,
        'keywords': keywords,
        'verified': True,
        'internalNetwork': False,
        'priority': priority,
    })

sites_doc['sites'].sort(key=lambda s: (-int(s.get('priority',0)), s.get('name','')))
sites_doc['version'] = int(sites_doc.get('version', 1)) + 1
sites_doc['updatedAt'] = '2026-10-04T08:45:00Z'

sites_path.write_text(json.dumps(sites_doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
cats_path.write_text(json.dumps(cats_doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f"Iran Web now has {len(sites_doc['sites'])} sites and {len(cats_doc['categories'])} categories")
