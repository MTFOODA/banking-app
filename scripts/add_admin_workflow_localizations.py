import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'frontend/faisal_app/lib/l10n'
values={
 'admDataEmail':('Email','البريد الإلكتروني'), 'admDataPhone':('Phone','رقم الهاتف'), 'admDataAddress':('Address','العنوان'),
 'admDataProduct':('Banking product','المنتج المصرفي'), 'admDataAccount':('Account','الحساب'), 'admDataCurrency':('Currency','العملة'),
 'admDataCard':('Card','البطاقة'), 'admDataAmount':('Requested amount','المبلغ المطلوب'), 'admDataReason':('Reason','السبب'),
 'admSubtitle':('Review customer requests and publish bank notices','راجع طلبات العملاء وانشر تنبيهات البنك'),
 'admAll':('All requests','كل الطلبات'),
 'admSearch':('Search by request reference','ابحث برقم الطلب'),
 'admEmptyRequests':('No requests match this filter','لا توجد طلبات مطابقة لهذا الفلتر'),
 'admLoadMore':('Load more','عرض المزيد'),
 'admDetails':('Request details','تفاصيل الطلب'),
 'admCustomer':('Customer','العميل'),
 'admHistory':('Request history','سجل الطلب'),
 'admDecisionSaved':('Decision recorded and customer notified','تم تسجيل القرار وإخطار العميل'),
 'admEmptyNotices':('No announcements yet','لا توجد إعلانات حاليًا'),
 'admPublicEmpty':('No urgent notices at the moment','لا توجد تنبيهات عاجلة حاليًا'),
 'admPublicTitle':('Bank notices','تنبيهات البنك'),
 'admPublicSubtitle':('Important updates before you sign in','آخر التحديثات المهمة قبل تسجيل الدخول'),
 'admLocation':('Display location','مكان ظهور الإعلان'),
 'admHome':('Customer home','الصفحة الرئيسية للعميل'),
 'admBeforeLogin':('Before sign-in','قبل تسجيل الدخول'),
 'admBoth':('Home and before sign-in','الرئيسية وقبل تسجيل الدخول'),
 'admPublicPolicy':('Before-sign-in notices are public. Do not include customer or private information. Targeted notices must remain on home.','إعلانات ما قبل الدخول عامة للجميع. لا تضع بيانات عملاء أو معلومات خاصة. الإعلانات الموجهة تظل في الرئيسية.'),
 'admTitleEn':('English title','العنوان بالإنجليزية'),
 'admTitleAr':('Arabic title','العنوان بالعربية'),
 'admBodyEn':('English message','الرسالة بالإنجليزية'),
 'admBodyAr':('Arabic message','الرسالة بالعربية'),
 'admRequired':('Enter at least 3 characters','أدخل ٣ أحرف على الأقل'),
 'admPriority':('Priority','الأولوية'),
 'admDraft':('Draft','مسودة'),
 'admPublished':('Published','منشور'),
 'admArchived':('Archived','مؤرشف'),
 'admSaved':('Announcement saved','تم حفظ الإعلان'),
 'admEdit':('Edit announcement','تعديل الإعلان'),
 'admPublishConfirm':('Publish this announcement to the selected location?','هل تريد نشر الإعلان في المكان المختار؟'),
 'admArchiveConfirm':('Archive this announcement and remove it from customer screens?','هل تريد أرشفة الإعلان وإخفاءه من شاشات العملاء؟'),
}
for i,locale in enumerate(('en','ar')):
 p=root/f'app_{locale}.arb';data=json.loads(p.read_text(encoding='utf-8'))
 data.update({key:value[i] for key,value in values.items()})
 p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
