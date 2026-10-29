// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Your banks';

  @override
  String get bankName => 'Your bank';

  @override
  String get bankNameShort => 'Your banks';

  @override
  String get appTagline => 'Banking, thoughtfully designed';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get demoDataNotice =>
      'Development simulation. Bank names and themes do not indicate a connection to any real bank or payment network.';

  @override
  String get simulated => 'Simulated';

  @override
  String get simulatedShort => 'Demo';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get submit => 'Submit';

  @override
  String get optional => 'Optional';

  @override
  String get loading => 'Loading…';

  @override
  String get loadingMore => 'Loading more…';

  @override
  String get noData => 'Nothing to show yet';

  @override
  String get refresh => 'Refresh';

  @override
  String get viewAll => 'View all';

  @override
  String get details => 'Details';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get amount => 'Amount';

  @override
  String amountWithCurrency(String amount, String currency) {
    return '$amount $currency';
  }

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get reference => 'Reference';

  @override
  String get home => 'Home';

  @override
  String get accounts => 'Accounts';

  @override
  String get cards => 'Cards';

  @override
  String get transfers => 'Transfers';

  @override
  String get payments => 'Payments';

  @override
  String get more => 'More';

  @override
  String get requests => 'Requests';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get products => 'Products';

  @override
  String get support => 'Support';

  @override
  String get profile => 'Profile';

  @override
  String get admin => 'Administration';

  @override
  String get repayments => 'Repayments';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in with your username and password.';

  @override
  String get cardNumber => 'Card number';

  @override
  String get cardNumberHint => '4508 1234 5678 9012';

  @override
  String get loginIdentifier => 'Username';

  @override
  String get loginIdentifierHint => 'Enter your username';

  @override
  String get invalidLoginIdentifier =>
      'Enter a valid username, card or account number.';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get temporaryPassword => 'Account number / temporary password';

  @override
  String get temporaryPasswordHint =>
      'Enter your account number on first sign-in';

  @override
  String get rememberDevice => 'Remember this device';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get securityNotice =>
      'Never share your password or one-time codes. Your bank will never ask for them.';

  @override
  String get invalidCardNumber =>
      'Enter a valid card number (at least 8 digits).';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get loginFailed =>
      'We could not sign you in. Check your details and try again.';

  @override
  String get firstLoginBadge => 'First-time setup';

  @override
  String get createSecurePassword => 'Create a secure password';

  @override
  String setupSubtitle(String name) {
    return 'Welcome $name. For your security, please replace your temporary credential with a new password.';
  }

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm new password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get passwordStrength => 'Password strength';

  @override
  String get strengthWeak => 'Weak';

  @override
  String get strengthFair => 'Fair';

  @override
  String get strengthGood => 'Good';

  @override
  String get strengthStrong => 'Strong';

  @override
  String get reqMinLength => 'At least 8 characters';

  @override
  String get reqUppercase => 'One uppercase letter (A–Z)';

  @override
  String get reqLowercase => 'One lowercase letter (a–z)';

  @override
  String get reqDigit => 'One number (0–9)';

  @override
  String get reqSpecial => 'One special character (! @ # \$ % & *)';

  @override
  String get reqNoRepeat => 'No character repeated 3 times in a row';

  @override
  String get passwordMismatch => 'The passwords do not match.';

  @override
  String get passwordPolicyError =>
      'Your password does not meet all the security requirements.';

  @override
  String get continueToHome => 'Save password and continue';

  @override
  String get passwordUpdated => 'Your password has been updated.';

  @override
  String get setupExpired =>
      'Your setup session has expired. Please sign in again.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingUser(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get totalBalance => 'Total balance';

  @override
  String get availableBalance => 'Available balance';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get blockedBalance => 'Blocked balance';

  @override
  String get hideBalance => 'Hide balance';

  @override
  String get showBalance => 'Show balance';

  @override
  String get activeAccounts => 'Active accounts';

  @override
  String activeAccountsCount(int count) {
    return '$count active accounts';
  }

  @override
  String get quickActions => 'Quick actions';

  @override
  String get myAccounts => 'My accounts';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get viewAllTransactions => 'View all transactions';

  @override
  String get noRecentTransactions => 'No recent transactions';

  @override
  String get featured => 'Featured';

  @override
  String get accountTypeCurrent => 'Current account';

  @override
  String get accountTypeInvestment => 'Investment account';

  @override
  String get accountTypeSavings => 'Savings account';

  @override
  String get accountTypeOther => 'Account';

  @override
  String accountEndingIn(String last4) {
    return 'Account $last4';
  }

  @override
  String get accountNumber => 'Account number';

  @override
  String get iban => 'IBAN';

  @override
  String get accountDetails => 'Account details';

  @override
  String get totalAcrossAccounts => 'Total across eligible accounts';

  @override
  String get linkedCards => 'Linked cards';

  @override
  String get accountServices => 'Account services';

  @override
  String get openAccount => 'Open an account';

  @override
  String get closeAccount => 'Close account';

  @override
  String get selectProduct => 'Select a product';

  @override
  String get minimumBalance => 'Minimum balance';

  @override
  String get closeAccountWarning =>
      'Closing an account requires the balance to be settled and approval from the bank.';

  @override
  String requestSubmittedMessage(String reference) {
    return 'Request $reference has been submitted.';
  }

  @override
  String get cardsTitle => 'My cards';

  @override
  String get cardHolder => 'Cardholder';

  @override
  String cardExpires(String month, String year) {
    return 'Expires $month/$year';
  }

  @override
  String cardEndingIn(String last4) {
    return 'Card ending $last4';
  }

  @override
  String get freezeCard => 'Freeze card';

  @override
  String get unfreezeCard => 'Unfreeze card';

  @override
  String get reportLostCard => 'Report lost card';

  @override
  String get reportStolenCard => 'Report stolen card';

  @override
  String get blockCardPermanently => 'Block card permanently';

  @override
  String get requestReplacement => 'Request replacement';

  @override
  String get requestRenewal => 'Request renewal';

  @override
  String get resetPin => 'Reset PIN';

  @override
  String get cardLimits => 'Card limits';

  @override
  String get dailyPurchaseLimit => 'Daily purchase limit';

  @override
  String get dailyAtmLimit => 'Daily ATM limit';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get onlinePayments => 'Online payments';

  @override
  String get internationalPayments => 'International payments';

  @override
  String get contactlessPayments => 'Contactless payments';

  @override
  String get cardSettings => 'Card settings';

  @override
  String get creditDetails => 'Credit details';

  @override
  String get outstandingBalance => 'Outstanding balance';

  @override
  String get statementBalance => 'Statement balance';

  @override
  String get minimumPayment => 'Minimum payment';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String get availableCredit => 'Available credit';

  @override
  String get paymentDueDate => 'Payment due date';

  @override
  String get supplementaryCard => 'Supplementary card';

  @override
  String get requestSupplementaryCard => 'Request supplementary card';

  @override
  String get cardStatusActive => 'Active';

  @override
  String get cardStatusFrozen => 'Frozen';

  @override
  String get cardStatusLost => 'Reported lost';

  @override
  String get cardStatusStolen => 'Reported stolen';

  @override
  String get cardStatusBlocked => 'Blocked';

  @override
  String get cardStatusCancelled => 'Cancelled';

  @override
  String get cardStatusPendingActivation => 'Pending activation';

  @override
  String get cardStatusExpired => 'Expired';

  @override
  String get confirmFreezeTitle => 'Freeze this card?';

  @override
  String get confirmFreezeBody =>
      'Card payments will be blocked until you unfreeze it. You can unfreeze it at any time.';

  @override
  String get confirmUnfreezeTitle => 'Unfreeze this card?';

  @override
  String get confirmUnfreezeBody => 'Card payments will be enabled again.';

  @override
  String get confirmBlockTitle => 'Permanently block this card?';

  @override
  String get confirmBlockBody =>
      'This cannot be undone from the app. You will need to request a replacement card.';

  @override
  String get confirmLostTitle => 'Report this card as lost?';

  @override
  String get confirmLostBody =>
      'The card will be blocked immediately for your protection.';

  @override
  String get confirmStolenTitle => 'Report this card as stolen?';

  @override
  String get confirmStolenBody =>
      'The card will be blocked immediately. Contact the bank if you need urgent assistance.';

  @override
  String get cardFrozenSuccess => 'Card frozen.';

  @override
  String get cardUnfrozenSuccess => 'Card unfrozen.';

  @override
  String get cardBlockedSuccess => 'Card blocked.';

  @override
  String get cardActionFailed =>
      'We could not complete this action. Please try again.';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchTransactions =>
      'Search by description, merchant or reference';

  @override
  String get filters => 'Filters';

  @override
  String get dateFrom => 'From date';

  @override
  String get dateTo => 'To date';

  @override
  String get transactionType => 'Transaction type';

  @override
  String get direction => 'Direction';

  @override
  String get debit => 'Debit';

  @override
  String get credit => 'Credit';

  @override
  String get minAmount => 'Minimum amount';

  @override
  String get maxAmount => 'Maximum amount';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get transactionDetails => 'Transaction details';

  @override
  String get fees => 'Fees';

  @override
  String get source => 'Source';

  @override
  String get destination => 'Destination';

  @override
  String get receiptAvailable => 'Receipt available';

  @override
  String get noTransactionsFound => 'No transactions match your filters';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionTypeDeposit => 'Deposit';

  @override
  String get transactionTypeWithdrawal => 'Withdrawal';

  @override
  String get transactionTypePurchase => 'Purchase';

  @override
  String get transactionTypeBillPayment => 'Bill payment';

  @override
  String get transactionTypeCardRepayment => 'Card repayment';

  @override
  String get transactionTypeFee => 'Fee';

  @override
  String get transactionTypeAdjustment => 'Adjustment';

  @override
  String get transactionTypeSalary => 'Salary';

  @override
  String get transactionStatusPosted => 'Completed';

  @override
  String get transactionStatusPending => 'Pending';

  @override
  String get transactionStatusFailed => 'Failed';

  @override
  String get transactionStatusReversed => 'Reversed';

  @override
  String get transfersTitle => 'Transfers';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get savedBeneficiary => 'Saved beneficiary';

  @override
  String get newBeneficiary => 'New beneficiary';

  @override
  String get purpose => 'Purpose';

  @override
  String get note => 'Note';

  @override
  String get reviewTransfer => 'Review transfer';

  @override
  String get confirmTransfer => 'Confirm transfer';

  @override
  String get transferReviewNote =>
      'Transfers in this demo are simulated and do not move real money.';

  @override
  String get transferSuccess => 'Transfer completed (simulated)';

  @override
  String transferSuccessMessage(String reference) {
    return 'Reference $reference';
  }

  @override
  String get transferFailed => 'The transfer could not be completed.';

  @override
  String get beneficiaries => 'Beneficiaries';

  @override
  String get addBeneficiary => 'Add beneficiary';

  @override
  String get bankNameLabel => 'Bank name';

  @override
  String get nickname => 'Nickname';

  @override
  String get deleteBeneficiary => 'Remove beneficiary';

  @override
  String get insufficientFunds => 'The available balance is not sufficient.';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get payBill => 'Pay a bill';

  @override
  String get biller => 'Biller';

  @override
  String get billerCategory => 'Biller category';

  @override
  String get payNow => 'Pay now';

  @override
  String get paymentSuccess => 'Payment completed (simulated)';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get branchServices => 'Branch services';

  @override
  String get cashDepositRequest => 'Cash deposit request';

  @override
  String get cashWithdrawalRequest => 'Cash withdrawal request';

  @override
  String get branchServiceNote =>
      'Branch services create a request for the bank to action. No money moves automatically.';

  @override
  String get selectBiller => 'Select a biller';

  @override
  String get repaymentsTitle => 'Credit card repayments';

  @override
  String get repayCreditCard => 'Repay credit card';

  @override
  String get selectCard => 'Select card';

  @override
  String get selectFundingAccount => 'Select funding account';

  @override
  String get repaymentOption => 'Repayment option';

  @override
  String get optionFullBalance => 'Full outstanding balance';

  @override
  String get optionStatementBalance => 'Current statement balance';

  @override
  String get optionMinimumPayment => 'Minimum payment';

  @override
  String get optionCustomAmount => 'Custom amount';

  @override
  String get charges => 'Charges';

  @override
  String get totalPayable => 'Total payable';

  @override
  String get confirmRepayment => 'Confirm repayment';

  @override
  String get repaymentSuccess => 'Repayment completed (simulated)';

  @override
  String repaymentSuccessMessage(String reference) {
    return 'Repayment reference $reference';
  }

  @override
  String get repaymentNote =>
      'Repayments are processed by a simulated payment service. No real bank transfer occurs.';

  @override
  String get repaymentNotEligible =>
      'This repayment is not available with the selected account.';

  @override
  String get repaymentHistory => 'Repayment history';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get newRequest => 'New request';

  @override
  String get requestDetails => 'Request details';

  @override
  String get requestType => 'Request type';

  @override
  String get submittedOn => 'Submitted on';

  @override
  String get statusHistory => 'Status history';

  @override
  String get decisionReason => 'Decision reason';

  @override
  String get provideInformation => 'Provide information';

  @override
  String get uploadDocument => 'Upload document';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get awaitingYourInformation =>
      'The bank needs more information from you.';

  @override
  String get requestReferenceCopied => 'Reference copied';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusUnderReview => 'Under review';

  @override
  String get statusPendingCustomerInfo => 'Action required';

  @override
  String get statusPendingApproval => 'Pending approval';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get requestTypeAccountOpen => 'Open account';

  @override
  String get requestTypeAccountClose => 'Close account';

  @override
  String get requestTypeCardReplacement => 'Replace card';

  @override
  String get requestTypeCardRenewal => 'Renew card';

  @override
  String get requestTypeCardCancellation => 'Cancel card';

  @override
  String get requestTypeLimitIncrease => 'Increase card limit';

  @override
  String get requestTypeLimitDecrease => 'Decrease card limit';

  @override
  String get requestTypePinReset => 'Reset card PIN';

  @override
  String get requestTypeSupplementary => 'Supplementary card';

  @override
  String get requestTypeCreditCard => 'Credit card application';

  @override
  String get requestTypeInvestment => 'Investment product';

  @override
  String get requestTypeInfoUpdate => 'Update my information';

  @override
  String get requestTypeOther => 'Other service';

  @override
  String get noRequests => 'You have no requests yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get unreadNotifications => 'Unread';

  @override
  String get noNotifications => 'You have no notifications';

  @override
  String get announcementDetails => 'Announcement';

  @override
  String get maintenanceNotice => 'Service notice';

  @override
  String get productsTitle => 'Discover';

  @override
  String get offersTitle => 'Offers';

  @override
  String get productDetails => 'Product details';

  @override
  String get eligibility => 'Eligibility';

  @override
  String get pricingInformation => 'Pricing information';

  @override
  String get applyNow => 'Apply now';

  @override
  String get readMore => 'Read more';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get emailLabel => 'Email';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get addressLabel => 'Address';

  @override
  String get customerNumber => 'Customer number';

  @override
  String get identityVerified => 'Identity verified';

  @override
  String get securitySettings => 'Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get activeSessions => 'Active sessions';

  @override
  String get thisDevice => 'This device';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get theme => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get notificationPreferences => 'Notification preferences';

  @override
  String get transactionNotifications => 'Transaction alerts';

  @override
  String get marketingNotifications => 'Offers and marketing';

  @override
  String get allNotifications => 'All notifications';

  @override
  String get biometricLogin => 'Biometric sign-in';

  @override
  String get biometricUnavailable =>
      'Biometrics are unavailable or no biometric credential is enrolled. Use your password and enroll biometrics in device settings.';

  @override
  String get about => 'About';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get helpCenter => 'Help center';

  @override
  String get faq => 'Frequently asked questions';

  @override
  String get faqQ1 => 'How do I reset my password?';

  @override
  String get faqA1 =>
      'Choose Forgot password on the sign-in screen. A bank representative will provide a one-time reset code.';

  @override
  String get faqQ2 => 'Why is my card frozen?';

  @override
  String get faqA2 =>
      'A freeze is a temporary block you control. Open the card and select Unfreeze card to enable payments again.';

  @override
  String get faqQ3 => 'Are transfers real?';

  @override
  String get faqA3 =>
      'No. This demo uses a simulated payment service and never moves real money.';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get profileUpdated => 'Your profile has been updated.';

  @override
  String get preferencesUpdated => 'Preferences updated.';

  @override
  String get supportTitle => 'Support';

  @override
  String get newTicket => 'New conversation';

  @override
  String get subject => 'Subject';

  @override
  String get message => 'Message';

  @override
  String get sendMessage => 'Send message';

  @override
  String get noTickets => 'No conversations yet';

  @override
  String get contactChannels => 'Contact channels';

  @override
  String get callUs => 'Call the bank';

  @override
  String get branchLocator => 'Find a branch';

  @override
  String get adminPortal => 'Administration portal';

  @override
  String get dashboard => 'Overview';

  @override
  String get customers => 'Customers';

  @override
  String get requestQueue => 'Request queue';

  @override
  String get announcementsAdmin => 'Announcements';

  @override
  String get productsAndOffers => 'Products & offers';

  @override
  String get auditLogs => 'Audit log';

  @override
  String get demoStatistics => 'Demo statistics';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get publishedAnnouncements => 'Published announcements';

  @override
  String get scheduledMaintenance => 'Scheduled maintenance';

  @override
  String get recentActions => 'Recent administrative actions';

  @override
  String get reviewQueue => 'Review queue';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get requestInformation => 'Request information';

  @override
  String get assignReviewer => 'Assign reviewer';

  @override
  String get internalNote => 'Internal note';

  @override
  String get customerExplanation => 'Message to customer';

  @override
  String get confirmApprove => 'Approve this request?';

  @override
  String get confirmReject => 'Reject this request?';

  @override
  String get rejectionReasonRequired =>
      'Enter a reason for the rejection (at least 5 characters).';

  @override
  String get createAnnouncement => 'Create announcement';

  @override
  String get publish => 'Publish';

  @override
  String get archive => 'Archive';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get preview => 'Preview';

  @override
  String get audience => 'Audience';

  @override
  String get audienceAll => 'All customers';

  @override
  String get priority => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get schedule => 'Schedule';

  @override
  String get titleEn => 'Title (English)';

  @override
  String get titleAr => 'Title (Arabic)';

  @override
  String get bodyEn => 'Content (English)';

  @override
  String get bodyAr => 'Content (Arabic)';

  @override
  String get createdOn => 'Created';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get noAccess => 'You do not have permission to view this page.';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to perform this action.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorValidation => 'Please check the highlighted fields.';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get startupRestoreFailed =>
      'We couldn\'t restore your saved session. Check your connection and try again.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get invalidAmount => 'Enter a valid amount.';

  @override
  String get amountPositive => 'The amount must be greater than zero.';

  @override
  String get invalidDate => 'Enter a valid date.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get readOnlyAccess => 'Read-only access';

  @override
  String get registerTitle => 'Register for digital banking';

  @override
  String get registrationExplanation =>
      'Enter your card number for the selected bank. Verify using your registered contact, then create your unique username and password.';

  @override
  String get registrationVerified =>
      'Contact verified. Create your secure password to complete enrollment.';

  @override
  String get registeredContactMasked =>
      'Verification uses your registered contact (***).';

  @override
  String get identifierFormatError =>
      'Enter 6–24 digits; spaces, dashes and dots are allowed.';

  @override
  String get otpExplanation =>
      'If your details are eligible, use the six-digit code provided to your registered contact. Never share this code.';

  @override
  String get otpDevelopmentNotice =>
      'For your test: enter the code shown below. No message was sent; real SMS/email delivery is not configured. A new request replaces the previous code.';

  @override
  String get developmentCode => 'Local development code';

  @override
  String get otpCode => 'Verification code';

  @override
  String get otpFormatError => 'Enter the six-digit code.';

  @override
  String get verifyCode => 'Verify code';

  @override
  String get resendCode => 'Request another code';

  @override
  String get otpIncorrect => 'The verification code is incorrect.';

  @override
  String get otpExpired => 'This code expired. Request another code.';

  @override
  String get otpUsed =>
      'This code was used or replaced. Start registration again.';

  @override
  String get otpAttemptsExceeded =>
      'Too many incorrect codes. Start registration again later.';

  @override
  String get authorizeTitle => 'Authorize operation';

  @override
  String get authorizationExplanation =>
      'Re-enter your current password to generate a short-lived token for this operation. Copy it, continue, and enter it on the confirmation page.';

  @override
  String get authorizationSuccess => 'Authorization token issued';

  @override
  String get authorizationValidity => 'Validity in seconds';

  @override
  String get authorizationToken => 'Authorization token';

  @override
  String get copyToken => 'Copy Token';

  @override
  String get tokenCopied => 'Token copied (clears after 60 seconds)';

  @override
  String get authorizationExpired =>
      'The authorization token expired. Authorize again.';

  @override
  String get authorizationUsed =>
      'This authorization token has already been used.';

  @override
  String get authorizationInvalid =>
      'Enter a valid token issued for this operation and these details.';

  @override
  String get currentPasswordIncorrect => 'The current password is incorrect.';

  @override
  String get passwordsMatchLabel => 'Passwords match';

  @override
  String get securityOperationError =>
      'The operation could not be completed. Check the details and try again.';

  @override
  String get transferBalanceError => 'The available balance is insufficient.';

  @override
  String get internalTransferOnly =>
      'Only verified internal account destinations are supported. Existing external beneficiaries are preserved but cannot receive transfers here.';

  @override
  String get totalDebit => 'Total debit';

  @override
  String get beneficiaryName => 'Beneficiary name';

  @override
  String get ownAccounts => 'Between my accounts';

  @override
  String get transferReceipt => 'Transfer receipt';

  @override
  String get editTransfer => 'Edit transfer details';

  @override
  String get transferExplicitConfirmation =>
      'I confirm the reviewed beneficiary, amount and total debit.';

  @override
  String get updatePersonalInfo => 'Update personal information';

  @override
  String get profileReviewExplanation =>
      'Submit email, phone or address changes electronically for bank review. Your verified details remain unchanged until approval. Identity and legal name changes require bank assistance.';

  @override
  String get profilePendingReview =>
      'Submitted for bank review. Your verified information has not changed.';

  @override
  String get profileRequestExists =>
      'You already have a pending information update request.';

  @override
  String get biometricReason => 'Verify your identity to enter banking';

  @override
  String get biometricEnabledMessage =>
      'Biometric re-entry enabled on this device. A valid backend session is still required.';

  @override
  String get biometricDisabledMessage =>
      'Biometric re-entry disabled on this device.';

  @override
  String get biometricUnlock => 'Unlock with biometrics';

  @override
  String get biometricLocked =>
      'Your session is locked. Unlock or sign out to use a password.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHint =>
      '3–30 English letters and digits only; start with a letter.';

  @override
  String get usernameInvalid => 'Choose a valid username.';

  @override
  String get usernameAvailable => 'Username is available';

  @override
  String get usernameTaken =>
      'Username is unavailable. Choose a suggestion or type another.';

  @override
  String get investmentsTitle => 'Certificates & investment funds';

  @override
  String get investmentSimulationNotice =>
      'Development simulation: subscriptions debit your account immediately. Fund unit prices are simulated; no real investment or guaranteed return.';

  @override
  String get investmentProduct => 'Certificate or fund';

  @override
  String get investmentMinimum => 'Minimum subscription';

  @override
  String get investmentStep => 'Amount increment';

  @override
  String get investmentUnits => 'Units';

  @override
  String get investmentMaximumPenalty => 'Maximum early redemption deduction';

  @override
  String get investmentPenaltyFormula =>
      'Certificate deduction = principal × maximum percentage × remaining days ÷ total days; zero at maturity. Funds have no term penalty in this simulation.';

  @override
  String get investmentAmountError =>
      'Use the minimum subscription and the specified amount increments.';

  @override
  String get investmentSubscribe => 'Subscribe';

  @override
  String get myInvestments => 'My investments';

  @override
  String get noInvestments => 'You have no investment holdings yet.';

  @override
  String get investmentPrincipal => 'Principal';

  @override
  String get investmentActive => 'Active';

  @override
  String get investmentRedeemed => 'Redeemed';

  @override
  String get investmentMaturity => 'Maturity date';

  @override
  String get investmentRedeem => 'Redeem / break';

  @override
  String get investmentReview => 'Review investment operation';

  @override
  String get investmentPenalty => 'Early redemption deduction';

  @override
  String get investmentNetCredit => 'Net amount returned to your account';

  @override
  String get investmentConfirm =>
      'I confirm the reviewed investment operation and its deduction policy.';

  @override
  String get investmentCompleted => 'Investment operation completed';

  @override
  String get investmentPending => 'Operation awaiting completion';

  @override
  String get investmentUnavailable =>
      'This investment is unavailable or has already been redeemed. Refresh your holdings.';

  @override
  String get exchangeRatesTitle => 'Currency exchange rates';

  @override
  String get fxIndicativeNotice =>
      'Indicative global rates in EGP. Buy and sell values use a simulated spread; they are not bank dealing prices and cannot execute an exchange.';

  @override
  String get fxProviderTime => 'Rate observation time';

  @override
  String get fxFetchedTime => 'Last server fetch';

  @override
  String get fxDelaySeconds => 'Provider delay (seconds)';

  @override
  String get fxSpread => 'Simulated total spread';

  @override
  String get fxMarketOpen => 'Market session: open';

  @override
  String get fxMarketClosed => 'Market session closed / reference rates';

  @override
  String get fxStale =>
      'Last known rates: data is old or the provider is unavailable.';

  @override
  String get fxRefreshNotice =>
      'Refreshes every 60 seconds while this page is active. Free feed can be delayed by 15 minutes; daily reference and closed-market rates may be older.';

  @override
  String get fxUnit => 'EGP for 1 unit of foreign currency';

  @override
  String get fxBuy => 'Buy (simulated)';

  @override
  String get fxSell => 'Sell (simulated)';

  @override
  String get fxMid => 'Reference mid-rate';

  @override
  String get fxSource => 'Observation source';

  @override
  String get fxAttribution => 'Rates provided by exchangerate.dev ↗';

  @override
  String get fxUnavailable =>
      'Currency rates are temporarily unavailable. Please retry.';

  @override
  String get currencyUsd => 'USD · US dollar';

  @override
  String get currencySar => 'SAR · Saudi riyal';

  @override
  String get currencyEur => 'EUR · Euro';

  @override
  String get currencyAed => 'AED · UAE dirham';

  @override
  String get currencyGbp => 'GBP · Pound sterling';

  @override
  String get currencyKwd => 'KWD · Kuwaiti dinar';

  @override
  String get currencyQar => 'QAR · Qatari riyal';

  @override
  String get currencyChf => 'CHF · Swiss franc';

  @override
  String get certificatesTitle => 'Certificates';

  @override
  String get investmentFundsTitle => 'Investment funds';

  @override
  String get myCertificates => 'My certificates';

  @override
  String get myFunds => 'My fund holdings';

  @override
  String get fxSearch => 'Search currency name or code';

  @override
  String get fxAll => 'All';

  @override
  String get fxFavorites => 'Favorites';

  @override
  String get fxArabCurrencies => 'Arab currencies';

  @override
  String get fxForeignCurrencies => 'Other currencies';

  @override
  String get fxFavoriteAdd => 'Add to favorites';

  @override
  String get fxFavoriteRemove => 'Remove from favorites';

  @override
  String get fxEmpty => 'No matching currencies';

  @override
  String get fxEgpBase => 'Egyptian pound · EGP';

  @override
  String get fxDetails => 'Rate details and source';

  @override
  String get fxDayChangeUnavailable => 'Daily change unavailable';

  @override
  String get otpDevelopmentUnavailable =>
      'No local code was issued for this number. For this demo, use the card of a customer who has not enrolled yet. Already enrolled customers should sign in.';

  @override
  String get admSubtitle => 'Review customer requests and publish bank notices';

  @override
  String get admAll => 'All requests';

  @override
  String get admSearch => 'Search by request reference';

  @override
  String get admEmptyRequests => 'No requests match this filter';

  @override
  String get admLoadMore => 'Load more';

  @override
  String get admDetails => 'Request details';

  @override
  String get admCustomer => 'Customer';

  @override
  String get admHistory => 'Request history';

  @override
  String get admDecisionSaved => 'Decision recorded and customer notified';

  @override
  String get admEmptyNotices => 'No announcements yet';

  @override
  String get admPublicEmpty => 'No urgent notices at the moment';

  @override
  String get admPublicTitle => 'Bank notices';

  @override
  String get admPublicSubtitle => 'Important updates before you sign in';

  @override
  String get admLocation => 'Display location';

  @override
  String get admHome => 'Customer home';

  @override
  String get admBeforeLogin => 'Before sign-in';

  @override
  String get admBoth => 'Home and before sign-in';

  @override
  String get admPublicPolicy =>
      'Before-login notices are public to everyone or the selected bank, and contain no personal data.';

  @override
  String get admTitleEn => 'English title';

  @override
  String get admTitleAr => 'Arabic title';

  @override
  String get admBodyEn => 'English message';

  @override
  String get admBodyAr => 'Arabic message';

  @override
  String get admRequired => 'Enter at least 3 characters';

  @override
  String get admPriority => 'Priority';

  @override
  String get admDraft => 'Draft';

  @override
  String get admPublished => 'Published';

  @override
  String get admArchived => 'Archived';

  @override
  String get admSaved => 'Announcement saved';

  @override
  String get admEdit => 'Edit announcement';

  @override
  String get admPublishConfirm =>
      'Publish this announcement to the selected location?';

  @override
  String get admArchiveConfirm =>
      'Archive this announcement and remove it from customer screens?';

  @override
  String get admDataEmail => 'Email';

  @override
  String get admDataPhone => 'Phone';

  @override
  String get admDataAddress => 'Address';

  @override
  String get admDataProduct => 'Banking product';

  @override
  String get admDataAccount => 'Account';

  @override
  String get admDataCurrency => 'Currency';

  @override
  String get admDataCard => 'Card';

  @override
  String get admDataAmount => 'Requested amount';

  @override
  String get admDataReason => 'Reason';

  @override
  String get cardApplyTitle => 'Request a card';

  @override
  String get cardApplySubtitle =>
      'Choose your card and linked account. Bank approval is required.';

  @override
  String get cardPreview => 'DESIGN PREVIEW';

  @override
  String get cardSelect => 'Choose this card';

  @override
  String get cardSelected => 'Selected card';

  @override
  String get cardChooseAccount => 'Linked account';

  @override
  String get cardInvestmentOnly => 'Investment account in EGP';

  @override
  String get cardDomesticAccount => 'Active EGP account';

  @override
  String get cardForeignOnly => 'USD, EUR or SAR accounts only';

  @override
  String get cardYouthOnly =>
      'For customers under 21 with a verified date of birth';

  @override
  String get cardAgeUnverified =>
      'A verified date of birth is required. Contact the bank to verify it.';

  @override
  String get cardYouthAge =>
      'Youth cards are available only to customers under 21.';

  @override
  String get cardInvestmentRequired =>
      'You need an active EGP investment account for this card.';

  @override
  String get cardForeignRequired =>
      'You need an active USD, EUR or SAR account for this card.';

  @override
  String get cardAccountRequired => 'You need an eligible active EGP account.';

  @override
  String get cardUnavailable =>
      'The card or customer is no longer eligible. Refresh and review the available options.';

  @override
  String get cardOpenAccount => 'Open Accounts';

  @override
  String get cardReviewTitle => 'Review card request';

  @override
  String get cardApprovalNotice =>
      'Submitting creates a request only. The card is issued after an administrator approves it. Delivery and activation remain pending.';

  @override
  String get cardAnnualFee => 'Configured annual fee';

  @override
  String get cardSubmitRequest => 'Confirm and submit request';

  @override
  String get cardRequestReceived => 'Request received — awaiting bank review';

  @override
  String get cardMyRequests => 'My card requests';

  @override
  String get cardRequestExists =>
      'You already have a pending card request. Follow its status below.';

  @override
  String get cardNoRequests => 'No card requests yet';

  @override
  String get cardProductLabel => 'Card category';

  @override
  String get cardPendingActivation => 'Awaiting delivery and activation';

  @override
  String get cardBackCards => 'Back to my cards';

  @override
  String get transferTypeLabel => 'Transfer type';

  @override
  String get transferOwnType => 'Between my accounts';

  @override
  String get transferInternalType => 'Within the same bank';

  @override
  String get transferDomesticType => 'Other banks in Egypt';

  @override
  String get transferInternationalType => 'International transfer';

  @override
  String get transferWalletType => 'Mobile wallet';

  @override
  String get transferInstapayType => 'InstaPay';

  @override
  String get transferSimulationOnly =>
      'Local simulation: your demo balance is debited. No payment is sent to a bank, wallet or InstaPay network.';

  @override
  String get transferSameCurrency =>
      'Uses the source account currency. Currency conversion is not available.';

  @override
  String get transferBankName => 'Receiving bank name';

  @override
  String get transferAccountOrIban => 'Account number or IBAN';

  @override
  String get transferCountry => 'Country code (for example US or SA)';

  @override
  String get transferSwift => 'SWIFT / BIC';

  @override
  String get transferWalletNumber => 'Egyptian wallet mobile number';

  @override
  String get transferIpa => 'IPA address or Egyptian mobile';

  @override
  String get transferIpaHint => 'Example: fictionaluser@instapay';

  @override
  String get transferDestinationInvalid =>
      'Check the recipient, account/mobile/IPA format, bank and currency.';

  @override
  String get transferProviderMissing =>
      'This route has no configured delivery provider. No money has been debited.';

  @override
  String get transferUnavailableType => 'Not configured';

  @override
  String get transferSimulationSuccess => 'Transfer simulation completed';

  @override
  String get transferProviderReference => 'Simulation reference';

  @override
  String get transferDeliveryFailure =>
      'Delivery simulation failed. Refresh your balance and retry safely.';

  @override
  String get transferNoEligibleSource =>
      'No eligible account for this type. Domestic, wallet and InstaPay transfers require EGP.';

  @override
  String get ownFxAvailable =>
      'Currency conversion is available only between your own accounts.';

  @override
  String get ownFxRate => 'Exchange rate';

  @override
  String get ownFxReceived => 'Amount received';

  @override
  String get ownFxAsOf => 'Market data as of';

  @override
  String get ownFxExpires => 'Quote valid until';

  @override
  String get ownFxSimulation =>
      'Simulated exchange using indicative buy/sell prices and their spread, which may be delayed. This is not a real bank dealing quote.';

  @override
  String get ownFxExpired =>
      'The exchange quote expired or was already used. Edit the transfer, review a new quote and authorize again.';

  @override
  String get ownFxInvalid =>
      'Obtain a new quote for the same customer, accounts and amount before authorizing.';

  @override
  String get ownFxAmountInvalid =>
      'The amount received is too small or exceeds the supported balance range.';

  @override
  String get publicWelcomeTitle => 'Welcome to your bank';

  @override
  String get publicWelcomeSubtitle =>
      'Your banking and support services, in one place.';

  @override
  String get publicBranches => 'Branches';

  @override
  String get publicAtms => 'ATMs';

  @override
  String get publicCallCenter => 'Call center';

  @override
  String get publicSignInHint => 'Access your accounts';

  @override
  String get publicBranchesHint => 'Addresses and maps';

  @override
  String get publicAtmsHint => 'Find an ATM';

  @override
  String get publicCallCenterHint => 'We are here to help';

  @override
  String get publicBranchSearch => 'Search branch, area or address';

  @override
  String get publicGovernorate => 'Governorate';

  @override
  String get publicAllGovernorates => 'All governorates';

  @override
  String get publicResultCount => 'Results';

  @override
  String get publicDirectoryEmpty =>
      'No branches match your search. Try another area or governorate.';

  @override
  String get publicDirectoryFailed =>
      'Could not load the branch directory. Please retry.';

  @override
  String get publicOpenMap => 'Open location';

  @override
  String get publicMapSearchNote =>
      'Open the branch pin or search its name and address on the map.';

  @override
  String get publicAtmSubtitle => 'Find a cash machine';

  @override
  String get publicAtmNote =>
      'Search for Faisal Bank ATMs on the map, or use the bank’s official branch and ATM locator.';

  @override
  String get publicAtmArea => 'City or area (optional)';

  @override
  String get publicSearchAtm => 'Search ATMs on map';

  @override
  String get publicOfficialLocator => 'Official bank locator';

  @override
  String get publicCallEgypt => 'Hotline inside Egypt';

  @override
  String get publicHotlineAvailability =>
      'Customer service is available 24 hours a day, 7 days a week.';

  @override
  String get publicCallAction => 'Open dialer';

  @override
  String get publicCopyNumber => 'Copy number';

  @override
  String get publicNumberCopied => 'Phone number copied';

  @override
  String get publicOfficialWebsite => 'Official bank website';

  @override
  String get publicLinkFailed =>
      'Could not open the link. Try again or use another maps app or browser.';

  @override
  String get brandingTitle => 'Bank appearance settings';

  @override
  String get brandingGeneral => 'General branding';

  @override
  String get brandingName => 'Application display name';

  @override
  String get brandingShortName => 'Application short name';

  @override
  String get brandingTagline => 'Tagline (optional)';

  @override
  String get brandingWelcome => 'Welcome message';

  @override
  String get brandingOriginal =>
      'Leave blank to keep the original localized text';

  @override
  String get brandingLogo => 'Application logo';

  @override
  String get brandingDarkLogo => 'Dark mode logo';

  @override
  String get brandingSplash => 'In-app splash image';

  @override
  String get brandingUpload => 'Upload image';

  @override
  String get brandingRemove => 'Use default asset';

  @override
  String get brandingUploadHelp =>
      'PNG/JPEG • maximum 2 MB • 16–4096 px per side • up to 4 megapixels. Aspect ratio is preserved.';

  @override
  String get brandingColors => 'Theme colors';

  @override
  String get brandingCustomTheme => 'Customize the theme';

  @override
  String get brandingLight => 'Light mode';

  @override
  String get brandingDark => 'Dark mode';

  @override
  String get brandingPrimary => 'Primary color';

  @override
  String get brandingSecondary => 'Secondary color';

  @override
  String get brandingAccent => 'Accent color';

  @override
  String get brandingBackground => 'Background';

  @override
  String get brandingSurface => 'Surface';

  @override
  String get brandingTextPrimary => 'Primary text';

  @override
  String get brandingTextSecondary => 'Secondary text';

  @override
  String get brandingError => 'Error color';

  @override
  String get brandingButtonBackground => 'Button background';

  @override
  String get brandingButtonText => 'Button text';

  @override
  String get brandingCard => 'Card background';

  @override
  String get brandingBorder => 'Border';

  @override
  String get brandingTypography => 'Typography';

  @override
  String get brandingPrimaryFont => 'Primary font family';

  @override
  String get brandingArabicFont => 'Arabic font family';

  @override
  String get brandingEnglishFont => 'English font family';

  @override
  String get brandingScale => 'Font size scale';

  @override
  String get brandingHeadingWeight => 'Heading weight';

  @override
  String get brandingBodyWeight => 'Body weight';

  @override
  String get brandingMode => 'Appearance policy';

  @override
  String get brandingUserMode => 'Keep customer choice';

  @override
  String get brandingSystem => 'System default';

  @override
  String get brandingPreview => 'Live preview — only visible here';

  @override
  String get brandingPreviewCard => 'Example account card';

  @override
  String get brandingPreviewBody => 'Secure banking at your fingertips';

  @override
  String get brandingSave => 'Save draft';

  @override
  String get brandingPublish => 'Publish changes';

  @override
  String get brandingDefaults => 'Restore original branding as draft';

  @override
  String get brandingHistory => 'Published configuration history';

  @override
  String get brandingRestore => 'Restore as draft';

  @override
  String get brandingNoHistory => 'No custom configuration has been published.';

  @override
  String get brandingDraftNotice =>
      'Save a draft and explicitly publish to update customer screens. Connected clients refresh on foreground resume; no new app download is needed for supported internal settings.';

  @override
  String get brandingSaved => 'Draft saved. Live branding is unchanged.';

  @override
  String get brandingPublished => 'Branding published successfully.';

  @override
  String get brandingRestored =>
      'Configuration restored as a draft. Review and publish to apply.';

  @override
  String get brandingUploaded =>
      'Image uploaded. Save the draft to keep this selection.';

  @override
  String get brandingConflict =>
      'Another administrator changed these settings. Your edits are preserved; reload to review the latest version.';

  @override
  String get brandingInvalid =>
      'Check the internal text, supported fonts and size scale. The preview keeps the last valid appearance.';

  @override
  String get brandingRequestFailed =>
      'The operation could not be completed. Your edits are preserved; try again.';

  @override
  String get brandingSaveFirst => 'Save a valid draft before publishing.';

  @override
  String get brandingHistoryFailed =>
      'Could not load history. Reload to try again.';

  @override
  String get brandingPublishConfirm =>
      'Publish the saved internal appearance changes for the affected banks?';

  @override
  String get brandingReloadConfirm => 'Reload and replace your unsaved edits?';

  @override
  String get brandingReplaceConfirm =>
      'Replace the current draft? This will not publish anything.';

  @override
  String get brandingUnsaved => 'You have unsaved edits.';

  @override
  String get brandingNative => 'Native launcher branding';

  @override
  String get brandingReleaseRequired => 'Requires New Application Release';

  @override
  String get brandingNativeHelp =>
      'Launcher labels and icons are fixed in the application release. Changes require a new release. These controls only affect in-app appearance.';

  @override
  String get brandingHex => 'HEX color (#RRGGBB)';

  @override
  String get brandingHue => 'Hue';

  @override
  String get brandingSaturation => 'Saturation';

  @override
  String get brandingBrightness => 'Brightness';

  @override
  String get brandingVersion => 'Published version';

  @override
  String get brandingMoreHistory => 'Load older versions';

  @override
  String get brandingSystemFont => 'Original system font';

  @override
  String get bankSelectionLabel => 'Bank';

  @override
  String get bankSelectionRequired => 'Choose your card’s bank.';

  @override
  String get bankRegistrationHelp =>
      'Choose the bank of your provisioned development card. Verification uses the contact already registered for that customer; selecting a bank never changes card ownership.';

  @override
  String get bankFixedIdentity => 'Fixed application identity';

  @override
  String get bankFixedIdentityHelp =>
      'Bank names and official logos follow the selected bank. These settings change supported in-app appearance, not the native launcher.';

  @override
  String get bankAppearanceScope =>
      'Edits apply to customers registered with the selected bank. Other banks and the fixed application identity stay independent.';

  @override
  String get bankPresetColors => 'Bank color preset';

  @override
  String get bankPresetHelp =>
      'This read-only palette is inspired by the bank’s identity and adjusted for accessible text contrast. Colors cannot be replaced with arbitrary values.';

  @override
  String get bankInternalContent => 'Content inside customer accounts';

  @override
  String get bankInternalCaption => 'Internal caption (optional)';

  @override
  String get bankRestorePreset => 'Restore this bank’s defaults as draft';

  @override
  String get bankDirectoryNote =>
      'The bundled street-address directory belongs to Faisal Bank only. For other banks, use the verified official website; no unverified addresses or hotlines are shown.';

  @override
  String get bankOfficialWebsite => 'Open official bank website';

  @override
  String get bankServiceChoose => 'Choose a bank for this service.';

  @override
  String get bankLinkedBank => 'Registered bank';

  @override
  String get bankLoginSelectionLabel => 'Bank (optional for sign-in)';

  @override
  String get bankLoginAutomatic => 'Detect from username or card';

  @override
  String get bankLoginSelectionHelp =>
      'Choose the bank for this username/card, or leave automatic. Each successful sign-in uses the bank verified by the server. Administrators sign in without choosing a bank.';

  @override
  String get bankIntroTitle => 'Your banks, in one place';

  @override
  String get bankIntroBody =>
      'Choose your bank to access its services with its own familiar identity. Switch banks whenever you need to.';

  @override
  String get bankSecurityIntroTitle => 'Your identity stays with your bank';

  @override
  String get bankSecurityIntroBody =>
      'Sign in using your bank username. New here? Verify your card with a one-time code, then create a username and password.';

  @override
  String get bankChooseTitle => 'Choose your bank';

  @override
  String get bankChooseBody =>
      'Your login, branches, ATMs and customer service will follow this selection.';

  @override
  String get bankSearchLabel => 'Search banks';

  @override
  String get bankChangeSelection => 'Change bank';

  @override
  String get bankNoticeSpecific => 'Notice for a specific bank';

  @override
  String get bankDirectoryReviewed => 'Source reviewed';

  @override
  String get bankDirectoryPartial =>
      'This is a verified subset of the bank’s published locations. See the official locator for the full current network.';

  @override
  String get bankDirectoryUnavailable =>
      'A verified address list is not available here yet. Use this bank’s official locator; another bank’s locations are never substituted.';

  @override
  String get bankContactUnavailable =>
      'A customer service number has not been verified here yet. Use this bank’s official contact website.';
}
