"""Fixed universal identity and bank-scoped appearance strings."""
import json
from pathlib import Path

STRINGS={
 'appName':('Banking App','Banking App'),
 'bankLoginSelectionLabel':('Bank (optional for sign-in)','البنك (اختياري عند الدخول)'),
 'bankLoginAutomatic':('Detect from username or card','تحديد البنك من اليوزر أو الكارت'),
 'bankLoginSelectionHelp':('Choose the bank for this username/card, or leave automatic. Each successful sign-in uses the bank verified by the server. Administrators sign in without choosing a bank.','اختر البنك التابع لهذا اليوزر أو الكارت، أو اترك التحديد التلقائي. كل دخول يفتح بثيم البنك المتحقق منه على السيرفر. دخول الأدمن لا يحتاج اختيار بنك.'),
 'bankNameShort':('Banking App','Banking App'),
 'securityNotice':('Never share your password or one-time codes. Your bank will never ask for them.','لا تشارك كلمة المرور أو الرموز المؤقتة مع أي شخص. لن يطلبها البنك منك.'),
 'bankName':('Your bank','البنك'),
 'publicWelcomeTitle':('Welcome to Banking App','مرحبًا بك في Banking App'),
 'publicWelcomeSubtitle':('Your banking and support services, in one place.','خدماتك البنكية والدعم في مكان واحد.'),
 'demoDataNotice':('Development simulation. Bank names and themes do not indicate a connection to any real bank or payment network.','محاكاة للتطوير. أسماء البنوك وثيماتها لا تعني وجود اتصال بأي بنك أو شبكة دفع حقيقية.'),
 'bankSelectionLabel':('Bank','البنك'),
 'bankSelectionRequired':('Choose your card’s bank.','اختر البنك الذي يتبع له الكارت.'),
 'bankRegistrationHelp':('Choose the bank of your provisioned development card. Verification uses the contact already registered for that customer; selecting a bank never changes card ownership.','اختر بنك الكارت التجريبي المسجل. التحقق يتم ببيانات الاتصال المسجلة للعميل؛ اختيار البنك لا يغير ملكية الكارت.'),
 'registrationExplanation':('Choose your bank and enter your card number. Next, verify with the contact already registered at the bank, then create your unique username and password.','اختر البنك وأدخل رقم الكارت. بعدها تحقّق ببيانات الاتصال المسجلة لدى البنك، ثم أنشئ اسم مستخدم فريدًا وكلمة مرور.'),
 'brandingTitle':('Bank appearance settings','إعدادات مظهر البنوك'),
 'bankFixedIdentity':('Fixed application identity','هوية التطبيق الثابتة'),
 'bankFixedIdentityHelp':('Banking App name, logo, launcher icon and sign-in appearance are fixed in the application release. These settings customize customer screens after sign-in only.','اسم Banking App واللوجو وأيقونة التطبيق ومظهر الدخول ثابتة في إصدار التطبيق. الإعدادات هنا تخص شاشات العملاء بعد تسجيل الدخول فقط.'),
 'bankAppearanceScope':('Edits apply to customers registered with the selected bank. Other banks and the fixed application identity stay independent.','التعديلات تخص العملاء المسجلين لدى البنك المختار. لكل بنك إعداداته المستقلة، وهوية التطبيق الأساسية ثابتة.'),
 'bankPresetColors':('Bank color preset','ألوان ثيم البنك'),
 'bankPresetHelp':('This read-only palette is inspired by the bank’s identity and adjusted for accessible text contrast. Colors cannot be replaced with arbitrary values.','لوحة ألوان ثابتة مستوحاة من هوية البنك مع ضبط تباين النصوص. لا يمكن استبدالها بألوان عشوائية.'),
 'bankInternalContent':('Content inside customer accounts','المحتوى داخل حسابات العملاء'),
 'bankInternalCaption':('Internal caption (optional)','نص إضافي داخلي (اختياري)'),
 'bankRestorePreset':('Restore this bank’s defaults as draft','استعادة إعدادات هذا البنك كمسودة'),
 'brandingInvalid':('Check the internal text, supported fonts and size scale. The preview keeps the last valid appearance.','راجع النصوص الداخلية والخطوط المتاحة ومقياس الحجم. تحتفظ المعاينة بآخر إعداد صالح.'),
 'brandingDraftNotice':('Save a draft and explicitly publish to update customer screens. Connected clients refresh on foreground resume; no new app download is needed for supported internal settings.','احفظ المسودة ثم انشرها لتحديث شاشات العملاء. يُجلب التحديث عند العودة للتطبيق، ولا يحتاج تغيير الإعدادات الداخلية المدعومة لتنزيل إصدار جديد.'),
 'brandingPublishConfirm':('Publish the saved internal appearance changes for the affected banks?','هل تريد نشر تعديلات المظهر الداخلي المحفوظة للبنوك المعنية؟'),
 'brandingNativeHelp':('The Banking App name, logo, launcher icons and native startup resources are fixed. Changing them requires a new application release; this screen has no controls to change them.','اسم Banking App واللوجو وأيقونات النظام وموارد الإقلاع ثابتة. تغييرها يحتاج إصدارًا جديدًا؛ هذه الشاشة لا تتيح تعديلها.'),
 'bankDirectoryNote':('The bundled street-address directory belongs to Faisal Bank only. For other banks, use the verified official website; no unverified addresses or hotlines are shown.','دليل عناوين الفروع المرفق خاص ببنك فيصل فقط. للبنوك الأخرى استخدم الموقع الرسمي؛ لا نعرض عناوين أو أرقام خدمة عملاء غير متحقق منها.'),
 'bankOfficialWebsite':('Open official bank website','فتح الموقع الرسمي للبنك'),
 'bankServiceChoose':('Choose a bank for this service.','اختر البنك المطلوب لهذه الخدمة.'),
 'bankLinkedBank':('Registered bank','البنك المسجل'),
}

if __name__=='__main__':
 root=Path(__file__).resolve().parents[1]
 for index,language in enumerate(('en','ar')):
  path=root/'frontend/faisal_app/lib/l10n'/f'app_{language}.arb'
  value=json.loads(path.read_text(encoding='utf-8'))
  value.update({key:text[index] for key,text in STRINGS.items()})
  path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
