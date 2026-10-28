"""Extend both existing ARB catalogs; generated Dart is owned by flutter gen-l10n."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "frontend/faisal_app/lib/l10n"
LABELS = {
    "registerTitle": ("Register for digital banking", "التسجيل في الخدمات المصرفية الرقمية"),
    "registrationExplanation": ("Enter your existing card or account number. Next, verify a code using the contact registered with the bank. Your existing banking password is not needed.", "أدخل رقم بطاقتك أو حسابك الحالي. ثم تحقق برمز عبر بيانات الاتصال المسجلة لدى البنك. لا تحتاج كلمة مرور مصرفية حالية."),
    "registrationVerified": ("Contact verified. Create your secure password to complete enrollment.", "تم التحقق من وسيلة الاتصال. أنشئ كلمة مرور آمنة لإكمال التسجيل."),
    "registeredContactMasked": ("Verification uses your registered contact (***).", "التحقق عبر وسيلة الاتصال المسجلة لديك (***)."),
    "identifierFormatError": ("Enter 6–24 digits; spaces, dashes and dots are allowed.", "أدخل من ٦ إلى ٢٤ رقماً؛ يمكن استخدام المسافات والشرطات والنقاط."),
    "otpExplanation": ("If your details are eligible, use the six-digit code provided to your registered contact. Never share this code.", "إذا كانت بياناتك مؤهلة، استخدم الرمز المكون من ستة أرقام المرسل لوسيلة الاتصال المسجلة. لا تشارك الرمز."),
    "otpDevelopmentNotice": ("Development adapter: real SMS/email delivery is not configured. No message was sent. Local codes require explicit server configuration.", "موفر تطوير: إرسال الرسائل النصية أو البريد الحقيقي غير مهيأ. لم يتم إرسال رسالة. إظهار رمز محلي يتطلب تهيئة صريحة للخادم."),
    "developmentCode": ("Local development code", "رمز التطوير المحلي"),
    "otpCode": ("Verification code", "رمز التحقق"),
    "otpFormatError": ("Enter the six-digit code.", "أدخل رمز التحقق المكون من ستة أرقام."),
    "verifyCode": ("Verify code", "تحقق من الرمز"),
    "resendCode": ("Request another code", "طلب رمز آخر"),
    "otpIncorrect": ("The verification code is incorrect.", "رمز التحقق غير صحيح."),
    "otpExpired": ("This code expired. Request another code.", "انتهت صلاحية الرمز. اطلب رمزاً آخر."),
    "otpUsed": ("This code was used or replaced. Start registration again.", "تم استخدام الرمز أو استبداله. ابدأ التسجيل مرة أخرى."),
    "otpAttemptsExceeded": ("Too many incorrect codes. Start registration again later.", "تجاوزت محاولات إدخال الرمز. ابدأ التسجيل لاحقاً."),
    "authorizeTitle": ("Authorize operation", "تفويض العملية"),
    "authorizationExplanation": ("Re-enter your current password to generate a short-lived token for this operation. Copy it, continue, and enter it on the confirmation page.", "أعد إدخال كلمة مرورك الحالية لإنشاء رمز مؤقت لهذه العملية. انسخه ثم تابع وأدخله في صفحة التأكيد."),
    "authorizationSuccess": ("Authorization token issued", "تم إصدار رمز التفويض"),
    "authorizationValidity": ("Validity in seconds", "الصلاحية بالثواني"),
    "authorizationToken": ("Authorization token", "رمز التفويض"),
    "copyToken": ("Copy Token", "نسخ الرمز"),
    "tokenCopied": ("Token copied (clears after 60 seconds)", "تم نسخ الرمز (يُمسح بعد ٦٠ ثانية)"),
    "authorizationExpired": ("The authorization token expired. Authorize again.", "انتهت صلاحية رمز التفويض. أعد التفويض."),
    "authorizationUsed": ("This authorization token has already been used.", "تم استخدام رمز التفويض مسبقاً."),
    "authorizationInvalid": ("Enter a valid token issued for this operation and these details.", "أدخل رمزاً صالحاً صادراً لهذه العملية وبياناتها."),
    "currentPasswordIncorrect": ("The current password is incorrect.", "كلمة المرور الحالية غير صحيحة."),
    "passwordsMatchLabel": ("Passwords match", "كلمتا المرور متطابقتان"),
    "securityOperationError": ("The operation could not be completed. Check the details and try again.", "تعذر إكمال العملية. راجع البيانات وحاول مجدداً."),
    "transferBalanceError": ("The available balance is insufficient.", "الرصيد المتاح غير كافٍ."),
    "internalTransferOnly": ("Only verified internal account destinations are supported. Existing external beneficiaries are preserved but cannot receive transfers here.", "تتاح التحويلات إلى الحسابات الداخلية المعروفة فقط. المستفيدون الخارجيون محفوظون ولكن التحويل إليهم غير متاح هنا."),
    "totalDebit": ("Total debit", "إجمالي الخصم"),
    "beneficiaryName": ("Beneficiary name", "اسم المستفيد"),
    "ownAccounts": ("Between my accounts", "بين حساباتي"),
    "transferReceipt": ("Transfer receipt", "إيصال التحويل"),
    "editTransfer": ("Edit transfer details", "تعديل بيانات التحويل"),
    "transferExplicitConfirmation": ("I confirm the reviewed beneficiary, amount and total debit.", "أؤكد المستفيد والمبلغ وإجمالي الخصم المعروض للمراجعة."),
    "updatePersonalInfo": ("Update personal information", "تحديث البيانات الشخصية"),
    "profileReviewExplanation": ("Submit email, phone or address changes electronically for bank review. Your verified details remain unchanged until approval. Identity and legal name changes require bank assistance.", "قدّم تغييرات البريد أو الهاتف أو العنوان إلكترونياً لمراجعة البنك. تبقى بياناتك المسجلة كما هي لحين الموافقة. تغييرات الهوية والاسم القانوني تتطلب مساعدة البنك."),
    "profilePendingReview": ("Submitted for bank review. Your verified information has not changed.", "تم التقديم لمراجعة البنك. لم تتغير بياناتك المسجلة بعد."),
    "profileRequestExists": ("You already have a pending information update request.", "لديك طلب تحديث بيانات قيد المراجعة بالفعل."),
    "biometricUnavailable": ("Biometrics are unavailable or no biometric credential is enrolled. Use your password and enroll biometrics in device settings.", "البصمة غير متاحة أو لا توجد بصمة مسجلة. استخدم كلمة المرور وسجّل بصمتك في إعدادات الجهاز."),
    "biometricReason": ("Verify your identity to enter banking", "تحقق من هويتك للدخول إلى الخدمات المصرفية"),
    "biometricEnabledMessage": ("Biometric re-entry enabled on this device. A valid backend session is still required.", "تم تفعيل الدخول بالبصمة على هذا الجهاز. تظل جلسة خادم سارية مطلوبة."),
    "biometricDisabledMessage": ("Biometric re-entry disabled on this device.", "تم تعطيل الدخول بالبصمة على هذا الجهاز."),
    "biometricUnlock": ("Unlock with biometrics", "فتح باستخدام البصمة"),
    "biometricLocked": ("Your session is locked. Unlock or sign out to use a password.", "جلستك مقفلة. افتح بالبصمة أو سجل الخروج لاستخدام كلمة المرور."),
}

for locale, index in (("en", 0), ("ar", 1)):
    path = ROOT / f"app_{locale}.arb"
    data = json.loads(path.read_text(encoding="utf-8"))
    data.update({key: values[index] for key, values in LABELS.items()})
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
