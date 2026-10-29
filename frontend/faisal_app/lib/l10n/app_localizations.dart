import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Your banks'**
  String get appName;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Your bank'**
  String get bankName;

  /// No description provided for @bankNameShort.
  ///
  /// In en, this message translates to:
  /// **'Your banks'**
  String get bankNameShort;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Banking, thoughtfully designed'**
  String get appTagline;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @demoDataNotice.
  ///
  /// In en, this message translates to:
  /// **'Development simulation. Bank names and themes do not indicate a connection to any real bank or payment network.'**
  String get demoDataNotice;

  /// No description provided for @simulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated'**
  String get simulated;

  /// No description provided for @simulatedShort.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get simulatedShort;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get loadingMore;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get noData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'{amount} {currency}'**
  String amountWithCurrency(String amount, String currency);

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfers;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get admin;

  /// No description provided for @repayments.
  ///
  /// In en, this message translates to:
  /// **'Repayments'**
  String get repayments;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your username and password.'**
  String get loginSubtitle;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get cardNumber;

  /// No description provided for @cardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'4508 1234 5678 9012'**
  String get cardNumberHint;

  /// No description provided for @loginIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginIdentifier;

  /// No description provided for @loginIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get loginIdentifierHint;

  /// No description provided for @invalidLoginIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid username, card or account number.'**
  String get invalidLoginIdentifier;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @temporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Account number / temporary password'**
  String get temporaryPassword;

  /// No description provided for @temporaryPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your account number on first sign-in'**
  String get temporaryPasswordHint;

  /// No description provided for @rememberDevice.
  ///
  /// In en, this message translates to:
  /// **'Remember this device'**
  String get rememberDevice;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @securityNotice.
  ///
  /// In en, this message translates to:
  /// **'Never share your password or one-time codes. Your bank will never ask for them.'**
  String get securityNotice;

  /// No description provided for @invalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid card number (at least 8 digits).'**
  String get invalidCardNumber;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in. Check your details and try again.'**
  String get loginFailed;

  /// No description provided for @firstLoginBadge.
  ///
  /// In en, this message translates to:
  /// **'First-time setup'**
  String get firstLoginBadge;

  /// No description provided for @createSecurePassword.
  ///
  /// In en, this message translates to:
  /// **'Create a secure password'**
  String get createSecurePassword;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}. For your security, please replace your temporary credential with a new password.'**
  String setupSubtitle(String name);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get strengthWeak;

  /// No description provided for @strengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get strengthFair;

  /// No description provided for @strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get strengthGood;

  /// No description provided for @strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strengthStrong;

  /// No description provided for @reqMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get reqMinLength;

  /// No description provided for @reqUppercase.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter (A–Z)'**
  String get reqUppercase;

  /// No description provided for @reqLowercase.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter (a–z)'**
  String get reqLowercase;

  /// No description provided for @reqDigit.
  ///
  /// In en, this message translates to:
  /// **'One number (0–9)'**
  String get reqDigit;

  /// No description provided for @reqSpecial.
  ///
  /// In en, this message translates to:
  /// **'One special character (! @ # \$ % & *)'**
  String get reqSpecial;

  /// No description provided for @reqNoRepeat.
  ///
  /// In en, this message translates to:
  /// **'No character repeated 3 times in a row'**
  String get reqNoRepeat;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @passwordPolicyError.
  ///
  /// In en, this message translates to:
  /// **'Your password does not meet all the security requirements.'**
  String get passwordPolicyError;

  /// No description provided for @continueToHome.
  ///
  /// In en, this message translates to:
  /// **'Save password and continue'**
  String get continueToHome;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get passwordUpdated;

  /// No description provided for @setupExpired.
  ///
  /// In en, this message translates to:
  /// **'Your setup session has expired. Please sign in again.'**
  String get setupExpired;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingUser.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetingUser(String greeting, String name);

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @blockedBalance.
  ///
  /// In en, this message translates to:
  /// **'Blocked balance'**
  String get blockedBalance;

  /// No description provided for @hideBalance.
  ///
  /// In en, this message translates to:
  /// **'Hide balance'**
  String get hideBalance;

  /// No description provided for @showBalance.
  ///
  /// In en, this message translates to:
  /// **'Show balance'**
  String get showBalance;

  /// No description provided for @activeAccounts.
  ///
  /// In en, this message translates to:
  /// **'Active accounts'**
  String get activeAccounts;

  /// No description provided for @activeAccountsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active accounts'**
  String activeAccountsCount(int count);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @myAccounts.
  ///
  /// In en, this message translates to:
  /// **'My accounts'**
  String get myAccounts;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @viewAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'View all transactions'**
  String get viewAllTransactions;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @accountTypeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current account'**
  String get accountTypeCurrent;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment account'**
  String get accountTypeInvestment;

  /// No description provided for @accountTypeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountTypeSavings;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTypeOther;

  /// No description provided for @accountEndingIn.
  ///
  /// In en, this message translates to:
  /// **'Account {last4}'**
  String accountEndingIn(String last4);

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumber;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetails;

  /// No description provided for @totalAcrossAccounts.
  ///
  /// In en, this message translates to:
  /// **'Total across eligible accounts'**
  String get totalAcrossAccounts;

  /// No description provided for @linkedCards.
  ///
  /// In en, this message translates to:
  /// **'Linked cards'**
  String get linkedCards;

  /// No description provided for @accountServices.
  ///
  /// In en, this message translates to:
  /// **'Account services'**
  String get accountServices;

  /// No description provided for @openAccount.
  ///
  /// In en, this message translates to:
  /// **'Open an account'**
  String get openAccount;

  /// No description provided for @closeAccount.
  ///
  /// In en, this message translates to:
  /// **'Close account'**
  String get closeAccount;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select a product'**
  String get selectProduct;

  /// No description provided for @minimumBalance.
  ///
  /// In en, this message translates to:
  /// **'Minimum balance'**
  String get minimumBalance;

  /// No description provided for @closeAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Closing an account requires the balance to be settled and approval from the bank.'**
  String get closeAccountWarning;

  /// No description provided for @requestSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Request {reference} has been submitted.'**
  String requestSubmittedMessage(String reference);

  /// No description provided for @cardsTitle.
  ///
  /// In en, this message translates to:
  /// **'My cards'**
  String get cardsTitle;

  /// No description provided for @cardHolder.
  ///
  /// In en, this message translates to:
  /// **'Cardholder'**
  String get cardHolder;

  /// No description provided for @cardExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {month}/{year}'**
  String cardExpires(String month, String year);

  /// No description provided for @cardEndingIn.
  ///
  /// In en, this message translates to:
  /// **'Card ending {last4}'**
  String cardEndingIn(String last4);

  /// No description provided for @freezeCard.
  ///
  /// In en, this message translates to:
  /// **'Freeze card'**
  String get freezeCard;

  /// No description provided for @unfreezeCard.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze card'**
  String get unfreezeCard;

  /// No description provided for @reportLostCard.
  ///
  /// In en, this message translates to:
  /// **'Report lost card'**
  String get reportLostCard;

  /// No description provided for @reportStolenCard.
  ///
  /// In en, this message translates to:
  /// **'Report stolen card'**
  String get reportStolenCard;

  /// No description provided for @blockCardPermanently.
  ///
  /// In en, this message translates to:
  /// **'Block card permanently'**
  String get blockCardPermanently;

  /// No description provided for @requestReplacement.
  ///
  /// In en, this message translates to:
  /// **'Request replacement'**
  String get requestReplacement;

  /// No description provided for @requestRenewal.
  ///
  /// In en, this message translates to:
  /// **'Request renewal'**
  String get requestRenewal;

  /// No description provided for @resetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPin;

  /// No description provided for @cardLimits.
  ///
  /// In en, this message translates to:
  /// **'Card limits'**
  String get cardLimits;

  /// No description provided for @dailyPurchaseLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily purchase limit'**
  String get dailyPurchaseLimit;

  /// No description provided for @dailyAtmLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily ATM limit'**
  String get dailyAtmLimit;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimit;

  /// No description provided for @onlinePayments.
  ///
  /// In en, this message translates to:
  /// **'Online payments'**
  String get onlinePayments;

  /// No description provided for @internationalPayments.
  ///
  /// In en, this message translates to:
  /// **'International payments'**
  String get internationalPayments;

  /// No description provided for @contactlessPayments.
  ///
  /// In en, this message translates to:
  /// **'Contactless payments'**
  String get contactlessPayments;

  /// No description provided for @cardSettings.
  ///
  /// In en, this message translates to:
  /// **'Card settings'**
  String get cardSettings;

  /// No description provided for @creditDetails.
  ///
  /// In en, this message translates to:
  /// **'Credit details'**
  String get creditDetails;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get outstandingBalance;

  /// No description provided for @statementBalance.
  ///
  /// In en, this message translates to:
  /// **'Statement balance'**
  String get statementBalance;

  /// No description provided for @minimumPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment'**
  String get minimumPayment;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @availableCredit.
  ///
  /// In en, this message translates to:
  /// **'Available credit'**
  String get availableCredit;

  /// No description provided for @paymentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Payment due date'**
  String get paymentDueDate;

  /// No description provided for @supplementaryCard.
  ///
  /// In en, this message translates to:
  /// **'Supplementary card'**
  String get supplementaryCard;

  /// No description provided for @requestSupplementaryCard.
  ///
  /// In en, this message translates to:
  /// **'Request supplementary card'**
  String get requestSupplementaryCard;

  /// No description provided for @cardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get cardStatusActive;

  /// No description provided for @cardStatusFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get cardStatusFrozen;

  /// No description provided for @cardStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Reported lost'**
  String get cardStatusLost;

  /// No description provided for @cardStatusStolen.
  ///
  /// In en, this message translates to:
  /// **'Reported stolen'**
  String get cardStatusStolen;

  /// No description provided for @cardStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get cardStatusBlocked;

  /// No description provided for @cardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cardStatusCancelled;

  /// No description provided for @cardStatusPendingActivation.
  ///
  /// In en, this message translates to:
  /// **'Pending activation'**
  String get cardStatusPendingActivation;

  /// No description provided for @cardStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get cardStatusExpired;

  /// No description provided for @confirmFreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Freeze this card?'**
  String get confirmFreezeTitle;

  /// No description provided for @confirmFreezeBody.
  ///
  /// In en, this message translates to:
  /// **'Card payments will be blocked until you unfreeze it. You can unfreeze it at any time.'**
  String get confirmFreezeBody;

  /// No description provided for @confirmUnfreezeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze this card?'**
  String get confirmUnfreezeTitle;

  /// No description provided for @confirmUnfreezeBody.
  ///
  /// In en, this message translates to:
  /// **'Card payments will be enabled again.'**
  String get confirmUnfreezeBody;

  /// No description provided for @confirmBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently block this card?'**
  String get confirmBlockTitle;

  /// No description provided for @confirmBlockBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone from the app. You will need to request a replacement card.'**
  String get confirmBlockBody;

  /// No description provided for @confirmLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this card as lost?'**
  String get confirmLostTitle;

  /// No description provided for @confirmLostBody.
  ///
  /// In en, this message translates to:
  /// **'The card will be blocked immediately for your protection.'**
  String get confirmLostBody;

  /// No description provided for @confirmStolenTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this card as stolen?'**
  String get confirmStolenTitle;

  /// No description provided for @confirmStolenBody.
  ///
  /// In en, this message translates to:
  /// **'The card will be blocked immediately. Contact the bank if you need urgent assistance.'**
  String get confirmStolenBody;

  /// No description provided for @cardFrozenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card frozen.'**
  String get cardFrozenSuccess;

  /// No description provided for @cardUnfrozenSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card unfrozen.'**
  String get cardUnfrozenSuccess;

  /// No description provided for @cardBlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Card blocked.'**
  String get cardBlockedSuccess;

  /// No description provided for @cardActionFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not complete this action. Please try again.'**
  String get cardActionFailed;

  /// No description provided for @transactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTitle;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search by description, merchant or reference'**
  String get searchTransactions;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get dateTo;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get transactionType;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// No description provided for @debit.
  ///
  /// In en, this message translates to:
  /// **'Debit'**
  String get debit;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum amount'**
  String get maxAmount;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @receiptAvailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt available'**
  String get receiptAvailable;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions match your filters'**
  String get noTransactionsFound;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionTypeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get transactionTypeDeposit;

  /// No description provided for @transactionTypeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get transactionTypeWithdrawal;

  /// No description provided for @transactionTypePurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get transactionTypePurchase;

  /// No description provided for @transactionTypeBillPayment.
  ///
  /// In en, this message translates to:
  /// **'Bill payment'**
  String get transactionTypeBillPayment;

  /// No description provided for @transactionTypeCardRepayment.
  ///
  /// In en, this message translates to:
  /// **'Card repayment'**
  String get transactionTypeCardRepayment;

  /// No description provided for @transactionTypeFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get transactionTypeFee;

  /// No description provided for @transactionTypeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get transactionTypeAdjustment;

  /// No description provided for @transactionTypeSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get transactionTypeSalary;

  /// No description provided for @transactionStatusPosted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transactionStatusPosted;

  /// No description provided for @transactionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transactionStatusPending;

  /// No description provided for @transactionStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transactionStatusFailed;

  /// No description provided for @transactionStatusReversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get transactionStatusReversed;

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTitle;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @savedBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Saved beneficiary'**
  String get savedBeneficiary;

  /// No description provided for @newBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'New beneficiary'**
  String get newBeneficiary;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @reviewTransfer.
  ///
  /// In en, this message translates to:
  /// **'Review transfer'**
  String get reviewTransfer;

  /// No description provided for @confirmTransfer.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer'**
  String get confirmTransfer;

  /// No description provided for @transferReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Transfers in this demo are simulated and do not move real money.'**
  String get transferReviewNote;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed (simulated)'**
  String get transferSuccess;

  /// No description provided for @transferSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Reference {reference}'**
  String transferSuccessMessage(String reference);

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'The transfer could not be completed.'**
  String get transferFailed;

  /// No description provided for @beneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Beneficiaries'**
  String get beneficiaries;

  /// No description provided for @addBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Add beneficiary'**
  String get addBeneficiary;

  /// No description provided for @bankNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankNameLabel;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @deleteBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Remove beneficiary'**
  String get deleteBeneficiary;

  /// No description provided for @insufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'The available balance is not sufficient.'**
  String get insufficientFunds;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @payBill.
  ///
  /// In en, this message translates to:
  /// **'Pay a bill'**
  String get payBill;

  /// No description provided for @biller.
  ///
  /// In en, this message translates to:
  /// **'Biller'**
  String get biller;

  /// No description provided for @billerCategory.
  ///
  /// In en, this message translates to:
  /// **'Biller category'**
  String get billerCategory;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment completed (simulated)'**
  String get paymentSuccess;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @branchServices.
  ///
  /// In en, this message translates to:
  /// **'Branch services'**
  String get branchServices;

  /// No description provided for @cashDepositRequest.
  ///
  /// In en, this message translates to:
  /// **'Cash deposit request'**
  String get cashDepositRequest;

  /// No description provided for @cashWithdrawalRequest.
  ///
  /// In en, this message translates to:
  /// **'Cash withdrawal request'**
  String get cashWithdrawalRequest;

  /// No description provided for @branchServiceNote.
  ///
  /// In en, this message translates to:
  /// **'Branch services create a request for the bank to action. No money moves automatically.'**
  String get branchServiceNote;

  /// No description provided for @selectBiller.
  ///
  /// In en, this message translates to:
  /// **'Select a biller'**
  String get selectBiller;

  /// No description provided for @repaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit card repayments'**
  String get repaymentsTitle;

  /// No description provided for @repayCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Repay credit card'**
  String get repayCreditCard;

  /// No description provided for @selectCard.
  ///
  /// In en, this message translates to:
  /// **'Select card'**
  String get selectCard;

  /// No description provided for @selectFundingAccount.
  ///
  /// In en, this message translates to:
  /// **'Select funding account'**
  String get selectFundingAccount;

  /// No description provided for @repaymentOption.
  ///
  /// In en, this message translates to:
  /// **'Repayment option'**
  String get repaymentOption;

  /// No description provided for @optionFullBalance.
  ///
  /// In en, this message translates to:
  /// **'Full outstanding balance'**
  String get optionFullBalance;

  /// No description provided for @optionStatementBalance.
  ///
  /// In en, this message translates to:
  /// **'Current statement balance'**
  String get optionStatementBalance;

  /// No description provided for @optionMinimumPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment'**
  String get optionMinimumPayment;

  /// No description provided for @optionCustomAmount.
  ///
  /// In en, this message translates to:
  /// **'Custom amount'**
  String get optionCustomAmount;

  /// No description provided for @charges.
  ///
  /// In en, this message translates to:
  /// **'Charges'**
  String get charges;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get totalPayable;

  /// No description provided for @confirmRepayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm repayment'**
  String get confirmRepayment;

  /// No description provided for @repaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Repayment completed (simulated)'**
  String get repaymentSuccess;

  /// No description provided for @repaymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Repayment reference {reference}'**
  String repaymentSuccessMessage(String reference);

  /// No description provided for @repaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Repayments are processed by a simulated payment service. No real bank transfer occurs.'**
  String get repaymentNote;

  /// No description provided for @repaymentNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This repayment is not available with the selected account.'**
  String get repaymentNotEligible;

  /// No description provided for @repaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Repayment history'**
  String get repaymentHistory;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTitle;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get requestDetails;

  /// No description provided for @requestType.
  ///
  /// In en, this message translates to:
  /// **'Request type'**
  String get requestType;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on'**
  String get submittedOn;

  /// No description provided for @statusHistory.
  ///
  /// In en, this message translates to:
  /// **'Status history'**
  String get statusHistory;

  /// No description provided for @decisionReason.
  ///
  /// In en, this message translates to:
  /// **'Decision reason'**
  String get decisionReason;

  /// No description provided for @provideInformation.
  ///
  /// In en, this message translates to:
  /// **'Provide information'**
  String get provideInformation;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @awaitingYourInformation.
  ///
  /// In en, this message translates to:
  /// **'The bank needs more information from you.'**
  String get awaitingYourInformation;

  /// No description provided for @requestReferenceCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get requestReferenceCopied;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusUnderReview;

  /// No description provided for @statusPendingCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get statusPendingCustomerInfo;

  /// No description provided for @statusPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get statusPendingApproval;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @requestTypeAccountOpen.
  ///
  /// In en, this message translates to:
  /// **'Open account'**
  String get requestTypeAccountOpen;

  /// No description provided for @requestTypeAccountClose.
  ///
  /// In en, this message translates to:
  /// **'Close account'**
  String get requestTypeAccountClose;

  /// No description provided for @requestTypeCardReplacement.
  ///
  /// In en, this message translates to:
  /// **'Replace card'**
  String get requestTypeCardReplacement;

  /// No description provided for @requestTypeCardRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renew card'**
  String get requestTypeCardRenewal;

  /// No description provided for @requestTypeCardCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancel card'**
  String get requestTypeCardCancellation;

  /// No description provided for @requestTypeLimitIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase card limit'**
  String get requestTypeLimitIncrease;

  /// No description provided for @requestTypeLimitDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease card limit'**
  String get requestTypeLimitDecrease;

  /// No description provided for @requestTypePinReset.
  ///
  /// In en, this message translates to:
  /// **'Reset card PIN'**
  String get requestTypePinReset;

  /// No description provided for @requestTypeSupplementary.
  ///
  /// In en, this message translates to:
  /// **'Supplementary card'**
  String get requestTypeSupplementary;

  /// No description provided for @requestTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card application'**
  String get requestTypeCreditCard;

  /// No description provided for @requestTypeInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment product'**
  String get requestTypeInvestment;

  /// No description provided for @requestTypeInfoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update my information'**
  String get requestTypeInfoUpdate;

  /// No description provided for @requestTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other service'**
  String get requestTypeOther;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'You have no requests yet'**
  String get noRequests;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @unreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unreadNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications'**
  String get noNotifications;

  /// No description provided for @announcementDetails.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcementDetails;

  /// No description provided for @maintenanceNotice.
  ///
  /// In en, this message translates to:
  /// **'Service notice'**
  String get maintenanceNotice;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get productsTitle;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersTitle;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product details'**
  String get productDetails;

  /// No description provided for @eligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get eligibility;

  /// No description provided for @pricingInformation.
  ///
  /// In en, this message translates to:
  /// **'Pricing information'**
  String get pricingInformation;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply now'**
  String get applyNow;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @customerNumber.
  ///
  /// In en, this message translates to:
  /// **'Customer number'**
  String get customerNumber;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get identityVerified;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get activeSessions;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferences;

  /// No description provided for @transactionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Transaction alerts'**
  String get transactionNotifications;

  /// No description provided for @marketingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Offers and marketing'**
  String get marketingNotifications;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get allNotifications;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in'**
  String get biometricLogin;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are unavailable or no biometric credential is enrolled. Use your password and enroll biometrics in device settings.'**
  String get biometricUnavailable;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I reset my password?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Choose Forgot password on the sign-in screen. A bank representative will provide a one-time reset code.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'Why is my card frozen?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'A freeze is a temporary block you control. Open the card and select Unfreeze card to enable payments again.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'Are transfers real?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'No. This demo uses a simulated payment service and never moves real money.'**
  String get faqA3;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated.'**
  String get profileUpdated;

  /// No description provided for @preferencesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Preferences updated.'**
  String get preferencesUpdated;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTitle;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get newTicket;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noTickets;

  /// No description provided for @contactChannels.
  ///
  /// In en, this message translates to:
  /// **'Contact channels'**
  String get contactChannels;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call the bank'**
  String get callUs;

  /// No description provided for @branchLocator.
  ///
  /// In en, this message translates to:
  /// **'Find a branch'**
  String get branchLocator;

  /// No description provided for @adminPortal.
  ///
  /// In en, this message translates to:
  /// **'Administration portal'**
  String get adminPortal;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashboard;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @requestQueue.
  ///
  /// In en, this message translates to:
  /// **'Request queue'**
  String get requestQueue;

  /// No description provided for @announcementsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsAdmin;

  /// No description provided for @productsAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Products & offers'**
  String get productsAndOffers;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditLogs;

  /// No description provided for @demoStatistics.
  ///
  /// In en, this message translates to:
  /// **'Demo statistics'**
  String get demoStatistics;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @publishedAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Published announcements'**
  String get publishedAnnouncements;

  /// No description provided for @scheduledMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Scheduled maintenance'**
  String get scheduledMaintenance;

  /// No description provided for @recentActions.
  ///
  /// In en, this message translates to:
  /// **'Recent administrative actions'**
  String get recentActions;

  /// No description provided for @reviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Review queue'**
  String get reviewQueue;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @requestInformation.
  ///
  /// In en, this message translates to:
  /// **'Request information'**
  String get requestInformation;

  /// No description provided for @assignReviewer.
  ///
  /// In en, this message translates to:
  /// **'Assign reviewer'**
  String get assignReviewer;

  /// No description provided for @internalNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get internalNote;

  /// No description provided for @customerExplanation.
  ///
  /// In en, this message translates to:
  /// **'Message to customer'**
  String get customerExplanation;

  /// No description provided for @confirmApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve this request?'**
  String get confirmApprove;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get confirmReject;

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason for the rejection (at least 5 characters).'**
  String get rejectionReasonRequired;

  /// No description provided for @createAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Create announcement'**
  String get createAnnouncement;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @audienceAll.
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get audienceAll;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @titleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get titleEn;

  /// No description provided for @titleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get titleAr;

  /// No description provided for @bodyEn.
  ///
  /// In en, this message translates to:
  /// **'Content (English)'**
  String get bodyEn;

  /// No description provided for @bodyAr.
  ///
  /// In en, this message translates to:
  /// **'Content (Arabic)'**
  String get bodyAr;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdOn;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this page.'**
  String get noAccess;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to perform this action.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @startupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t restore your saved session. Check your connection and try again.'**
  String get startupRestoreFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get invalidAmount;

  /// No description provided for @amountPositive.
  ///
  /// In en, this message translates to:
  /// **'The amount must be greater than zero.'**
  String get amountPositive;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date.'**
  String get invalidDate;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @readOnlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Read-only access'**
  String get readOnlyAccess;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register for digital banking'**
  String get registerTitle;

  /// No description provided for @registrationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Enter your card number for the selected bank. Verify using your registered contact, then create your unique username and password.'**
  String get registrationExplanation;

  /// No description provided for @registrationVerified.
  ///
  /// In en, this message translates to:
  /// **'Contact verified. Create your secure password to complete enrollment.'**
  String get registrationVerified;

  /// No description provided for @registeredContactMasked.
  ///
  /// In en, this message translates to:
  /// **'Verification uses your registered contact (***).'**
  String get registeredContactMasked;

  /// No description provided for @identifierFormatError.
  ///
  /// In en, this message translates to:
  /// **'Enter 6–24 digits; spaces, dashes and dots are allowed.'**
  String get identifierFormatError;

  /// No description provided for @otpExplanation.
  ///
  /// In en, this message translates to:
  /// **'If your details are eligible, use the six-digit code provided to your registered contact. Never share this code.'**
  String get otpExplanation;

  /// No description provided for @otpDevelopmentNotice.
  ///
  /// In en, this message translates to:
  /// **'For your test: enter the code shown below. No message was sent; real SMS/email delivery is not configured. A new request replaces the previous code.'**
  String get otpDevelopmentNotice;

  /// No description provided for @developmentCode.
  ///
  /// In en, this message translates to:
  /// **'Local development code'**
  String get developmentCode;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpCode;

  /// No description provided for @otpFormatError.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code.'**
  String get otpFormatError;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Request another code'**
  String get resendCode;

  /// No description provided for @otpIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The verification code is incorrect.'**
  String get otpIncorrect;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Request another code.'**
  String get otpExpired;

  /// No description provided for @otpUsed.
  ///
  /// In en, this message translates to:
  /// **'This code was used or replaced. Start registration again.'**
  String get otpUsed;

  /// No description provided for @otpAttemptsExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many incorrect codes. Start registration again later.'**
  String get otpAttemptsExceeded;

  /// No description provided for @authorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorize operation'**
  String get authorizeTitle;

  /// No description provided for @authorizationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your current password to generate a short-lived token for this operation. Copy it, continue, and enter it on the confirmation page.'**
  String get authorizationExplanation;

  /// No description provided for @authorizationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Authorization token issued'**
  String get authorizationSuccess;

  /// No description provided for @authorizationValidity.
  ///
  /// In en, this message translates to:
  /// **'Validity in seconds'**
  String get authorizationValidity;

  /// No description provided for @authorizationToken.
  ///
  /// In en, this message translates to:
  /// **'Authorization token'**
  String get authorizationToken;

  /// No description provided for @copyToken.
  ///
  /// In en, this message translates to:
  /// **'Copy Token'**
  String get copyToken;

  /// No description provided for @tokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Token copied (clears after 60 seconds)'**
  String get tokenCopied;

  /// No description provided for @authorizationExpired.
  ///
  /// In en, this message translates to:
  /// **'The authorization token expired. Authorize again.'**
  String get authorizationExpired;

  /// No description provided for @authorizationUsed.
  ///
  /// In en, this message translates to:
  /// **'This authorization token has already been used.'**
  String get authorizationUsed;

  /// No description provided for @authorizationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid token issued for this operation and these details.'**
  String get authorizationInvalid;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The current password is incorrect.'**
  String get currentPasswordIncorrect;

  /// No description provided for @passwordsMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Passwords match'**
  String get passwordsMatchLabel;

  /// No description provided for @securityOperationError.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed. Check the details and try again.'**
  String get securityOperationError;

  /// No description provided for @transferBalanceError.
  ///
  /// In en, this message translates to:
  /// **'The available balance is insufficient.'**
  String get transferBalanceError;

  /// No description provided for @internalTransferOnly.
  ///
  /// In en, this message translates to:
  /// **'Only verified internal account destinations are supported. Existing external beneficiaries are preserved but cannot receive transfers here.'**
  String get internalTransferOnly;

  /// No description provided for @totalDebit.
  ///
  /// In en, this message translates to:
  /// **'Total debit'**
  String get totalDebit;

  /// No description provided for @beneficiaryName.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary name'**
  String get beneficiaryName;

  /// No description provided for @ownAccounts.
  ///
  /// In en, this message translates to:
  /// **'Between my accounts'**
  String get ownAccounts;

  /// No description provided for @transferReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transfer receipt'**
  String get transferReceipt;

  /// No description provided for @editTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit transfer details'**
  String get editTransfer;

  /// No description provided for @transferExplicitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'I confirm the reviewed beneficiary, amount and total debit.'**
  String get transferExplicitConfirmation;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update personal information'**
  String get updatePersonalInfo;

  /// No description provided for @profileReviewExplanation.
  ///
  /// In en, this message translates to:
  /// **'Submit email, phone or address changes electronically for bank review. Your verified details remain unchanged until approval. Identity and legal name changes require bank assistance.'**
  String get profileReviewExplanation;

  /// No description provided for @profilePendingReview.
  ///
  /// In en, this message translates to:
  /// **'Submitted for bank review. Your verified information has not changed.'**
  String get profilePendingReview;

  /// No description provided for @profileRequestExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending information update request.'**
  String get profileRequestExists;

  /// No description provided for @biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enter banking'**
  String get biometricReason;

  /// No description provided for @biometricEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Biometric re-entry enabled on this device. A valid backend session is still required.'**
  String get biometricEnabledMessage;

  /// No description provided for @biometricDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Biometric re-entry disabled on this device.'**
  String get biometricDisabledMessage;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get biometricUnlock;

  /// No description provided for @biometricLocked.
  ///
  /// In en, this message translates to:
  /// **'Your session is locked. Unlock or sign out to use a password.'**
  String get biometricLocked;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'3–30 English letters and digits only; start with a letter.'**
  String get usernameHint;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid username.'**
  String get usernameInvalid;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username is available'**
  String get usernameAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username is unavailable. Choose a suggestion or type another.'**
  String get usernameTaken;

  /// No description provided for @investmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates & investment funds'**
  String get investmentsTitle;

  /// No description provided for @investmentSimulationNotice.
  ///
  /// In en, this message translates to:
  /// **'Development simulation: subscriptions debit your account immediately. Fund unit prices are simulated; no real investment or guaranteed return.'**
  String get investmentSimulationNotice;

  /// No description provided for @investmentProduct.
  ///
  /// In en, this message translates to:
  /// **'Certificate or fund'**
  String get investmentProduct;

  /// No description provided for @investmentMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum subscription'**
  String get investmentMinimum;

  /// No description provided for @investmentStep.
  ///
  /// In en, this message translates to:
  /// **'Amount increment'**
  String get investmentStep;

  /// No description provided for @investmentUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get investmentUnits;

  /// No description provided for @investmentMaximumPenalty.
  ///
  /// In en, this message translates to:
  /// **'Maximum early redemption deduction'**
  String get investmentMaximumPenalty;

  /// No description provided for @investmentPenaltyFormula.
  ///
  /// In en, this message translates to:
  /// **'Certificate deduction = principal × maximum percentage × remaining days ÷ total days; zero at maturity. Funds have no term penalty in this simulation.'**
  String get investmentPenaltyFormula;

  /// No description provided for @investmentAmountError.
  ///
  /// In en, this message translates to:
  /// **'Use the minimum subscription and the specified amount increments.'**
  String get investmentAmountError;

  /// No description provided for @investmentSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get investmentSubscribe;

  /// No description provided for @myInvestments.
  ///
  /// In en, this message translates to:
  /// **'My investments'**
  String get myInvestments;

  /// No description provided for @noInvestments.
  ///
  /// In en, this message translates to:
  /// **'You have no investment holdings yet.'**
  String get noInvestments;

  /// No description provided for @investmentPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get investmentPrincipal;

  /// No description provided for @investmentActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get investmentActive;

  /// No description provided for @investmentRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get investmentRedeemed;

  /// No description provided for @investmentMaturity.
  ///
  /// In en, this message translates to:
  /// **'Maturity date'**
  String get investmentMaturity;

  /// No description provided for @investmentRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem / break'**
  String get investmentRedeem;

  /// No description provided for @investmentReview.
  ///
  /// In en, this message translates to:
  /// **'Review investment operation'**
  String get investmentReview;

  /// No description provided for @investmentPenalty.
  ///
  /// In en, this message translates to:
  /// **'Early redemption deduction'**
  String get investmentPenalty;

  /// No description provided for @investmentNetCredit.
  ///
  /// In en, this message translates to:
  /// **'Net amount returned to your account'**
  String get investmentNetCredit;

  /// No description provided for @investmentConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm the reviewed investment operation and its deduction policy.'**
  String get investmentConfirm;

  /// No description provided for @investmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Investment operation completed'**
  String get investmentCompleted;

  /// No description provided for @investmentPending.
  ///
  /// In en, this message translates to:
  /// **'Operation awaiting completion'**
  String get investmentPending;

  /// No description provided for @investmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This investment is unavailable or has already been redeemed. Refresh your holdings.'**
  String get investmentUnavailable;

  /// No description provided for @exchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency exchange rates'**
  String get exchangeRatesTitle;

  /// No description provided for @fxIndicativeNotice.
  ///
  /// In en, this message translates to:
  /// **'Indicative global rates in EGP. Buy and sell values use a simulated spread; they are not bank dealing prices and cannot execute an exchange.'**
  String get fxIndicativeNotice;

  /// No description provided for @fxProviderTime.
  ///
  /// In en, this message translates to:
  /// **'Rate observation time'**
  String get fxProviderTime;

  /// No description provided for @fxFetchedTime.
  ///
  /// In en, this message translates to:
  /// **'Last server fetch'**
  String get fxFetchedTime;

  /// No description provided for @fxDelaySeconds.
  ///
  /// In en, this message translates to:
  /// **'Provider delay (seconds)'**
  String get fxDelaySeconds;

  /// No description provided for @fxSpread.
  ///
  /// In en, this message translates to:
  /// **'Simulated total spread'**
  String get fxSpread;

  /// No description provided for @fxMarketOpen.
  ///
  /// In en, this message translates to:
  /// **'Market session: open'**
  String get fxMarketOpen;

  /// No description provided for @fxMarketClosed.
  ///
  /// In en, this message translates to:
  /// **'Market session closed / reference rates'**
  String get fxMarketClosed;

  /// No description provided for @fxStale.
  ///
  /// In en, this message translates to:
  /// **'Last known rates: data is old or the provider is unavailable.'**
  String get fxStale;

  /// No description provided for @fxRefreshNotice.
  ///
  /// In en, this message translates to:
  /// **'Refreshes every 60 seconds while this page is active. Free feed can be delayed by 15 minutes; daily reference and closed-market rates may be older.'**
  String get fxRefreshNotice;

  /// No description provided for @fxUnit.
  ///
  /// In en, this message translates to:
  /// **'EGP for 1 unit of foreign currency'**
  String get fxUnit;

  /// No description provided for @fxBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy (simulated)'**
  String get fxBuy;

  /// No description provided for @fxSell.
  ///
  /// In en, this message translates to:
  /// **'Sell (simulated)'**
  String get fxSell;

  /// No description provided for @fxMid.
  ///
  /// In en, this message translates to:
  /// **'Reference mid-rate'**
  String get fxMid;

  /// No description provided for @fxSource.
  ///
  /// In en, this message translates to:
  /// **'Observation source'**
  String get fxSource;

  /// No description provided for @fxAttribution.
  ///
  /// In en, this message translates to:
  /// **'Rates provided by exchangerate.dev ↗'**
  String get fxAttribution;

  /// No description provided for @fxUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currency rates are temporarily unavailable. Please retry.'**
  String get fxUnavailable;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD · US dollar'**
  String get currencyUsd;

  /// No description provided for @currencySar.
  ///
  /// In en, this message translates to:
  /// **'SAR · Saudi riyal'**
  String get currencySar;

  /// No description provided for @currencyEur.
  ///
  /// In en, this message translates to:
  /// **'EUR · Euro'**
  String get currencyEur;

  /// No description provided for @currencyAed.
  ///
  /// In en, this message translates to:
  /// **'AED · UAE dirham'**
  String get currencyAed;

  /// No description provided for @currencyGbp.
  ///
  /// In en, this message translates to:
  /// **'GBP · Pound sterling'**
  String get currencyGbp;

  /// No description provided for @currencyKwd.
  ///
  /// In en, this message translates to:
  /// **'KWD · Kuwaiti dinar'**
  String get currencyKwd;

  /// No description provided for @currencyQar.
  ///
  /// In en, this message translates to:
  /// **'QAR · Qatari riyal'**
  String get currencyQar;

  /// No description provided for @currencyChf.
  ///
  /// In en, this message translates to:
  /// **'CHF · Swiss franc'**
  String get currencyChf;

  /// No description provided for @certificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificatesTitle;

  /// No description provided for @investmentFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Investment funds'**
  String get investmentFundsTitle;

  /// No description provided for @myCertificates.
  ///
  /// In en, this message translates to:
  /// **'My certificates'**
  String get myCertificates;

  /// No description provided for @myFunds.
  ///
  /// In en, this message translates to:
  /// **'My fund holdings'**
  String get myFunds;

  /// No description provided for @fxSearch.
  ///
  /// In en, this message translates to:
  /// **'Search currency name or code'**
  String get fxSearch;

  /// No description provided for @fxAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fxAll;

  /// No description provided for @fxFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get fxFavorites;

  /// No description provided for @fxArabCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Arab currencies'**
  String get fxArabCurrencies;

  /// No description provided for @fxForeignCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Other currencies'**
  String get fxForeignCurrencies;

  /// No description provided for @fxFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get fxFavoriteAdd;

  /// No description provided for @fxFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get fxFavoriteRemove;

  /// No description provided for @fxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching currencies'**
  String get fxEmpty;

  /// No description provided for @fxEgpBase.
  ///
  /// In en, this message translates to:
  /// **'Egyptian pound · EGP'**
  String get fxEgpBase;

  /// No description provided for @fxDetails.
  ///
  /// In en, this message translates to:
  /// **'Rate details and source'**
  String get fxDetails;

  /// No description provided for @fxDayChangeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Daily change unavailable'**
  String get fxDayChangeUnavailable;

  /// No description provided for @otpDevelopmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No local code was issued for this number. For this demo, use the card of a customer who has not enrolled yet. Already enrolled customers should sign in.'**
  String get otpDevelopmentUnavailable;

  /// No description provided for @admSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review customer requests and publish bank notices'**
  String get admSubtitle;

  /// No description provided for @admAll.
  ///
  /// In en, this message translates to:
  /// **'All requests'**
  String get admAll;

  /// No description provided for @admSearch.
  ///
  /// In en, this message translates to:
  /// **'Search by request reference'**
  String get admSearch;

  /// No description provided for @admEmptyRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests match this filter'**
  String get admEmptyRequests;

  /// No description provided for @admLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get admLoadMore;

  /// No description provided for @admDetails.
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get admDetails;

  /// No description provided for @admCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get admCustomer;

  /// No description provided for @admHistory.
  ///
  /// In en, this message translates to:
  /// **'Request history'**
  String get admHistory;

  /// No description provided for @admDecisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Decision recorded and customer notified'**
  String get admDecisionSaved;

  /// No description provided for @admEmptyNotices.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get admEmptyNotices;

  /// No description provided for @admPublicEmpty.
  ///
  /// In en, this message translates to:
  /// **'No urgent notices at the moment'**
  String get admPublicEmpty;

  /// No description provided for @admPublicTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank notices'**
  String get admPublicTitle;

  /// No description provided for @admPublicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important updates before you sign in'**
  String get admPublicSubtitle;

  /// No description provided for @admLocation.
  ///
  /// In en, this message translates to:
  /// **'Display location'**
  String get admLocation;

  /// No description provided for @admHome.
  ///
  /// In en, this message translates to:
  /// **'Customer home'**
  String get admHome;

  /// No description provided for @admBeforeLogin.
  ///
  /// In en, this message translates to:
  /// **'Before sign-in'**
  String get admBeforeLogin;

  /// No description provided for @admBoth.
  ///
  /// In en, this message translates to:
  /// **'Home and before sign-in'**
  String get admBoth;

  /// No description provided for @admPublicPolicy.
  ///
  /// In en, this message translates to:
  /// **'Before-login notices are public to everyone or the selected bank, and contain no personal data.'**
  String get admPublicPolicy;

  /// No description provided for @admTitleEn.
  ///
  /// In en, this message translates to:
  /// **'English title'**
  String get admTitleEn;

  /// No description provided for @admTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic title'**
  String get admTitleAr;

  /// No description provided for @admBodyEn.
  ///
  /// In en, this message translates to:
  /// **'English message'**
  String get admBodyEn;

  /// No description provided for @admBodyAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic message'**
  String get admBodyAr;

  /// No description provided for @admRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters'**
  String get admRequired;

  /// No description provided for @admPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get admPriority;

  /// No description provided for @admDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get admDraft;

  /// No description provided for @admPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get admPublished;

  /// No description provided for @admArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get admArchived;

  /// No description provided for @admSaved.
  ///
  /// In en, this message translates to:
  /// **'Announcement saved'**
  String get admSaved;

  /// No description provided for @admEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit announcement'**
  String get admEdit;

  /// No description provided for @admPublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish this announcement to the selected location?'**
  String get admPublishConfirm;

  /// No description provided for @admArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive this announcement and remove it from customer screens?'**
  String get admArchiveConfirm;

  /// No description provided for @admDataEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get admDataEmail;

  /// No description provided for @admDataPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get admDataPhone;

  /// No description provided for @admDataAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get admDataAddress;

  /// No description provided for @admDataProduct.
  ///
  /// In en, this message translates to:
  /// **'Banking product'**
  String get admDataProduct;

  /// No description provided for @admDataAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get admDataAccount;

  /// No description provided for @admDataCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get admDataCurrency;

  /// No description provided for @admDataCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get admDataCard;

  /// No description provided for @admDataAmount.
  ///
  /// In en, this message translates to:
  /// **'Requested amount'**
  String get admDataAmount;

  /// No description provided for @admDataReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get admDataReason;

  /// No description provided for @cardApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a card'**
  String get cardApplyTitle;

  /// No description provided for @cardApplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your card and linked account. Bank approval is required.'**
  String get cardApplySubtitle;

  /// No description provided for @cardPreview.
  ///
  /// In en, this message translates to:
  /// **'DESIGN PREVIEW'**
  String get cardPreview;

  /// No description provided for @cardSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose this card'**
  String get cardSelect;

  /// No description provided for @cardSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected card'**
  String get cardSelected;

  /// No description provided for @cardChooseAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked account'**
  String get cardChooseAccount;

  /// No description provided for @cardInvestmentOnly.
  ///
  /// In en, this message translates to:
  /// **'Investment account in EGP'**
  String get cardInvestmentOnly;

  /// No description provided for @cardDomesticAccount.
  ///
  /// In en, this message translates to:
  /// **'Active EGP account'**
  String get cardDomesticAccount;

  /// No description provided for @cardForeignOnly.
  ///
  /// In en, this message translates to:
  /// **'USD, EUR or SAR accounts only'**
  String get cardForeignOnly;

  /// No description provided for @cardYouthOnly.
  ///
  /// In en, this message translates to:
  /// **'For customers under 21 with a verified date of birth'**
  String get cardYouthOnly;

  /// No description provided for @cardAgeUnverified.
  ///
  /// In en, this message translates to:
  /// **'A verified date of birth is required. Contact the bank to verify it.'**
  String get cardAgeUnverified;

  /// No description provided for @cardYouthAge.
  ///
  /// In en, this message translates to:
  /// **'Youth cards are available only to customers under 21.'**
  String get cardYouthAge;

  /// No description provided for @cardInvestmentRequired.
  ///
  /// In en, this message translates to:
  /// **'You need an active EGP investment account for this card.'**
  String get cardInvestmentRequired;

  /// No description provided for @cardForeignRequired.
  ///
  /// In en, this message translates to:
  /// **'You need an active USD, EUR or SAR account for this card.'**
  String get cardForeignRequired;

  /// No description provided for @cardAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'You need an eligible active EGP account.'**
  String get cardAccountRequired;

  /// No description provided for @cardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The card or customer is no longer eligible. Refresh and review the available options.'**
  String get cardUnavailable;

  /// No description provided for @cardOpenAccount.
  ///
  /// In en, this message translates to:
  /// **'Open Accounts'**
  String get cardOpenAccount;

  /// No description provided for @cardReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review card request'**
  String get cardReviewTitle;

  /// No description provided for @cardApprovalNotice.
  ///
  /// In en, this message translates to:
  /// **'Submitting creates a request only. The card is issued after an administrator approves it. Delivery and activation remain pending.'**
  String get cardApprovalNotice;

  /// No description provided for @cardAnnualFee.
  ///
  /// In en, this message translates to:
  /// **'Configured annual fee'**
  String get cardAnnualFee;

  /// No description provided for @cardSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm and submit request'**
  String get cardSubmitRequest;

  /// No description provided for @cardRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Request received — awaiting bank review'**
  String get cardRequestReceived;

  /// No description provided for @cardMyRequests.
  ///
  /// In en, this message translates to:
  /// **'My card requests'**
  String get cardMyRequests;

  /// No description provided for @cardRequestExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending card request. Follow its status below.'**
  String get cardRequestExists;

  /// No description provided for @cardNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No card requests yet'**
  String get cardNoRequests;

  /// No description provided for @cardProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Card category'**
  String get cardProductLabel;

  /// No description provided for @cardPendingActivation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting delivery and activation'**
  String get cardPendingActivation;

  /// No description provided for @cardBackCards.
  ///
  /// In en, this message translates to:
  /// **'Back to my cards'**
  String get cardBackCards;

  /// No description provided for @transferTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer type'**
  String get transferTypeLabel;

  /// No description provided for @transferOwnType.
  ///
  /// In en, this message translates to:
  /// **'Between my accounts'**
  String get transferOwnType;

  /// No description provided for @transferInternalType.
  ///
  /// In en, this message translates to:
  /// **'Within the same bank'**
  String get transferInternalType;

  /// No description provided for @transferDomesticType.
  ///
  /// In en, this message translates to:
  /// **'Other banks in Egypt'**
  String get transferDomesticType;

  /// No description provided for @transferInternationalType.
  ///
  /// In en, this message translates to:
  /// **'International transfer'**
  String get transferInternationalType;

  /// No description provided for @transferWalletType.
  ///
  /// In en, this message translates to:
  /// **'Mobile wallet'**
  String get transferWalletType;

  /// No description provided for @transferInstapayType.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get transferInstapayType;

  /// No description provided for @transferSimulationOnly.
  ///
  /// In en, this message translates to:
  /// **'Local simulation: your demo balance is debited. No payment is sent to a bank, wallet or InstaPay network.'**
  String get transferSimulationOnly;

  /// No description provided for @transferSameCurrency.
  ///
  /// In en, this message translates to:
  /// **'Uses the source account currency. Currency conversion is not available.'**
  String get transferSameCurrency;

  /// No description provided for @transferBankName.
  ///
  /// In en, this message translates to:
  /// **'Receiving bank name'**
  String get transferBankName;

  /// No description provided for @transferAccountOrIban.
  ///
  /// In en, this message translates to:
  /// **'Account number or IBAN'**
  String get transferAccountOrIban;

  /// No description provided for @transferCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code (for example US or SA)'**
  String get transferCountry;

  /// No description provided for @transferSwift.
  ///
  /// In en, this message translates to:
  /// **'SWIFT / BIC'**
  String get transferSwift;

  /// No description provided for @transferWalletNumber.
  ///
  /// In en, this message translates to:
  /// **'Egyptian wallet mobile number'**
  String get transferWalletNumber;

  /// No description provided for @transferIpa.
  ///
  /// In en, this message translates to:
  /// **'IPA address or Egyptian mobile'**
  String get transferIpa;

  /// No description provided for @transferIpaHint.
  ///
  /// In en, this message translates to:
  /// **'Example: fictionaluser@instapay'**
  String get transferIpaHint;

  /// No description provided for @transferDestinationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the recipient, account/mobile/IPA format, bank and currency.'**
  String get transferDestinationInvalid;

  /// No description provided for @transferProviderMissing.
  ///
  /// In en, this message translates to:
  /// **'This route has no configured delivery provider. No money has been debited.'**
  String get transferProviderMissing;

  /// No description provided for @transferUnavailableType.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get transferUnavailableType;

  /// No description provided for @transferSimulationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transfer simulation completed'**
  String get transferSimulationSuccess;

  /// No description provided for @transferProviderReference.
  ///
  /// In en, this message translates to:
  /// **'Simulation reference'**
  String get transferProviderReference;

  /// No description provided for @transferDeliveryFailure.
  ///
  /// In en, this message translates to:
  /// **'Delivery simulation failed. Refresh your balance and retry safely.'**
  String get transferDeliveryFailure;

  /// No description provided for @transferNoEligibleSource.
  ///
  /// In en, this message translates to:
  /// **'No eligible account for this type. Domestic, wallet and InstaPay transfers require EGP.'**
  String get transferNoEligibleSource;

  /// No description provided for @ownFxAvailable.
  ///
  /// In en, this message translates to:
  /// **'Currency conversion is available only between your own accounts.'**
  String get ownFxAvailable;

  /// No description provided for @ownFxRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate'**
  String get ownFxRate;

  /// No description provided for @ownFxReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get ownFxReceived;

  /// No description provided for @ownFxAsOf.
  ///
  /// In en, this message translates to:
  /// **'Market data as of'**
  String get ownFxAsOf;

  /// No description provided for @ownFxExpires.
  ///
  /// In en, this message translates to:
  /// **'Quote valid until'**
  String get ownFxExpires;

  /// No description provided for @ownFxSimulation.
  ///
  /// In en, this message translates to:
  /// **'Simulated exchange using indicative buy/sell prices and their spread, which may be delayed. This is not a real bank dealing quote.'**
  String get ownFxSimulation;

  /// No description provided for @ownFxExpired.
  ///
  /// In en, this message translates to:
  /// **'The exchange quote expired or was already used. Edit the transfer, review a new quote and authorize again.'**
  String get ownFxExpired;

  /// No description provided for @ownFxInvalid.
  ///
  /// In en, this message translates to:
  /// **'Obtain a new quote for the same customer, accounts and amount before authorizing.'**
  String get ownFxInvalid;

  /// No description provided for @ownFxAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'The amount received is too small or exceeds the supported balance range.'**
  String get ownFxAmountInvalid;

  /// No description provided for @publicWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your bank'**
  String get publicWelcomeTitle;

  /// No description provided for @publicWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your banking and support services, in one place.'**
  String get publicWelcomeSubtitle;

  /// No description provided for @publicBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get publicBranches;

  /// No description provided for @publicAtms.
  ///
  /// In en, this message translates to:
  /// **'ATMs'**
  String get publicAtms;

  /// No description provided for @publicCallCenter.
  ///
  /// In en, this message translates to:
  /// **'Call center'**
  String get publicCallCenter;

  /// No description provided for @publicSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Access your accounts'**
  String get publicSignInHint;

  /// No description provided for @publicBranchesHint.
  ///
  /// In en, this message translates to:
  /// **'Addresses and maps'**
  String get publicBranchesHint;

  /// No description provided for @publicAtmsHint.
  ///
  /// In en, this message translates to:
  /// **'Find an ATM'**
  String get publicAtmsHint;

  /// No description provided for @publicCallCenterHint.
  ///
  /// In en, this message translates to:
  /// **'We are here to help'**
  String get publicCallCenterHint;

  /// No description provided for @publicBranchSearch.
  ///
  /// In en, this message translates to:
  /// **'Search branch, area or address'**
  String get publicBranchSearch;

  /// No description provided for @publicGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get publicGovernorate;

  /// No description provided for @publicAllGovernorates.
  ///
  /// In en, this message translates to:
  /// **'All governorates'**
  String get publicAllGovernorates;

  /// No description provided for @publicResultCount.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get publicResultCount;

  /// No description provided for @publicDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No branches match your search. Try another area or governorate.'**
  String get publicDirectoryEmpty;

  /// No description provided for @publicDirectoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the branch directory. Please retry.'**
  String get publicDirectoryFailed;

  /// No description provided for @publicOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open location'**
  String get publicOpenMap;

  /// No description provided for @publicMapSearchNote.
  ///
  /// In en, this message translates to:
  /// **'Open the branch pin or search its name and address on the map.'**
  String get publicMapSearchNote;

  /// No description provided for @publicAtmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a cash machine'**
  String get publicAtmSubtitle;

  /// No description provided for @publicAtmNote.
  ///
  /// In en, this message translates to:
  /// **'Search for Faisal Bank ATMs on the map, or use the bank’s official branch and ATM locator.'**
  String get publicAtmNote;

  /// No description provided for @publicAtmArea.
  ///
  /// In en, this message translates to:
  /// **'City or area (optional)'**
  String get publicAtmArea;

  /// No description provided for @publicSearchAtm.
  ///
  /// In en, this message translates to:
  /// **'Search ATMs on map'**
  String get publicSearchAtm;

  /// No description provided for @publicOfficialLocator.
  ///
  /// In en, this message translates to:
  /// **'Official bank locator'**
  String get publicOfficialLocator;

  /// No description provided for @publicCallEgypt.
  ///
  /// In en, this message translates to:
  /// **'Hotline inside Egypt'**
  String get publicCallEgypt;

  /// No description provided for @publicHotlineAvailability.
  ///
  /// In en, this message translates to:
  /// **'Customer service is available 24 hours a day, 7 days a week.'**
  String get publicHotlineAvailability;

  /// No description provided for @publicCallAction.
  ///
  /// In en, this message translates to:
  /// **'Open dialer'**
  String get publicCallAction;

  /// No description provided for @publicCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get publicCopyNumber;

  /// No description provided for @publicNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get publicNumberCopied;

  /// No description provided for @publicOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Official bank website'**
  String get publicOfficialWebsite;

  /// No description provided for @publicLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link. Try again or use another maps app or browser.'**
  String get publicLinkFailed;

  /// No description provided for @brandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank appearance settings'**
  String get brandingTitle;

  /// No description provided for @brandingGeneral.
  ///
  /// In en, this message translates to:
  /// **'General branding'**
  String get brandingGeneral;

  /// No description provided for @brandingName.
  ///
  /// In en, this message translates to:
  /// **'Application display name'**
  String get brandingName;

  /// No description provided for @brandingShortName.
  ///
  /// In en, this message translates to:
  /// **'Application short name'**
  String get brandingShortName;

  /// No description provided for @brandingTagline.
  ///
  /// In en, this message translates to:
  /// **'Tagline (optional)'**
  String get brandingTagline;

  /// No description provided for @brandingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome message'**
  String get brandingWelcome;

  /// No description provided for @brandingOriginal.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the original localized text'**
  String get brandingOriginal;

  /// No description provided for @brandingLogo.
  ///
  /// In en, this message translates to:
  /// **'Application logo'**
  String get brandingLogo;

  /// No description provided for @brandingDarkLogo.
  ///
  /// In en, this message translates to:
  /// **'Dark mode logo'**
  String get brandingDarkLogo;

  /// No description provided for @brandingSplash.
  ///
  /// In en, this message translates to:
  /// **'In-app splash image'**
  String get brandingSplash;

  /// No description provided for @brandingUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get brandingUpload;

  /// No description provided for @brandingRemove.
  ///
  /// In en, this message translates to:
  /// **'Use default asset'**
  String get brandingRemove;

  /// No description provided for @brandingUploadHelp.
  ///
  /// In en, this message translates to:
  /// **'PNG/JPEG • maximum 2 MB • 16–4096 px per side • up to 4 megapixels. Aspect ratio is preserved.'**
  String get brandingUploadHelp;

  /// No description provided for @brandingColors.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get brandingColors;

  /// No description provided for @brandingCustomTheme.
  ///
  /// In en, this message translates to:
  /// **'Customize the theme'**
  String get brandingCustomTheme;

  /// No description provided for @brandingLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get brandingLight;

  /// No description provided for @brandingDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get brandingDark;

  /// No description provided for @brandingPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get brandingPrimary;

  /// No description provided for @brandingSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary color'**
  String get brandingSecondary;

  /// No description provided for @brandingAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get brandingAccent;

  /// No description provided for @brandingBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get brandingBackground;

  /// No description provided for @brandingSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get brandingSurface;

  /// No description provided for @brandingTextPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary text'**
  String get brandingTextPrimary;

  /// No description provided for @brandingTextSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary text'**
  String get brandingTextSecondary;

  /// No description provided for @brandingError.
  ///
  /// In en, this message translates to:
  /// **'Error color'**
  String get brandingError;

  /// No description provided for @brandingButtonBackground.
  ///
  /// In en, this message translates to:
  /// **'Button background'**
  String get brandingButtonBackground;

  /// No description provided for @brandingButtonText.
  ///
  /// In en, this message translates to:
  /// **'Button text'**
  String get brandingButtonText;

  /// No description provided for @brandingCard.
  ///
  /// In en, this message translates to:
  /// **'Card background'**
  String get brandingCard;

  /// No description provided for @brandingBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get brandingBorder;

  /// No description provided for @brandingTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get brandingTypography;

  /// No description provided for @brandingPrimaryFont.
  ///
  /// In en, this message translates to:
  /// **'Primary font family'**
  String get brandingPrimaryFont;

  /// No description provided for @brandingArabicFont.
  ///
  /// In en, this message translates to:
  /// **'Arabic font family'**
  String get brandingArabicFont;

  /// No description provided for @brandingEnglishFont.
  ///
  /// In en, this message translates to:
  /// **'English font family'**
  String get brandingEnglishFont;

  /// No description provided for @brandingScale.
  ///
  /// In en, this message translates to:
  /// **'Font size scale'**
  String get brandingScale;

  /// No description provided for @brandingHeadingWeight.
  ///
  /// In en, this message translates to:
  /// **'Heading weight'**
  String get brandingHeadingWeight;

  /// No description provided for @brandingBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get brandingBodyWeight;

  /// No description provided for @brandingMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance policy'**
  String get brandingMode;

  /// No description provided for @brandingUserMode.
  ///
  /// In en, this message translates to:
  /// **'Keep customer choice'**
  String get brandingUserMode;

  /// No description provided for @brandingSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get brandingSystem;

  /// No description provided for @brandingPreview.
  ///
  /// In en, this message translates to:
  /// **'Live preview — only visible here'**
  String get brandingPreview;

  /// No description provided for @brandingPreviewCard.
  ///
  /// In en, this message translates to:
  /// **'Example account card'**
  String get brandingPreviewCard;

  /// No description provided for @brandingPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Secure banking at your fingertips'**
  String get brandingPreviewBody;

  /// No description provided for @brandingSave.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get brandingSave;

  /// No description provided for @brandingPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish changes'**
  String get brandingPublish;

  /// No description provided for @brandingDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore original branding as draft'**
  String get brandingDefaults;

  /// No description provided for @brandingHistory.
  ///
  /// In en, this message translates to:
  /// **'Published configuration history'**
  String get brandingHistory;

  /// No description provided for @brandingRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore as draft'**
  String get brandingRestore;

  /// No description provided for @brandingNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No custom configuration has been published.'**
  String get brandingNoHistory;

  /// No description provided for @brandingDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Save a draft and explicitly publish to update customer screens. Connected clients refresh on foreground resume; no new app download is needed for supported internal settings.'**
  String get brandingDraftNotice;

  /// No description provided for @brandingSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved. Live branding is unchanged.'**
  String get brandingSaved;

  /// No description provided for @brandingPublished.
  ///
  /// In en, this message translates to:
  /// **'Branding published successfully.'**
  String get brandingPublished;

  /// No description provided for @brandingRestored.
  ///
  /// In en, this message translates to:
  /// **'Configuration restored as a draft. Review and publish to apply.'**
  String get brandingRestored;

  /// No description provided for @brandingUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded. Save the draft to keep this selection.'**
  String get brandingUploaded;

  /// No description provided for @brandingConflict.
  ///
  /// In en, this message translates to:
  /// **'Another administrator changed these settings. Your edits are preserved; reload to review the latest version.'**
  String get brandingConflict;

  /// No description provided for @brandingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the internal text, supported fonts and size scale. The preview keeps the last valid appearance.'**
  String get brandingInvalid;

  /// No description provided for @brandingRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed. Your edits are preserved; try again.'**
  String get brandingRequestFailed;

  /// No description provided for @brandingSaveFirst.
  ///
  /// In en, this message translates to:
  /// **'Save a valid draft before publishing.'**
  String get brandingSaveFirst;

  /// No description provided for @brandingHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history. Reload to try again.'**
  String get brandingHistoryFailed;

  /// No description provided for @brandingPublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish the saved internal appearance changes for the affected banks?'**
  String get brandingPublishConfirm;

  /// No description provided for @brandingReloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reload and replace your unsaved edits?'**
  String get brandingReloadConfirm;

  /// No description provided for @brandingReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the current draft? This will not publish anything.'**
  String get brandingReplaceConfirm;

  /// No description provided for @brandingUnsaved.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved edits.'**
  String get brandingUnsaved;

  /// No description provided for @brandingNative.
  ///
  /// In en, this message translates to:
  /// **'Native launcher branding'**
  String get brandingNative;

  /// No description provided for @brandingReleaseRequired.
  ///
  /// In en, this message translates to:
  /// **'Requires New Application Release'**
  String get brandingReleaseRequired;

  /// No description provided for @brandingNativeHelp.
  ///
  /// In en, this message translates to:
  /// **'Launcher labels and icons are fixed in the application release. Changes require a new release. These controls only affect in-app appearance.'**
  String get brandingNativeHelp;

  /// No description provided for @brandingHex.
  ///
  /// In en, this message translates to:
  /// **'HEX color (#RRGGBB)'**
  String get brandingHex;

  /// No description provided for @brandingHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get brandingHue;

  /// No description provided for @brandingSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get brandingSaturation;

  /// No description provided for @brandingBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brandingBrightness;

  /// No description provided for @brandingVersion.
  ///
  /// In en, this message translates to:
  /// **'Published version'**
  String get brandingVersion;

  /// No description provided for @brandingMoreHistory.
  ///
  /// In en, this message translates to:
  /// **'Load older versions'**
  String get brandingMoreHistory;

  /// No description provided for @brandingSystemFont.
  ///
  /// In en, this message translates to:
  /// **'Original system font'**
  String get brandingSystemFont;

  /// No description provided for @bankSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankSelectionLabel;

  /// No description provided for @bankSelectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose your card’s bank.'**
  String get bankSelectionRequired;

  /// No description provided for @bankRegistrationHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the bank of your provisioned development card. Verification uses the contact already registered for that customer; selecting a bank never changes card ownership.'**
  String get bankRegistrationHelp;

  /// No description provided for @bankFixedIdentity.
  ///
  /// In en, this message translates to:
  /// **'Fixed application identity'**
  String get bankFixedIdentity;

  /// No description provided for @bankFixedIdentityHelp.
  ///
  /// In en, this message translates to:
  /// **'Bank names and official logos follow the selected bank. These settings change supported in-app appearance, not the native launcher.'**
  String get bankFixedIdentityHelp;

  /// No description provided for @bankAppearanceScope.
  ///
  /// In en, this message translates to:
  /// **'Edits apply to customers registered with the selected bank. Other banks and the fixed application identity stay independent.'**
  String get bankAppearanceScope;

  /// No description provided for @bankPresetColors.
  ///
  /// In en, this message translates to:
  /// **'Bank color preset'**
  String get bankPresetColors;

  /// No description provided for @bankPresetHelp.
  ///
  /// In en, this message translates to:
  /// **'This read-only palette is inspired by the bank’s identity and adjusted for accessible text contrast. Colors cannot be replaced with arbitrary values.'**
  String get bankPresetHelp;

  /// No description provided for @bankInternalContent.
  ///
  /// In en, this message translates to:
  /// **'Content inside customer accounts'**
  String get bankInternalContent;

  /// No description provided for @bankInternalCaption.
  ///
  /// In en, this message translates to:
  /// **'Internal caption (optional)'**
  String get bankInternalCaption;

  /// No description provided for @bankRestorePreset.
  ///
  /// In en, this message translates to:
  /// **'Restore this bank’s defaults as draft'**
  String get bankRestorePreset;

  /// No description provided for @bankDirectoryNote.
  ///
  /// In en, this message translates to:
  /// **'The bundled street-address directory belongs to Faisal Bank only. For other banks, use the verified official website; no unverified addresses or hotlines are shown.'**
  String get bankDirectoryNote;

  /// No description provided for @bankOfficialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open official bank website'**
  String get bankOfficialWebsite;

  /// No description provided for @bankServiceChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a bank for this service.'**
  String get bankServiceChoose;

  /// No description provided for @bankLinkedBank.
  ///
  /// In en, this message translates to:
  /// **'Registered bank'**
  String get bankLinkedBank;

  /// No description provided for @bankLoginSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank (optional for sign-in)'**
  String get bankLoginSelectionLabel;

  /// No description provided for @bankLoginAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Detect from username or card'**
  String get bankLoginAutomatic;

  /// No description provided for @bankLoginSelectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the bank for this username/card, or leave automatic. Each successful sign-in uses the bank verified by the server. Administrators sign in without choosing a bank.'**
  String get bankLoginSelectionHelp;

  /// No description provided for @bankIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your banks, in one place'**
  String get bankIntroTitle;

  /// No description provided for @bankIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your bank to access its services with its own familiar identity. Switch banks whenever you need to.'**
  String get bankIntroBody;

  /// No description provided for @bankSecurityIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your identity stays with your bank'**
  String get bankSecurityIntroTitle;

  /// No description provided for @bankSecurityIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in using your bank username. New here? Verify your card with a one-time code, then create a username and password.'**
  String get bankSecurityIntroBody;

  /// No description provided for @bankChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your bank'**
  String get bankChooseTitle;

  /// No description provided for @bankChooseBody.
  ///
  /// In en, this message translates to:
  /// **'Your login, branches, ATMs and customer service will follow this selection.'**
  String get bankChooseBody;

  /// No description provided for @bankSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search banks'**
  String get bankSearchLabel;

  /// No description provided for @bankChangeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change bank'**
  String get bankChangeSelection;

  /// No description provided for @bankNoticeSpecific.
  ///
  /// In en, this message translates to:
  /// **'Notice for a specific bank'**
  String get bankNoticeSpecific;

  /// No description provided for @bankDirectoryReviewed.
  ///
  /// In en, this message translates to:
  /// **'Source reviewed'**
  String get bankDirectoryReviewed;

  /// No description provided for @bankDirectoryPartial.
  ///
  /// In en, this message translates to:
  /// **'This is a verified subset of the bank’s published locations. See the official locator for the full current network.'**
  String get bankDirectoryPartial;

  /// No description provided for @bankDirectoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A verified address list is not available here yet. Use this bank’s official locator; another bank’s locations are never substituted.'**
  String get bankDirectoryUnavailable;

  /// No description provided for @bankContactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A customer service number has not been verified here yet. Use this bank’s official contact website.'**
  String get bankContactUnavailable;

  /// No description provided for @savedBanksTitle.
  ///
  /// In en, this message translates to:
  /// **'My banks'**
  String get savedBanksTitle;

  /// No description provided for @savedBanksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an account you signed in to on this device.'**
  String get savedBanksSubtitle;

  /// No description provided for @savedBanksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a new bank'**
  String get savedBanksAdd;

  /// No description provided for @savedBanksUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get savedBanksUsePassword;

  /// No description provided for @savedBanksPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Passwords are never saved. Biometric sign-in requires an active bank session; expired or revoked sessions require your password again.'**
  String get savedBanksPrivacy;

  /// No description provided for @savedBanksBiometricRetry.
  ///
  /// In en, this message translates to:
  /// **'Biometric verification was not completed. Try again or sign in with your password.'**
  String get savedBanksBiometricRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
