import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'frontend/faisal_app/lib/l10n'
values={
'publicWelcomeTitle':('Welcome to Faisal Bank','مرحبًا بك في بنك فيصل'),
'publicWelcomeSubtitle':('Your banking and support services, in one place.','خدماتك البنكية ووسائل التواصل في مكان واحد.'),
'publicBranches':('Branches','الفروع'),
'publicAtms':('ATMs','الصراف الآلي'),
'publicCallCenter':('Call center','الكول سنتر'),
'publicSignInHint':('Access your accounts','ادخل إلى حساباتك'),
'publicBranchesHint':('Addresses and maps','العناوين واللوكيشن'),
'publicAtmsHint':('Find an ATM','اعثر على ماكينة'),
'publicCallCenterHint':('We are here to help','نحن هنا لمساعدتك'),
'publicBranchSearch':('Search branch, area or address','ابحث باسم الفرع أو المنطقة أو العنوان'),
'publicGovernorate':('Governorate','المحافظة'),
'publicAllGovernorates':('All governorates','كل المحافظات'),
'publicResultCount':('Results','النتائج'),
'publicDirectoryEmpty':('No branches match your search. Try another area or governorate.','لا توجد فروع مطابقة. جرّب منطقة أو محافظة أخرى.'),
'publicDirectoryFailed':('Could not load the branch directory. Please retry.','تعذّر تحميل دليل الفروع. حاول مرة أخرى.'),
'publicOpenMap':('Open location','افتح اللوكيشن'),
'publicMapSearchNote':('Open the branch pin or search its name and address on the map.','افتح نقطة الفرع أو ابحث باسمه وعنوانه على الخريطة.'),
'publicAtmSubtitle':('Find a cash machine','ابحث عن ماكينة صراف آلي'),
'publicAtmNote':('Search for Faisal Bank ATMs on the map, or use the bank’s official branch and ATM locator.','ابحث عن ماكينات بنك فيصل على الخريطة، أو استخدم محدد الفروع والصراف الآلي الرسمي للبنك.'),
'publicAtmArea':('City or area (optional)','المدينة أو المنطقة (اختياري)'),
'publicSearchAtm':('Search ATMs on map','ابحث على الخريطة'),
'publicOfficialLocator':('Official bank locator','محدد المواقع الرسمي للبنك'),
'publicCallEgypt':('Hotline inside Egypt','الخط الساخن من داخل مصر'),
'publicHotlineAvailability':('Customer service is available 24 hours a day, 7 days a week.','خدمة العملاء متاحة على مدار الساعة طوال أيام الأسبوع.'),
'publicCallAction':('Open dialer','اتصل بالكول سنتر'),
'publicCopyNumber':('Copy number','انسخ الرقم'),
'publicNumberCopied':('Phone number copied','تم نسخ رقم الهاتف'),
'publicOfficialWebsite':('Official bank website','الموقع الرسمي للبنك'),
'publicLinkFailed':('Could not open the link. Try again or use another maps app or browser.','تعذّر فتح الرابط. حاول مرة أخرى أو استخدم تطبيق خرائط أو متصفحًا آخر.'),
}
for index,lang in enumerate(('en','ar')):
    path=root/f'app_{lang}.arb';data=json.loads(path.read_text(encoding='utf-8'));data.update({k:v[index] for k,v in values.items()});path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Public service localization:',len(values),'keys per language')
