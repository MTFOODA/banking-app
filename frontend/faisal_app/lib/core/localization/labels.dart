import '../../l10n/app_localizations.dart';

/// Centralized enum-to-label mapping so screens never hardcode English text.
String requestStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'draft' => l10n.statusDraft,
      'submitted' => l10n.statusSubmitted,
      'under_review' => l10n.statusUnderReview,
      'pending_customer_info' => l10n.statusPendingCustomerInfo,
      'pending_approval' => l10n.statusPendingApproval,
      'approved' => l10n.statusApproved,
      'rejected' => l10n.statusRejected,
      'processing' => l10n.statusProcessing,
      'completed' => l10n.statusCompleted,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };

String requestTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'account_open' => l10n.requestTypeAccountOpen,
  'account_close' => l10n.requestTypeAccountClose,
  'card_replacement' => l10n.requestTypeCardReplacement,
  'card_renewal' => l10n.requestTypeCardRenewal,
  'card_cancellation' => l10n.requestTypeCardCancellation,
  'card_limit_increase' => l10n.requestTypeLimitIncrease,
  'card_limit_decrease' => l10n.requestTypeLimitDecrease,
  'pin_reset' => l10n.requestTypePinReset,
  'supplementary_card' => l10n.requestTypeSupplementary,
  'credit_card_application' => l10n.requestTypeCreditCard,
  'investment_product' => l10n.requestTypeInvestment,
  'customer_info_update' => l10n.requestTypeInfoUpdate,
  _ => l10n.requestTypeOther,
};

String cardStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'active' => l10n.cardStatusActive,
      'frozen' => l10n.cardStatusFrozen,
      'lost' => l10n.cardStatusLost,
      'stolen' => l10n.cardStatusStolen,
      'blocked' => l10n.cardStatusBlocked,
      'cancelled' => l10n.cardStatusCancelled,
      'pending_activation' => l10n.cardStatusPendingActivation,
      'expired' => l10n.cardStatusExpired,
      _ => status,
    };

String transactionTypeLabel(AppLocalizations l10n, String type) =>
    switch (type) {
      'transfer' => l10n.transactionTypeTransfer,
      'deposit' => l10n.transactionTypeDeposit,
      'withdrawal' => l10n.transactionTypeWithdrawal,
      'purchase' => l10n.transactionTypePurchase,
      'bill_payment' => l10n.transactionTypeBillPayment,
      'card_repayment' => l10n.transactionTypeCardRepayment,
      'fee' => l10n.transactionTypeFee,
      'adjustment' => l10n.transactionTypeAdjustment,
      'salary' => l10n.transactionTypeSalary,
      _ => type,
    };

String transactionStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'posted' => l10n.transactionStatusPosted,
      'pending' => l10n.transactionStatusPending,
      'failed' => l10n.transactionStatusFailed,
      'reversed' => l10n.transactionStatusReversed,
      _ => status,
    };

String accountTypeLabel(AppLocalizations l10n, String type) => switch (type) {
  'current' => l10n.accountTypeCurrent,
  'investment' => l10n.accountTypeInvestment,
  'savings' => l10n.accountTypeSavings,
  _ => l10n.accountTypeOther,
};

String priorityLabel(AppLocalizations l10n, String priority) =>
    switch (priority) {
      'low' => l10n.priorityLow,
      'high' => l10n.priorityHigh,
      _ => l10n.priorityNormal,
    };

String repaymentModeLabel(AppLocalizations l10n, String mode) => switch (mode) {
  'full' => l10n.optionFullBalance,
  'statement' => l10n.optionStatementBalance,
  'minimum' => l10n.optionMinimumPayment,
  _ => l10n.optionCustomAmount,
};
