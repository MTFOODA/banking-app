import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]/'frontend/faisal_app/lib/l10n'
values={
 'cardApplyTitle':('Request a card','طلب بطاقة جديدة'),
 'cardApplySubtitle':('Choose your card and linked account. Bank approval is required.','اختر بطاقتك والحساب المرتبط بها. الإصدار يتطلب موافقة البنك.'),
 'cardPreview':('DESIGN PREVIEW','معاينة التصميم'),
 'cardSelect':('Choose this card','اختيار البطاقة'),
 'cardSelected':('Selected card','البطاقة المختارة'),
 'cardChooseAccount':('Linked account','الحساب المرتبط'),
 'cardInvestmentOnly':('Investment account in EGP','حساب استثماري بالجنيه المصري'),
 'cardDomesticAccount':('Active EGP account','حساب نشط بالجنيه المصري'),
 'cardForeignOnly':('USD, EUR or SAR accounts only','حسابات الدولار أو اليورو أو الريال فقط'),
 'cardYouthOnly':('For customers under 21 with a verified date of birth','للشباب أقل من ٢١ سنة بتاريخ ميلاد موثق'),
 'cardAgeUnverified':('A verified date of birth is required. Contact the bank to verify it.','يلزم تاريخ ميلاد موثق لدى البنك. تواصل مع البنك لتوثيقه.'),
 'cardYouthAge':('Youth cards are available only to customers under 21.','بطاقة يوث متاحة فقط لمن هم أقل من ٢١ سنة.'),
 'cardInvestmentRequired':('You need an active EGP investment account for this card.','تحتاج حسابًا استثماريًا نشطًا بالجنيه لهذه البطاقة.'),
 'cardForeignRequired':('You need an active USD, EUR or SAR account for this card.','تحتاج حسابًا نشطًا بالدولار أو اليورو أو الريال لهذه البطاقة.'),
 'cardAccountRequired':('You need an eligible active EGP account.','تحتاج حسابًا مؤهلًا ونشطًا بالجنيه المصري.'),
 'cardUnavailable':('The card or customer is no longer eligible. Refresh and review the available options.','البطاقة أو العميل لم يعد مؤهلًا. حدّث الصفحة وراجع الخيارات المتاحة.'),
 'cardOpenAccount':('Open Accounts','فتح صفحة الحسابات'),
 'cardReviewTitle':('Review card request','مراجعة طلب البطاقة'),
 'cardApprovalNotice':('Submitting creates a request only. The card is issued after an administrator approves it. Delivery and activation remain pending.','الإرسال ينشئ طلبًا فقط. تُصدر البطاقة بعد موافقة الأدمن، ويظل التسليم والتفعيل قيد الانتظار.'),
 'cardAnnualFee':('Configured annual fee','الرسوم السنوية المحددة'),
 'cardSubmitRequest':('Confirm and submit request','تأكيد وإرسال الطلب'),
 'cardRequestReceived':('Request received — awaiting bank review','تم استلام الطلب — بانتظار مراجعة البنك'),
 'cardMyRequests':('My card requests','طلبات بطاقاتي'),
 'cardRequestExists':('You already have a pending card request. Follow its status below.','لديك طلب بطاقة قيد المراجعة بالفعل. تابع حالته بالأسفل.'),
 'cardNoRequests':('No card requests yet','لا توجد طلبات بطاقات بعد'),
 'cardProductLabel':('Card category','فئة البطاقة'),
 'cardPendingActivation':('Awaiting delivery and activation','بانتظار التسليم والتفعيل'),
 'cardBackCards':('Back to my cards','العودة لبطاقاتي'),
}
for index,lang in enumerate(('en','ar')):
    path=root/f'app_{lang}.arb';data=json.loads(path.read_text(encoding='utf-8'))
    data.update({key:value[index] for key,value in values.items()})
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Card category localizations updated:',len(values),'keys per language')
