// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'تطبيق فيصل';

  @override
  String get bankName => 'بنك فيصل الإسلامي المصري';

  @override
  String get bankNameShort => 'بنك فيصل';

  @override
  String get appTagline => 'خدمات مصرفية بتصميم مدروس';

  @override
  String get demoMode => 'وضع تجريبي';

  @override
  String get demoDataNotice =>
      'هذا تطبيق تجريبي. جميع الأرصدة والبطاقات والمعاملات والطلبات محاكاة ولا ترتبط بأنظمة بنك فيصل الإسلامي المصري.';

  @override
  String get simulated => 'محاكاة';

  @override
  String get simulatedShort => 'تجريبي';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get all => 'الكل';

  @override
  String get apply => 'تطبيق';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get done => 'تم';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get submit => 'إرسال';

  @override
  String get optional => 'اختياري';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get loadingMore => 'جارٍ تحميل المزيد…';

  @override
  String get noData => 'لا يوجد ما يُعرض حالياً';

  @override
  String get refresh => 'تحديث';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get details => 'التفاصيل';

  @override
  String get share => 'مشاركة';

  @override
  String get download => 'تنزيل';

  @override
  String get amount => 'المبلغ';

  @override
  String amountWithCurrency(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get date => 'التاريخ';

  @override
  String get status => 'الحالة';

  @override
  String get reference => 'المرجع';

  @override
  String get home => 'الرئيسية';

  @override
  String get accounts => 'الحسابات';

  @override
  String get cards => 'البطاقات';

  @override
  String get transfers => 'التحويلات';

  @override
  String get payments => 'المدفوعات';

  @override
  String get more => 'المزيد';

  @override
  String get requests => 'الطلبات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get products => 'المنتجات';

  @override
  String get support => 'الدعم';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get admin => 'الإدارة';

  @override
  String get repayments => 'السداد';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get loginSubtitle =>
      'سجّل الدخول باسم المستخدم أو رقم البطاقة أو الحساب.';

  @override
  String get cardNumber => 'رقم البطاقة';

  @override
  String get cardNumberHint => '4508 1234 5678 9012';

  @override
  String get loginIdentifier => 'اسم المستخدم أو رقم البطاقة أو الحساب';

  @override
  String get loginIdentifierHint =>
      'أدخل اسم المستخدم أو رقم البطاقة أو الحساب';

  @override
  String get invalidLoginIdentifier =>
      'أدخل اسم مستخدم أو رقم بطاقة أو حساب صحيحًا.';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get temporaryPassword => 'رقم الحساب / كلمة المرور المؤقتة';

  @override
  String get temporaryPasswordHint =>
      'أدخل رقم حسابك عند تسجيل الدخول لأول مرة';

  @override
  String get rememberDevice => 'تذكر هذا الجهاز';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get securityNotice =>
      'لا تشارك كلمة المرور أو الرموز المؤقتة مع أي شخص. لن يطلبها بنك فيصل مطلقاً.';

  @override
  String get invalidCardNumber => 'أدخل رقم بطاقة صحيحاً (8 أرقام على الأقل).';

  @override
  String get passwordRequired => 'أدخل كلمة المرور.';

  @override
  String get loginFailed =>
      'تعذر تسجيل الدخول. تحقق من بياناتك وحاول مرة أخرى.';

  @override
  String get firstLoginBadge => 'إعداد أول مرة';

  @override
  String get createSecurePassword => 'أنشئ كلمة مرور آمنة';

  @override
  String setupSubtitle(String name) {
    return 'مرحباً $name. لحمايتك، يُرجى استبدال بيانات الدخول المؤقتة بكلمة مرور جديدة.';
  }

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get passwordStrength => 'قوة كلمة المرور';

  @override
  String get strengthWeak => 'ضعيفة';

  @override
  String get strengthFair => 'متوسطة';

  @override
  String get strengthGood => 'جيدة';

  @override
  String get strengthStrong => 'قوية';

  @override
  String get reqMinLength => '8 أحرف على الأقل';

  @override
  String get reqUppercase => 'حرف كبير واحد (A–Z)';

  @override
  String get reqLowercase => 'حرف صغير واحد (a–z)';

  @override
  String get reqDigit => 'رقم واحد (0–9)';

  @override
  String get reqSpecial => 'رمز خاص واحد (! @ # \$ % & *)';

  @override
  String get reqNoRepeat => 'بدون تكرار أي حرف 3 مرات متتالية';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get passwordPolicyError =>
      'كلمة المرور لا تستوفي جميع متطلبات الأمان.';

  @override
  String get continueToHome => 'حفظ كلمة المرور والمتابعة';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور.';

  @override
  String get setupExpired => 'انتهت جلسة الإعداد. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل تريد تسجيل الخروج فعلاً؟';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String greetingUser(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String get availableBalance => 'الرصيد المتاح';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get blockedBalance => 'الرصيد المحجوز';

  @override
  String get hideBalance => 'إخفاء الرصيد';

  @override
  String get showBalance => 'إظهار الرصيد';

  @override
  String get activeAccounts => 'الحسابات النشطة';

  @override
  String activeAccountsCount(int count) {
    return '$count حسابات نشطة';
  }

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get myAccounts => 'حساباتي';

  @override
  String get recentTransactions => 'أحدث المعاملات';

  @override
  String get viewAllTransactions => 'عرض كل المعاملات';

  @override
  String get noRecentTransactions => 'لا توجد معاملات حديثة';

  @override
  String get featured => 'مميز';

  @override
  String get accountTypeCurrent => 'الحساب الجاري';

  @override
  String get accountTypeInvestment => 'حساب الاستثمار';

  @override
  String get accountTypeSavings => 'حساب التوفير';

  @override
  String get accountTypeOther => 'حساب';

  @override
  String accountEndingIn(String last4) {
    return 'حساب $last4';
  }

  @override
  String get accountNumber => 'رقم الحساب';

  @override
  String get iban => 'رقم الآيبان';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get totalAcrossAccounts => 'الإجمالي في الحسابات المؤهلة';

  @override
  String get linkedCards => 'البطاقات المرتبطة';

  @override
  String get accountServices => 'خدمات الحساب';

  @override
  String get openAccount => 'فتح حساب';

  @override
  String get closeAccount => 'إغلاق الحساب';

  @override
  String get selectProduct => 'اختر المنتج';

  @override
  String get minimumBalance => 'الحد الأدنى للرصيد';

  @override
  String get closeAccountWarning =>
      'يتطلب إغلاق الحساب تسوية الرصيد وموافقة البنك.';

  @override
  String requestSubmittedMessage(String reference) {
    return 'تم إرسال الطلب $reference.';
  }

  @override
  String get cardsTitle => 'بطاقاتي';

  @override
  String get cardHolder => 'حامل البطاقة';

  @override
  String cardExpires(String month, String year) {
    return 'تنتهي في $month/$year';
  }

  @override
  String cardEndingIn(String last4) {
    return 'بطاقة تنتهي بـ $last4';
  }

  @override
  String get freezeCard => 'تجميد البطاقة';

  @override
  String get unfreezeCard => 'إلغاء تجميد البطاقة';

  @override
  String get reportLostCard => 'الإبلاغ عن فقدان البطاقة';

  @override
  String get reportStolenCard => 'الإبلاغ عن سرقة البطاقة';

  @override
  String get blockCardPermanently => 'إيقاف البطاقة نهائياً';

  @override
  String get requestReplacement => 'طلب بطاقة بديلة';

  @override
  String get requestRenewal => 'طلب تجديد البطاقة';

  @override
  String get resetPin => 'إعادة تعيين الرقم السري';

  @override
  String get cardLimits => 'حدود البطاقة';

  @override
  String get dailyPurchaseLimit => 'حد المشتريات اليومي';

  @override
  String get dailyAtmLimit => 'حد السحب اليومي';

  @override
  String get monthlyLimit => 'الحد الشهري';

  @override
  String get onlinePayments => 'المدفوعات عبر الإنترنت';

  @override
  String get internationalPayments => 'المدفوعات الدولية';

  @override
  String get contactlessPayments => 'المدفوعات اللاتلامسية';

  @override
  String get cardSettings => 'إعدادات البطاقة';

  @override
  String get creditDetails => 'تفاصيل الائتمان';

  @override
  String get outstandingBalance => 'الرصيد المستحق';

  @override
  String get statementBalance => 'رصيد الكشف';

  @override
  String get minimumPayment => 'الحد الأدنى للسداد';

  @override
  String get creditLimit => 'حد الائتمان';

  @override
  String get availableCredit => 'الائتمان المتاح';

  @override
  String get paymentDueDate => 'تاريخ استحقاق السداد';

  @override
  String get supplementaryCard => 'بطاقة إضافية';

  @override
  String get requestSupplementaryCard => 'طلب بطاقة إضافية';

  @override
  String get cardStatusActive => 'نشطة';

  @override
  String get cardStatusFrozen => 'مجمّدة';

  @override
  String get cardStatusLost => 'تم الإبلاغ عن فقدانها';

  @override
  String get cardStatusStolen => 'تم الإبلاغ عن سرقتها';

  @override
  String get cardStatusBlocked => 'موقوفة';

  @override
  String get cardStatusCancelled => 'ملغاة';

  @override
  String get cardStatusPendingActivation => 'بانتظار التفعيل';

  @override
  String get cardStatusExpired => 'منتهية';

  @override
  String get confirmFreezeTitle => 'تجميد هذه البطاقة؟';

  @override
  String get confirmFreezeBody =>
      'سيتم إيقاف مدفوعات البطاقة حتى تلغي التجميد، ويمكنك إلغاؤه في أي وقت.';

  @override
  String get confirmUnfreezeTitle => 'إلغاء تجميد هذه البطاقة?';

  @override
  String get confirmUnfreezeBody => 'سيتم تفعيل مدفوعات البطاقة مرة أخرى.';

  @override
  String get confirmBlockTitle => 'إيقاف هذه البطاقة نهائياً؟';

  @override
  String get confirmBlockBody =>
      'لا يمكن التراجع عن ذلك من التطبيق، وستحتاج إلى طلب بطاقة بديلة.';

  @override
  String get confirmLostTitle => 'الإبلاغ عن فقدان البطاقة؟';

  @override
  String get confirmLostBody => 'سيتم إيقاف البطاقة فوراً لحمايتك.';

  @override
  String get confirmStolenTitle => 'الإبلاغ عن سرقة البطاقة؟';

  @override
  String get confirmStolenBody =>
      'سيتم إيقاف البطاقة فوراً. تواصل مع البنك إذا كنت بحاجة إلى مساعدة عاجلة.';

  @override
  String get cardFrozenSuccess => 'تم تجميد البطاقة.';

  @override
  String get cardUnfrozenSuccess => 'تم إلغاء تجميد البطاقة.';

  @override
  String get cardBlockedSuccess => 'تم إيقاف البطاقة.';

  @override
  String get cardActionFailed =>
      'تعذر إتمام هذا الإجراء. يُرجى المحاولة مرة أخرى.';

  @override
  String get transactionsTitle => 'المعاملات';

  @override
  String get searchTransactions => 'ابحث بالوصف أو التاجر أو رقم المرجع';

  @override
  String get filters => 'عوامل التصفية';

  @override
  String get dateFrom => 'من تاريخ';

  @override
  String get dateTo => 'إلى تاريخ';

  @override
  String get transactionType => 'نوع المعاملة';

  @override
  String get direction => 'الاتجاه';

  @override
  String get debit => 'مدين';

  @override
  String get credit => 'دائن';

  @override
  String get minAmount => 'الحد الأدنى للمبلغ';

  @override
  String get maxAmount => 'الحد الأقصى للمبلغ';

  @override
  String get clearFilters => 'مسح التصفية';

  @override
  String get applyFilters => 'تطبيق التصفية';

  @override
  String get transactionDetails => 'تفاصيل المعاملة';

  @override
  String get fees => 'الرسوم';

  @override
  String get source => 'المصدر';

  @override
  String get destination => 'المستفيد';

  @override
  String get receiptAvailable => 'الإيصال متاح';

  @override
  String get noTransactionsFound => 'لا توجد معاملات مطابقة للتصفية';

  @override
  String get transactionTypeTransfer => 'تحويل';

  @override
  String get transactionTypeDeposit => 'إيداع';

  @override
  String get transactionTypeWithdrawal => 'سحب';

  @override
  String get transactionTypePurchase => 'مشتريات';

  @override
  String get transactionTypeBillPayment => 'سداد فاتورة';

  @override
  String get transactionTypeCardRepayment => 'سداد بطاقة';

  @override
  String get transactionTypeFee => 'رسوم';

  @override
  String get transactionTypeAdjustment => 'تسوية';

  @override
  String get transactionTypeSalary => 'راتب';

  @override
  String get transactionStatusPosted => 'مكتملة';

  @override
  String get transactionStatusPending => 'قيد الانتظار';

  @override
  String get transactionStatusFailed => 'فاشلة';

  @override
  String get transactionStatusReversed => 'معكوسة';

  @override
  String get transfersTitle => 'التحويلات';

  @override
  String get fromAccount => 'من حساب';

  @override
  String get toAccount => 'إلى حساب';

  @override
  String get savedBeneficiary => 'مستفيد محفوظ';

  @override
  String get newBeneficiary => 'مستفيد جديد';

  @override
  String get purpose => 'الغرض';

  @override
  String get note => 'ملاحظة';

  @override
  String get reviewTransfer => 'مراجعة التحويل';

  @override
  String get confirmTransfer => 'تأكيد التحويل';

  @override
  String get transferReviewNote =>
      'التحويلات في هذا التطبيق التجريبي محاكاة ولا تنقل أموالاً حقيقية.';

  @override
  String get transferSuccess => 'تم تنفيذ التحويل (محاكاة)';

  @override
  String transferSuccessMessage(String reference) {
    return 'رقم المرجع $reference';
  }

  @override
  String get transferFailed => 'تعذر إتمام التحويل.';

  @override
  String get beneficiaries => 'المستفيدون';

  @override
  String get addBeneficiary => 'إضافة مستفيد';

  @override
  String get bankNameLabel => 'اسم البنك';

  @override
  String get nickname => 'اسم مختصر';

  @override
  String get deleteBeneficiary => 'حذف المستفيد';

  @override
  String get insufficientFunds => 'الرصيد المتاح غير كافٍ.';

  @override
  String get paymentsTitle => 'المدفوعات';

  @override
  String get payBill => 'سداد فاتورة';

  @override
  String get biller => 'الجهة';

  @override
  String get billerCategory => 'فئة الجهة';

  @override
  String get payNow => 'ادفع الآن';

  @override
  String get paymentSuccess => 'تمت عملية الدفع (محاكاة)';

  @override
  String get paymentHistory => 'سجل المدفوعات';

  @override
  String get branchServices => 'خدمات الفروع';

  @override
  String get cashDepositRequest => 'طلب إيداع نقدي';

  @override
  String get cashWithdrawalRequest => 'طلب سحب نقدي';

  @override
  String get branchServiceNote =>
      'خدمات الفروع تُنشئ طلباً ليتولى البنك تنفيذه، ولا يتم نقل أي أموال تلقائياً.';

  @override
  String get selectBiller => 'اختر الجهة';

  @override
  String get repaymentsTitle => 'سداد البطاقات الائتمانية';

  @override
  String get repayCreditCard => 'سداد البطاقة الائتمانية';

  @override
  String get selectCard => 'اختر البطاقة';

  @override
  String get selectFundingAccount => 'اختر حساب السداد';

  @override
  String get repaymentOption => 'خيار السداد';

  @override
  String get optionFullBalance => 'سداد كامل الرصيد المستحق';

  @override
  String get optionStatementBalance => 'سداد رصيد الكشف الحالي';

  @override
  String get optionMinimumPayment => 'الحد الأدنى للسداد';

  @override
  String get optionCustomAmount => 'مبلغ مخصص';

  @override
  String get charges => 'الرسوم';

  @override
  String get totalPayable => 'إجمالي المطلوب';

  @override
  String get confirmRepayment => 'تأكيد السداد';

  @override
  String get repaymentSuccess => 'تم السداد (محاكاة)';

  @override
  String repaymentSuccessMessage(String reference) {
    return 'رقم مرجع السداد $reference';
  }

  @override
  String get repaymentNote =>
      'يتم تنفيذ السداد عبر خدمة دفع محاكاة، ولا يتم أي تحويل حقيقي.';

  @override
  String get repaymentNotEligible => 'هذا السداد غير متاح بالحساب المحدد.';

  @override
  String get repaymentHistory => 'سجل السداد';

  @override
  String get requestsTitle => 'الطلبات';

  @override
  String get newRequest => 'طلب جديد';

  @override
  String get requestDetails => 'تفاصيل الطلب';

  @override
  String get requestType => 'نوع الطلب';

  @override
  String get submittedOn => 'تاريخ الإرسال';

  @override
  String get statusHistory => 'سجل الحالة';

  @override
  String get decisionReason => 'سبب القرار';

  @override
  String get provideInformation => 'تقديم المعلومات';

  @override
  String get uploadDocument => 'رفع مستند';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get awaitingYourInformation => 'يحتاج البنك إلى معلومات إضافية منك.';

  @override
  String get requestReferenceCopied => 'تم نسخ رقم المرجع';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusSubmitted => 'تم الإرسال';

  @override
  String get statusUnderReview => 'قيد المراجعة';

  @override
  String get statusPendingCustomerInfo => 'مطلوب إجراء منك';

  @override
  String get statusPendingApproval => 'بانتظار الموافقة';

  @override
  String get statusApproved => 'تمت الموافقة';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusProcessing => 'قيد التنفيذ';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get requestTypeAccountOpen => 'فتح حساب';

  @override
  String get requestTypeAccountClose => 'إغلاق حساب';

  @override
  String get requestTypeCardReplacement => 'بدل فاقد بطاقة';

  @override
  String get requestTypeCardRenewal => 'تجديد بطاقة';

  @override
  String get requestTypeCardCancellation => 'إلغاء بطاقة';

  @override
  String get requestTypeLimitIncrease => 'زيادة حد البطاقة';

  @override
  String get requestTypeLimitDecrease => 'تخفيض حد البطاقة';

  @override
  String get requestTypePinReset => 'إعادة تعيين الرقم السري';

  @override
  String get requestTypeSupplementary => 'بطاقة إضافية';

  @override
  String get requestTypeCreditCard => 'طلب بطاقة ائتمانية';

  @override
  String get requestTypeInvestment => 'منتج استثماري';

  @override
  String get requestTypeInfoUpdate => 'تحديث بياناتي';

  @override
  String get requestTypeOther => 'خدمة أخرى';

  @override
  String get noRequests => 'لا توجد طلبات حتى الآن';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get unreadNotifications => 'غير مقروء';

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get announcementDetails => 'إعلان';

  @override
  String get maintenanceNotice => 'إشعار خدمة';

  @override
  String get productsTitle => 'اكتشف';

  @override
  String get offersTitle => 'العروض';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get eligibility => 'الأهلية';

  @override
  String get pricingInformation => 'معلومات التسعير';

  @override
  String get applyNow => 'تقدم بطلب';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get profileTitle => 'الملف الشخصي';

  @override
  String get personalInformation => 'البيانات الشخصية';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get phoneLabel => 'رقم الهاتف المحمول';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get customerNumber => 'رقم العميل';

  @override
  String get identityVerified => 'تم التحقق من الهوية';

  @override
  String get securitySettings => 'الأمان';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get activeSessions => 'الجلسات النشطة';

  @override
  String get thisDevice => 'هذا الجهاز';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get notificationPreferences => 'تفضيلات الإشعارات';

  @override
  String get transactionNotifications => 'تنبيهات المعاملات';

  @override
  String get marketingNotifications => 'العروض والتسويق';

  @override
  String get allNotifications => 'جميع الإشعارات';

  @override
  String get biometricLogin => 'الدخول بالبصمة';

  @override
  String get biometricUnavailable =>
      'البصمة غير متاحة أو لا توجد بصمة مسجلة. استخدم كلمة المرور وسجّل بصمتك في إعدادات الجهاز.';

  @override
  String get about => 'عن التطبيق';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get faqQ1 => 'كيف أعيد تعيين كلمة المرور؟';

  @override
  String get faqA1 =>
      'اختر \"نسيت كلمة المرور\" في شاشة الدخول، وسيوفر لك أحد ممثلي البنك رمزاً مؤقتاً لإعادة التعيين.';

  @override
  String get faqQ2 => 'لماذا تم تجميد بطاقتي؟';

  @override
  String get faqA2 =>
      'التجميد إيقاف مؤقت تتحكم فيه بنفسك. افتح البطاقة واختر \"إلغاء تجميد البطاقة\" لتفعيل المدفوعات مرة أخرى.';

  @override
  String get faqQ3 => 'هل التحويلات حقيقية؟';

  @override
  String get faqA3 =>
      'لا. يستخدم هذا التطبيق التجريبي خدمة دفع محاكاة ولا ينقل أموالاً حقيقية.';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get profileUpdated => 'تم تحديث ملفك الشخصي.';

  @override
  String get preferencesUpdated => 'تم تحديث التفضيلات.';

  @override
  String get supportTitle => 'الدعم';

  @override
  String get newTicket => 'محادثة جديدة';

  @override
  String get subject => 'الموضوع';

  @override
  String get message => 'الرسالة';

  @override
  String get sendMessage => 'إرسال الرسالة';

  @override
  String get noTickets => 'لا توجد محادثات بعد';

  @override
  String get contactChannels => 'قنوات التواصل';

  @override
  String get callUs => 'اتصل بالبنك';

  @override
  String get branchLocator => 'ابحث عن فرع';

  @override
  String get adminPortal => 'بوابة الإدارة';

  @override
  String get dashboard => 'لوحة المعلومات';

  @override
  String get customers => 'العملاء';

  @override
  String get requestQueue => 'قائمة الطلبات';

  @override
  String get announcementsAdmin => 'الإعلانات';

  @override
  String get productsAndOffers => 'المنتجات والعروض';

  @override
  String get auditLogs => 'سجل التدقيق';

  @override
  String get demoStatistics => 'إحصاءات تجريبية';

  @override
  String get pendingRequests => 'طلبات معلقة';

  @override
  String get publishedAnnouncements => 'إعلانات منشورة';

  @override
  String get scheduledMaintenance => 'صيانة مجدولة';

  @override
  String get recentActions => 'أحدث الإجراءات الإدارية';

  @override
  String get reviewQueue => 'قائمة المراجعة';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get requestInformation => 'طلب معلومات';

  @override
  String get assignReviewer => 'تعيين مراجع';

  @override
  String get internalNote => 'ملاحظة داخلية';

  @override
  String get customerExplanation => 'رسالة إلى العميل';

  @override
  String get confirmApprove => 'هل تريد الموافقة على هذا الطلب؟';

  @override
  String get confirmReject => 'هل تريد رفض هذا الطلب؟';

  @override
  String get rejectionReasonRequired => 'أدخل سبباً للرفض (5 أحرف على الأقل).';

  @override
  String get createAnnouncement => 'إنشاء إعلان';

  @override
  String get publish => 'نشر';

  @override
  String get archive => 'أرشفة';

  @override
  String get duplicate => 'تكرار';

  @override
  String get preview => 'معاينة';

  @override
  String get audience => 'الجمهور';

  @override
  String get audienceAll => 'جميع العملاء';

  @override
  String get priority => 'الأولوية';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get priorityHigh => 'عالية';

  @override
  String get schedule => 'جدولة';

  @override
  String get titleEn => 'العنوان (بالإنجليزية)';

  @override
  String get titleAr => 'العنوان (بالعربية)';

  @override
  String get bodyEn => 'المحتوى (بالإنجليزية)';

  @override
  String get bodyAr => 'المحتوى (بالعربية)';

  @override
  String get createdOn => 'تاريخ الإنشاء';

  @override
  String get assignedTo => 'مسند إلى';

  @override
  String get unassigned => 'غير مسند';

  @override
  String get noAccess => 'لا تملك صلاحية عرض هذه الصفحة.';

  @override
  String get errorNetwork =>
      'تعذر الوصول إلى الخادم. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorTimeout => 'انتهت مهلة الطلب. يُرجى المحاولة مرة أخرى.';

  @override
  String get errorUnauthorized => 'انتهت جلستك. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorForbidden => 'لا يُسمح لك بتنفيذ هذا الإجراء.';

  @override
  String get errorNotFound => 'لم نتمكن من العثور على ما تبحث عنه.';

  @override
  String get errorValidation => 'يُرجى مراجعة الحقول المحددة.';

  @override
  String get errorRateLimited =>
      'محاولات كثيرة جداً. انتظر قليلاً ثم حاول مرة أخرى.';

  @override
  String get errorUnexpected => 'حدث خطأ ما. يُرجى المحاولة مرة أخرى.';

  @override
  String get startupRestoreFailed =>
      'تعذّر استعادة جلستك المحفوظة. تحقّق من اتصالك ثم حاول مرة أخرى.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً.';

  @override
  String get invalidAmount => 'أدخل مبلغاً صحيحاً.';

  @override
  String get amountPositive => 'يجب أن يكون المبلغ أكبر من صفر.';

  @override
  String get invalidDate => 'أدخل تاريخاً صحيحاً.';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get readOnlyAccess => 'صلاحية قراءة فقط';

  @override
  String get registerTitle => 'التسجيل في الخدمات المصرفية الرقمية';

  @override
  String get registrationExplanation =>
      'أدخل رقم بطاقتك أو حسابك الحالي. ثم تحقق برمز عبر بيانات الاتصال المسجلة لدى البنك. لا تحتاج كلمة مرور مصرفية حالية.';

  @override
  String get registrationVerified =>
      'تم التحقق من وسيلة الاتصال. أنشئ كلمة مرور آمنة لإكمال التسجيل.';

  @override
  String get registeredContactMasked =>
      'التحقق عبر وسيلة الاتصال المسجلة لديك (***).';

  @override
  String get identifierFormatError =>
      'أدخل من ٦ إلى ٢٤ رقماً؛ يمكن استخدام المسافات والشرطات والنقاط.';

  @override
  String get otpExplanation =>
      'إذا كانت بياناتك مؤهلة، استخدم الرمز المكون من ستة أرقام المرسل لوسيلة الاتصال المسجلة. لا تشارك الرمز.';

  @override
  String get otpDevelopmentNotice =>
      'عشان تجرّب بنفسك، اكتب الرمز الظاهر تحت. لم تُرسل رسالة فعلية؛ إرسال SMS والبريد غير مهيأ حاليًا. إعادة الإرسال بتغيّر الرمز وتلغي القديم.';

  @override
  String get developmentCode => 'رمز التطوير المحلي';

  @override
  String get otpCode => 'رمز التحقق';

  @override
  String get otpFormatError => 'أدخل رمز التحقق المكون من ستة أرقام.';

  @override
  String get verifyCode => 'تحقق من الرمز';

  @override
  String get resendCode => 'طلب رمز آخر';

  @override
  String get otpIncorrect => 'رمز التحقق غير صحيح.';

  @override
  String get otpExpired => 'انتهت صلاحية الرمز. اطلب رمزاً آخر.';

  @override
  String get otpUsed => 'تم استخدام الرمز أو استبداله. ابدأ التسجيل مرة أخرى.';

  @override
  String get otpAttemptsExceeded =>
      'تجاوزت محاولات إدخال الرمز. ابدأ التسجيل لاحقاً.';

  @override
  String get authorizeTitle => 'تفويض العملية';

  @override
  String get authorizationExplanation =>
      'أعد إدخال كلمة مرورك الحالية لإنشاء رمز مؤقت لهذه العملية. انسخه ثم تابع وأدخله في صفحة التأكيد.';

  @override
  String get authorizationSuccess => 'تم إصدار رمز التفويض';

  @override
  String get authorizationValidity => 'الصلاحية بالثواني';

  @override
  String get authorizationToken => 'رمز التفويض';

  @override
  String get copyToken => 'نسخ الرمز';

  @override
  String get tokenCopied => 'تم نسخ الرمز (يُمسح بعد ٦٠ ثانية)';

  @override
  String get authorizationExpired => 'انتهت صلاحية رمز التفويض. أعد التفويض.';

  @override
  String get authorizationUsed => 'تم استخدام رمز التفويض مسبقاً.';

  @override
  String get authorizationInvalid =>
      'أدخل رمزاً صالحاً صادراً لهذه العملية وبياناتها.';

  @override
  String get currentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get passwordsMatchLabel => 'كلمتا المرور متطابقتان';

  @override
  String get securityOperationError =>
      'تعذر إكمال العملية. راجع البيانات وحاول مجدداً.';

  @override
  String get transferBalanceError => 'الرصيد المتاح غير كافٍ.';

  @override
  String get internalTransferOnly =>
      'تتاح التحويلات إلى الحسابات الداخلية المعروفة فقط. المستفيدون الخارجيون محفوظون ولكن التحويل إليهم غير متاح هنا.';

  @override
  String get totalDebit => 'إجمالي الخصم';

  @override
  String get beneficiaryName => 'اسم المستفيد';

  @override
  String get ownAccounts => 'بين حساباتي';

  @override
  String get transferReceipt => 'إيصال التحويل';

  @override
  String get editTransfer => 'تعديل بيانات التحويل';

  @override
  String get transferExplicitConfirmation =>
      'أؤكد المستفيد والمبلغ وإجمالي الخصم المعروض للمراجعة.';

  @override
  String get updatePersonalInfo => 'تحديث البيانات الشخصية';

  @override
  String get profileReviewExplanation =>
      'قدّم تغييرات البريد أو الهاتف أو العنوان إلكترونياً لمراجعة البنك. تبقى بياناتك المسجلة كما هي لحين الموافقة. تغييرات الهوية والاسم القانوني تتطلب مساعدة البنك.';

  @override
  String get profilePendingReview =>
      'تم التقديم لمراجعة البنك. لم تتغير بياناتك المسجلة بعد.';

  @override
  String get profileRequestExists =>
      'لديك طلب تحديث بيانات قيد المراجعة بالفعل.';

  @override
  String get biometricReason => 'تحقق من هويتك للدخول إلى الخدمات المصرفية';

  @override
  String get biometricEnabledMessage =>
      'تم تفعيل الدخول بالبصمة على هذا الجهاز. تظل جلسة خادم سارية مطلوبة.';

  @override
  String get biometricDisabledMessage =>
      'تم تعطيل الدخول بالبصمة على هذا الجهاز.';

  @override
  String get biometricUnlock => 'فتح باستخدام البصمة';

  @override
  String get biometricLocked =>
      'جلستك مقفلة. افتح بالبصمة أو سجل الخروج لاستخدام كلمة المرور.';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get usernameHint =>
      'من ٣ إلى ٣٠ حرفًا إنجليزيًا ورقمًا فقط، ويبدأ بحرف. بدون نقط أو رموز.';

  @override
  String get usernameInvalid => 'اختر اسم مستخدم صحيحًا.';

  @override
  String get usernameAvailable => 'اسم المستخدم متاح';

  @override
  String get usernameTaken =>
      'اسم المستخدم غير متاح. اختر أحد الاقتراحات أو اكتب اسمًا آخر.';

  @override
  String get investmentsTitle => 'الشهادات وصناديق الاستثمار';

  @override
  String get investmentSimulationNotice =>
      'محاكاة تطوير: يُخصم الاشتراك من حسابك فورًا. أسعار وثائق الصناديق محاكاة، ولا يوجد استثمار حقيقي أو عائد مضمون.';

  @override
  String get investmentProduct => 'الشهادة أو صندوق الاستثمار';

  @override
  String get investmentMinimum => 'الحد الأدنى للاشتراك';

  @override
  String get investmentStep => 'مضاعفات المبلغ';

  @override
  String get investmentUnits => 'الوثائق / الوحدات';

  @override
  String get investmentMaximumPenalty => 'أقصى خصم للكسر المبكر';

  @override
  String get investmentPenaltyFormula =>
      'خصم الشهادة = أصل المبلغ × النسبة القصوى × الأيام المتبقية ÷ إجمالي الأيام؛ ويصبح صفرًا عند الاستحقاق. لا توجد غرامة مدة للصناديق في هذه المحاكاة.';

  @override
  String get investmentAmountError =>
      'التزم بالحد الأدنى للاشتراك ومضاعفات المبلغ المحددة.';

  @override
  String get investmentSubscribe => 'ربط / اشتراك';

  @override
  String get myInvestments => 'استثماراتي';

  @override
  String get noInvestments => 'لا توجد استثمارات مرتبطة حتى الآن.';

  @override
  String get investmentPrincipal => 'أصل المبلغ';

  @override
  String get investmentActive => 'ساري';

  @override
  String get investmentRedeemed => 'تم الاسترداد';

  @override
  String get investmentMaturity => 'تاريخ الاستحقاق';

  @override
  String get investmentRedeem => 'استرداد / كسر';

  @override
  String get investmentReview => 'مراجعة عملية الاستثمار';

  @override
  String get investmentPenalty => 'خصم الكسر المبكر';

  @override
  String get investmentNetCredit => 'صافي المبلغ المعاد لحسابك';

  @override
  String get investmentConfirm =>
      'أؤكد عملية الاستثمار المعروضة وسياسة الخصم الخاصة بها.';

  @override
  String get investmentCompleted => 'تم تنفيذ عملية الاستثمار';

  @override
  String get investmentPending => 'العملية في انتظار الاكتمال';

  @override
  String get investmentUnavailable =>
      'هذا الاستثمار غير متاح أو تم استرداده بالفعل. حدّث قائمة استثماراتك.';

  @override
  String get exchangeRatesTitle => 'أسعار صرف العملات';

  @override
  String get fxIndicativeNotice =>
      'أسعار عالمية استرشادية بالجنيه المصري. أسعار الشراء والبيع محسوبة بهامش محاكاة؛ وليست تسعير البنك للتعامل ولا تنفذ عملية صرف.';

  @override
  String get fxProviderTime => 'وقت رصد السعر';

  @override
  String get fxFetchedTime => 'آخر جلب من الخادم';

  @override
  String get fxDelaySeconds => 'تأخير المصدر (بالثواني)';

  @override
  String get fxSpread => 'هامش المحاكاة الكلي';

  @override
  String get fxMarketOpen => 'جلسة السوق: مفتوحة';

  @override
  String get fxMarketClosed => 'جلسة السوق مغلقة / أسعار مرجعية';

  @override
  String get fxStale => 'آخر أسعار معروفة: البيانات قديمة أو المصدر غير متاح.';

  @override
  String get fxRefreshNotice =>
      'تحديث كل ٦٠ ثانية أثناء فتح الصفحة. المصدر المجاني قد يتأخر ١٥ دقيقة؛ وقد تكون الأسعار المرجعية اليومية وأسعار السوق المغلق أقدم.';

  @override
  String get fxUnit => 'جنيه مصري لكل وحدة من العملة الأجنبية';

  @override
  String get fxBuy => 'شراء (محاكاة)';

  @override
  String get fxSell => 'بيع (محاكاة)';

  @override
  String get fxMid => 'متوسط السعر المرجعي';

  @override
  String get fxSource => 'مصدر الرصد';

  @override
  String get fxAttribution => 'الأسعار مقدمة من exchangerate.dev ↗';

  @override
  String get fxUnavailable => 'أسعار العملات غير متاحة مؤقتًا. أعد المحاولة.';

  @override
  String get currencyUsd => 'USD · الدولار الأمريكي';

  @override
  String get currencySar => 'SAR · الريال السعودي';

  @override
  String get currencyEur => 'EUR · اليورو';

  @override
  String get currencyAed => 'AED · الدرهم الإماراتي';

  @override
  String get currencyGbp => 'GBP · الجنيه الإسترليني';

  @override
  String get currencyKwd => 'KWD · الدينار الكويتي';

  @override
  String get currencyQar => 'QAR · الريال القطري';

  @override
  String get currencyChf => 'CHF · الفرنك السويسري';

  @override
  String get certificatesTitle => 'الشهادات';

  @override
  String get investmentFundsTitle => 'صناديق الاستثمار';

  @override
  String get myCertificates => 'شهاداتي';

  @override
  String get myFunds => 'استثماراتي في الصناديق';

  @override
  String get fxSearch => 'ابحث باسم العملة أو الرمز (دولار، ريال…)';

  @override
  String get fxAll => 'الكل';

  @override
  String get fxFavorites => 'المفضلة';

  @override
  String get fxArabCurrencies => 'عملات عربية';

  @override
  String get fxForeignCurrencies => 'عملات أجنبية';

  @override
  String get fxFavoriteAdd => 'إضافة للمفضلة';

  @override
  String get fxFavoriteRemove => 'إزالة من المفضلة';

  @override
  String get fxEmpty => 'لا توجد عملات مطابقة';

  @override
  String get fxEgpBase => 'جنيه مصري · EGP';

  @override
  String get fxDetails => 'تفاصيل الأسعار والمصدر';

  @override
  String get fxDayChangeUnavailable => 'التغير اليومي غير متاح';

  @override
  String get otpDevelopmentUnavailable =>
      'لم يصدر رمز تجريبي لهذا الرقم. للتجربة استخدم كارت عميل لم يسجّل بعد؛ العميل المسجّل يدخل من شاشة تسجيل الدخول.';

  @override
  String get admSubtitle => 'راجع طلبات العملاء وانشر تنبيهات البنك';

  @override
  String get admAll => 'كل الطلبات';

  @override
  String get admSearch => 'ابحث برقم الطلب';

  @override
  String get admEmptyRequests => 'لا توجد طلبات مطابقة لهذا الفلتر';

  @override
  String get admLoadMore => 'عرض المزيد';

  @override
  String get admDetails => 'تفاصيل الطلب';

  @override
  String get admCustomer => 'العميل';

  @override
  String get admHistory => 'سجل الطلب';

  @override
  String get admDecisionSaved => 'تم تسجيل القرار وإخطار العميل';

  @override
  String get admEmptyNotices => 'لا توجد إعلانات حاليًا';

  @override
  String get admPublicEmpty => 'لا توجد تنبيهات عاجلة حاليًا';

  @override
  String get admPublicTitle => 'تنبيهات البنك';

  @override
  String get admPublicSubtitle => 'آخر التحديثات المهمة قبل تسجيل الدخول';

  @override
  String get admLocation => 'مكان ظهور الإعلان';

  @override
  String get admHome => 'الصفحة الرئيسية للعميل';

  @override
  String get admBeforeLogin => 'قبل تسجيل الدخول';

  @override
  String get admBoth => 'الرئيسية وقبل تسجيل الدخول';

  @override
  String get admPublicPolicy =>
      'إعلانات ما قبل الدخول عامة للجميع. لا تضع بيانات عملاء أو معلومات خاصة. الإعلانات الموجهة تظل في الرئيسية.';

  @override
  String get admTitleEn => 'العنوان بالإنجليزية';

  @override
  String get admTitleAr => 'العنوان بالعربية';

  @override
  String get admBodyEn => 'الرسالة بالإنجليزية';

  @override
  String get admBodyAr => 'الرسالة بالعربية';

  @override
  String get admRequired => 'أدخل ٣ أحرف على الأقل';

  @override
  String get admPriority => 'الأولوية';

  @override
  String get admDraft => 'مسودة';

  @override
  String get admPublished => 'منشور';

  @override
  String get admArchived => 'مؤرشف';

  @override
  String get admSaved => 'تم حفظ الإعلان';

  @override
  String get admEdit => 'تعديل الإعلان';

  @override
  String get admPublishConfirm => 'هل تريد نشر الإعلان في المكان المختار؟';

  @override
  String get admArchiveConfirm =>
      'هل تريد أرشفة الإعلان وإخفاءه من شاشات العملاء؟';

  @override
  String get admDataEmail => 'البريد الإلكتروني';

  @override
  String get admDataPhone => 'رقم الهاتف';

  @override
  String get admDataAddress => 'العنوان';

  @override
  String get admDataProduct => 'المنتج المصرفي';

  @override
  String get admDataAccount => 'الحساب';

  @override
  String get admDataCurrency => 'العملة';

  @override
  String get admDataCard => 'البطاقة';

  @override
  String get admDataAmount => 'المبلغ المطلوب';

  @override
  String get admDataReason => 'السبب';

  @override
  String get cardApplyTitle => 'طلب بطاقة جديدة';

  @override
  String get cardApplySubtitle =>
      'اختر بطاقتك والحساب المرتبط بها. الإصدار يتطلب موافقة البنك.';

  @override
  String get cardPreview => 'معاينة التصميم';

  @override
  String get cardSelect => 'اختيار البطاقة';

  @override
  String get cardSelected => 'البطاقة المختارة';

  @override
  String get cardChooseAccount => 'الحساب المرتبط';

  @override
  String get cardInvestmentOnly => 'حساب استثماري بالجنيه المصري';

  @override
  String get cardDomesticAccount => 'حساب نشط بالجنيه المصري';

  @override
  String get cardForeignOnly => 'حسابات الدولار أو اليورو أو الريال فقط';

  @override
  String get cardYouthOnly => 'للشباب أقل من ٢١ سنة بتاريخ ميلاد موثق';

  @override
  String get cardAgeUnverified =>
      'يلزم تاريخ ميلاد موثق لدى البنك. تواصل مع البنك لتوثيقه.';

  @override
  String get cardYouthAge => 'بطاقة يوث متاحة فقط لمن هم أقل من ٢١ سنة.';

  @override
  String get cardInvestmentRequired =>
      'تحتاج حسابًا استثماريًا نشطًا بالجنيه لهذه البطاقة.';

  @override
  String get cardForeignRequired =>
      'تحتاج حسابًا نشطًا بالدولار أو اليورو أو الريال لهذه البطاقة.';

  @override
  String get cardAccountRequired =>
      'تحتاج حسابًا مؤهلًا ونشطًا بالجنيه المصري.';

  @override
  String get cardUnavailable =>
      'البطاقة أو العميل لم يعد مؤهلًا. حدّث الصفحة وراجع الخيارات المتاحة.';

  @override
  String get cardOpenAccount => 'فتح صفحة الحسابات';

  @override
  String get cardReviewTitle => 'مراجعة طلب البطاقة';

  @override
  String get cardApprovalNotice =>
      'الإرسال ينشئ طلبًا فقط. تُصدر البطاقة بعد موافقة الأدمن، ويظل التسليم والتفعيل قيد الانتظار.';

  @override
  String get cardAnnualFee => 'الرسوم السنوية المحددة';

  @override
  String get cardSubmitRequest => 'تأكيد وإرسال الطلب';

  @override
  String get cardRequestReceived => 'تم استلام الطلب — بانتظار مراجعة البنك';

  @override
  String get cardMyRequests => 'طلبات بطاقاتي';

  @override
  String get cardRequestExists =>
      'لديك طلب بطاقة قيد المراجعة بالفعل. تابع حالته بالأسفل.';

  @override
  String get cardNoRequests => 'لا توجد طلبات بطاقات بعد';

  @override
  String get cardProductLabel => 'فئة البطاقة';

  @override
  String get cardPendingActivation => 'بانتظار التسليم والتفعيل';

  @override
  String get cardBackCards => 'العودة لبطاقاتي';

  @override
  String get transferTypeLabel => 'نوع التحويل';

  @override
  String get transferOwnType => 'بين حساباتي';

  @override
  String get transferInternalType => 'داخلي — نفس البنك';

  @override
  String get transferDomesticType => 'خارجي — بنوك أخرى داخل مصر';

  @override
  String get transferInternationalType => 'تحويل دولي';

  @override
  String get transferWalletType => 'تحويل إلى محفظة';

  @override
  String get transferInstapayType => 'تحويل إنستاباي';

  @override
  String get transferSimulationOnly =>
      'محاكاة محلية: يتم الخصم من رصيدك التجريبي فقط. لا تُرسل دفعة لبنك أو محفظة أو شبكة إنستاباي.';

  @override
  String get transferSameCurrency =>
      'بنفس عملة حساب المصدر. تحويل العملات غير متاح.';

  @override
  String get transferBankName => 'اسم البنك المستلم';

  @override
  String get transferAccountOrIban => 'رقم الحساب أو الآيبان';

  @override
  String get transferCountry => 'رمز الدولة مثل US أو SA';

  @override
  String get transferSwift => 'سويفت / BIC';

  @override
  String get transferWalletNumber => 'رقم موبايل المحفظة المصرية';

  @override
  String get transferIpa => 'عنوان IPA أو رقم موبايل مصري';

  @override
  String get transferIpaHint => 'مثال: fictionaluser@instapay';

  @override
  String get transferDestinationInvalid =>
      'راجع المستفيد وصيغة الحساب أو الموبايل أو IPA وبيانات البنك والعملة.';

  @override
  String get transferProviderMissing =>
      'لا يوجد مزوّد تحويل مهيأ لهذا المسار. لم يُخصم أي مبلغ.';

  @override
  String get transferUnavailableType => 'غير مهيأ';

  @override
  String get transferSimulationSuccess => 'اكتملت محاكاة التحويل';

  @override
  String get transferProviderReference => 'مرجع المحاكاة';

  @override
  String get transferDeliveryFailure =>
      'فشلت محاكاة التحويل. حدّث الرصيد ثم أعد المحاولة بأمان.';

  @override
  String get transferNoEligibleSource =>
      'لا يوجد حساب مؤهل لهذا النوع. التحويل المحلي والمحفظة وإنستاباي تتطلب الجنيه المصري.';

  @override
  String get ownFxAvailable => 'تحويل العملة متاح بين حساباتك أنت فقط.';

  @override
  String get ownFxRate => 'سعر الصرف';

  @override
  String get ownFxReceived => 'المبلغ الذي سيصل';

  @override
  String get ownFxAsOf => 'تاريخ بيانات السوق';

  @override
  String get ownFxExpires => 'السعر صالح حتى';

  @override
  String get ownFxSimulation =>
      'تحويل تجريبي بأسعار شراء وبيع استرشادية وهامشها، وقد تكون متأخرة. هذا ليس سعر تنفيذ بنكي حقيقي.';

  @override
  String get ownFxExpired =>
      'انتهت صلاحية سعر التحويل أو تم استخدامه. عدّل التحويل وراجع سعرًا جديدًا ثم أعد التفويض.';

  @override
  String get ownFxInvalid =>
      'راجع سعرًا جديدًا لنفس العميل والحسابات والمبلغ قبل التفويض.';

  @override
  String get ownFxAmountInvalid =>
      'المبلغ بعد التحويل أصغر من الحد الدقيق أو يتجاوز نطاق الرصيد المسموح.';

  @override
  String get publicWelcomeTitle => 'مرحبًا بك في بنك فيصل';

  @override
  String get publicWelcomeSubtitle =>
      'خدماتك البنكية ووسائل التواصل في مكان واحد.';

  @override
  String get publicBranches => 'الفروع';

  @override
  String get publicAtms => 'الصراف الآلي';

  @override
  String get publicCallCenter => 'الكول سنتر';

  @override
  String get publicSignInHint => 'ادخل إلى حساباتك';

  @override
  String get publicBranchesHint => 'العناوين واللوكيشن';

  @override
  String get publicAtmsHint => 'اعثر على ماكينة';

  @override
  String get publicCallCenterHint => 'نحن هنا لمساعدتك';

  @override
  String get publicBranchSearch => 'ابحث باسم الفرع أو المنطقة أو العنوان';

  @override
  String get publicGovernorate => 'المحافظة';

  @override
  String get publicAllGovernorates => 'كل المحافظات';

  @override
  String get publicResultCount => 'النتائج';

  @override
  String get publicDirectoryEmpty =>
      'لا توجد فروع مطابقة. جرّب منطقة أو محافظة أخرى.';

  @override
  String get publicDirectoryFailed => 'تعذّر تحميل دليل الفروع. حاول مرة أخرى.';

  @override
  String get publicOpenMap => 'افتح اللوكيشن';

  @override
  String get publicMapSearchNote =>
      'افتح نقطة الفرع أو ابحث باسمه وعنوانه على الخريطة.';

  @override
  String get publicAtmSubtitle => 'ابحث عن ماكينة صراف آلي';

  @override
  String get publicAtmNote =>
      'ابحث عن ماكينات بنك فيصل على الخريطة، أو استخدم محدد الفروع والصراف الآلي الرسمي للبنك.';

  @override
  String get publicAtmArea => 'المدينة أو المنطقة (اختياري)';

  @override
  String get publicSearchAtm => 'ابحث على الخريطة';

  @override
  String get publicOfficialLocator => 'محدد المواقع الرسمي للبنك';

  @override
  String get publicCallEgypt => 'الخط الساخن من داخل مصر';

  @override
  String get publicHotlineAvailability =>
      'خدمة العملاء متاحة على مدار الساعة طوال أيام الأسبوع.';

  @override
  String get publicCallAction => 'اتصل بالكول سنتر';

  @override
  String get publicCopyNumber => 'انسخ الرقم';

  @override
  String get publicNumberCopied => 'تم نسخ رقم الهاتف';

  @override
  String get publicOfficialWebsite => 'الموقع الرسمي للبنك';

  @override
  String get publicLinkFailed =>
      'تعذّر فتح الرابط. حاول مرة أخرى أو استخدم تطبيق خرائط أو متصفحًا آخر.';

  @override
  String get brandingTitle => 'هوية التطبيق والمظهر';

  @override
  String get brandingGeneral => 'الهوية العامة';

  @override
  String get brandingName => 'اسم التطبيق داخل التطبيق';

  @override
  String get brandingShortName => 'اسم التطبيق المختصر';

  @override
  String get brandingTagline => 'الشعار النصي (اختياري)';

  @override
  String get brandingWelcome => 'رسالة الترحيب';

  @override
  String get brandingOriginal => 'اتركه فارغًا للاحتفاظ بالنص الأصلي المترجم';

  @override
  String get brandingLogo => 'شعار التطبيق';

  @override
  String get brandingDarkLogo => 'شعار الوضع الداكن';

  @override
  String get brandingSplash => 'صورة بداية التطبيق الداخلية';

  @override
  String get brandingUpload => 'رفع صورة';

  @override
  String get brandingRemove => 'استخدام الصورة الأصلية';

  @override
  String get brandingUploadHelp =>
      'PNG/JPEG • بحد أقصى ٢ ميجابايت • ١٦–٤٠٩٦ بكسل لكل جانب • حتى ٤ ميجابكسل. تُحفظ أبعاد الصورة.';

  @override
  String get brandingColors => 'ألوان المظهر';

  @override
  String get brandingCustomTheme => 'تخصيص ألوان المظهر';

  @override
  String get brandingLight => 'الوضع الفاتح';

  @override
  String get brandingDark => 'الوضع الداكن';

  @override
  String get brandingPrimary => 'اللون الأساسي';

  @override
  String get brandingSecondary => 'اللون الثانوي';

  @override
  String get brandingAccent => 'لون التمييز';

  @override
  String get brandingBackground => 'الخلفية';

  @override
  String get brandingSurface => 'سطح المحتوى';

  @override
  String get brandingTextPrimary => 'النص الأساسي';

  @override
  String get brandingTextSecondary => 'النص الثانوي';

  @override
  String get brandingError => 'لون الخطأ';

  @override
  String get brandingButtonBackground => 'خلفية الزر';

  @override
  String get brandingButtonText => 'نص الزر';

  @override
  String get brandingCard => 'خلفية البطاقات';

  @override
  String get brandingBorder => 'الحدود';

  @override
  String get brandingTypography => 'الخطوط';

  @override
  String get brandingPrimaryFont => 'عائلة الخط الأساسية';

  @override
  String get brandingArabicFont => 'عائلة الخط العربي';

  @override
  String get brandingEnglishFont => 'عائلة الخط الإنجليزي';

  @override
  String get brandingScale => 'مقياس حجم الخط';

  @override
  String get brandingHeadingWeight => 'سُمك خط العناوين';

  @override
  String get brandingBodyWeight => 'سُمك خط المحتوى';

  @override
  String get brandingMode => 'سياسة المظهر';

  @override
  String get brandingUserMode => 'الاحتفاظ باختيار العميل';

  @override
  String get brandingSystem => 'الإعداد الافتراضي للنظام';

  @override
  String get brandingPreview => 'معاينة مباشرة — تظهر هنا فقط';

  @override
  String get brandingPreviewCard => 'بطاقة حساب للمعاينة';

  @override
  String get brandingPreviewBody => 'خدماتك البنكية بين يديك بأمان';

  @override
  String get brandingSave => 'حفظ المسودة';

  @override
  String get brandingPublish => 'نشر التعديلات';

  @override
  String get brandingDefaults => 'استعادة الهوية الأصلية كمسودة';

  @override
  String get brandingHistory => 'سجل الإصدارات المنشورة';

  @override
  String get brandingRestore => 'استعادة كمسودة';

  @override
  String get brandingNoHistory => 'لم تُنشر إعدادات مخصصة بعد.';

  @override
  String get brandingDraftNotice =>
      'المسودات والمعاينة لا تؤثران على العملاء. انشر التعديلات صراحةً لتطبيقها.';

  @override
  String get brandingSaved => 'تم حفظ المسودة. الهوية المنشورة لم تتغير.';

  @override
  String get brandingPublished => 'تم نشر الهوية بنجاح.';

  @override
  String get brandingRestored =>
      'تمت استعادة الإعدادات كمسودة. راجعها ثم انشر لتطبيقها.';

  @override
  String get brandingUploaded =>
      'تم رفع الصورة. احفظ المسودة للاحتفاظ بالاختيار.';

  @override
  String get brandingConflict =>
      'عدّل مسؤول آخر هذه الإعدادات. تعديلاتك محفوظة على الشاشة؛ أعد التحميل لمراجعة أحدث نسخة.';

  @override
  String get brandingInvalid =>
      'راجع الألوان والنصوص والخطوط والمقياس. يلزم تباين ٤٫٥:١ للنصوص والأزرار. تعرض المعاينة آخر إعداد صالح.';

  @override
  String get brandingRequestFailed =>
      'تعذر إتمام العملية. تعديلاتك ما زالت محفوظة؛ حاول مجددًا.';

  @override
  String get brandingSaveFirst => 'احفظ مسودة صالحة قبل النشر.';

  @override
  String get brandingHistoryFailed =>
      'تعذر تحميل السجل. أعد التحميل للمحاولة مجددًا.';

  @override
  String get brandingPublishConfirm =>
      'هل تريد نشر المسودة المحفوظة لجميع العملاء؟';

  @override
  String get brandingReloadConfirm =>
      'هل تريد إعادة التحميل واستبدال التعديلات غير المحفوظة؟';

  @override
  String get brandingReplaceConfirm =>
      'هل تريد استبدال المسودة الحالية؟ لن يُنشر أي تغيير.';

  @override
  String get brandingUnsaved => 'لديك تعديلات غير محفوظة.';

  @override
  String get brandingNative => 'هوية أيقونة النظام';

  @override
  String get brandingReleaseRequired => 'يتطلب إصدارًا جديدًا للتطبيق';

  @override
  String get brandingNativeHelp =>
      'أسماء وأيقونات Android/iOS وشاشات الإقلاع الأصلية موارد ضمن البناء. هذه الإعدادات تغيّر الهوية داخل التطبيق فقط. الأيقونات البديلة المحددة مسبقًا تتطلب إصدارًا أصليًا مختبرًا بشكل منفصل.';

  @override
  String get brandingHex => 'لون HEX ‏(#RRGGBB)';

  @override
  String get brandingHue => 'درجة اللون';

  @override
  String get brandingSaturation => 'التشبع';

  @override
  String get brandingBrightness => 'السطوع';

  @override
  String get brandingVersion => 'الإصدار المنشور';

  @override
  String get brandingMoreHistory => 'تحميل الإصدارات الأقدم';

  @override
  String get brandingSystemFont => 'خط النظام الأصلي';
}
