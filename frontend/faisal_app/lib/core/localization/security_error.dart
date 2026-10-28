import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';
import '../network/api_error_mapper.dart';

String securityError(AppLocalizations l, AppException error) {
  final code = serverErrorCode(error);
  return switch (code) {
    'username_taken' => l.usernameTaken,
    'fx_quote_expired' || 'fx_quote_used' => l.ownFxExpired,
    'invalid_fx_quote' || 'fx_quote_required' => l.ownFxInvalid,
    'fx_amount_invalid' => l.ownFxAmountInvalid,
    'transfer_provider_unavailable' => l.transferProviderMissing,
    'transfer_delivery_failed' => l.transferDeliveryFailure,
    'card_age_unverified' => l.cardAgeUnverified,
    'card_youth_age' => l.cardYouthAge,
    'card_fx_account_required' => l.cardForeignRequired,
    'card_investment_required' => l.cardInvestmentRequired,
    'card_eligible_account_required' => l.cardAccountRequired,
    'card_product_unavailable' ||
    'card_customer_ineligible' => l.cardUnavailable,
    'invalid_username' => l.usernameInvalid,
    'investment_amount' => l.investmentAmountError,
    'investment_unavailable' ||
    'investment_not_found' ||
    'investment_redeemed' => l.investmentUnavailable,
    'fx_unavailable' => l.fxUnavailable,
    'invalid_otp' => l.otpIncorrect,
    'otp_expired' => l.otpExpired,
    'otp_used' => l.otpUsed,
    'otp_attempts_exceeded' => l.otpAttemptsExceeded,
    'otp_cooldown' || 'rate_limited' => l.errorRateLimited,
    'authorization_expired' => l.authorizationExpired,
    'authorization_used' => l.authorizationUsed,
    'invalid_authorization' ||
    'authorization_required' => l.authorizationInvalid,
    'invalid_credentials' => l.currentPasswordIncorrect,
    'insufficient_funds' => l.transferBalanceError,
    'destination_unsupported' => l.internalTransferOnly,
    'password_policy_violation' => l.passwordPolicyError,
    'password_mismatch' => l.passwordMismatch,
    'duplicate_open_request' => l.profileRequestExists,
    _ => switch (error.code) {
      AppErrorCode.network => l.errorNetwork,
      AppErrorCode.timeout => l.errorTimeout,
      AppErrorCode.unauthorized => l.errorUnauthorized,
      AppErrorCode.rateLimited => l.errorRateLimited,
      _ => l.securityOperationError,
    },
  };
}
