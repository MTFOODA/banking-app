class RegistrationChallenge {
  const RegistrationChallenge({
    required this.reference,
    required this.contact,
    required this.resendAfter,
    required this.development,
    this.developmentCode,
  });
  final String reference;
  final String contact;
  final int resendAfter;
  final bool development;
  final String? developmentCode;
}

class AuthorizationCredential {
  const AuthorizationCredential(this.token, this.expiresIn);
  final String token;
  final int expiresIn;
}

class UsernameAvailability {
  const UsernameAvailability(this.username, this.available, this.suggestions);
  final String username;
  final bool available;
  final List<String> suggestions;
}
