/// Route paths used across the app.
class AppRoutes {
  const AppRoutes._();

  static const String onboarding = '/choose-bank';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String preLogin = '/bank-notices';
  static const String branches = '/branches';
  static const String atms = '/atms';
  static const String callCenter = '/call-center';
  static const String announcementDetails = '/announcements/:announcementId';
  static const String passwordSetup = '/first-login/password-setup';
  static const String forgotPassword = '/forgot-password';
  static const String registration = '/register';
  static const String passwordChange = '/profile/change-password';

  static const String home = '/home';
  static const String accounts = '/accounts';
  static const String accountCertificates = '/accounts?section=certificates';
  static const String accountFunds = '/accounts?section=funds';
  static const String accountDetails = '/accounts/:accountId';
  static const String accountTransactions = '/accounts/:accountId/transactions';
  static const String cards = '/cards';
  static const String cardApplication = '/cards/apply';
  static const String cardDetails = '/cards/:cardId';
  static const String cardTransactions = '/cards/:cardId/transactions';
  static const String transactions = '/transactions';
  static const String transfers = '/transfers';
  static const String payments = '/payments';
  static const String repayments = '/repayments';
  static const String requests = '/requests';
  static const String requestDetails = '/requests/:requestId';
  static const String notifications = '/notifications';
  static const String products = '/products';
  static const String exchangeRates = '/exchange-rates';
  static const String productDetails = '/products/:productId';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String more = '/more';
  static const String admin = '/admin';
  static const String adminSettings = '/admin/settings';
  static const String adminBranding = '/admin/settings/branding';
  static const String adminRequests = '/admin/requests';
  static const String adminRequestDetails = '/admin/requests/:requestId';
  static const String adminCustomers = '/admin/customers';
  static const String adminCustomerDetails = '/admin/customers/:customerId';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminProducts = '/admin/products';
  static const String adminAuditLogs = '/admin/audit-logs';

  static String account(String id) => '/accounts/$id';
  static String accountTransactionHistory(String id) =>
      '/accounts/$id/transactions';
  static String card(String id) => '/cards/$id';
  static String cardTransactionHistory(String id) => '/cards/$id/transactions';
  static String request(String id) => '/requests/$id';
  static String adminRequest(String id) => '/admin/requests/$id';
  static String adminCustomer(String id) => '/admin/customers/$id';
  static String product(String id) => '/products/$id';
}
