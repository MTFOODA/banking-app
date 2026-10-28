/// The authoritative password policy is enforced by the backend; this mirror
/// powers live feedback in the UI.
enum PasswordRequirement {
  minLength,
  uppercase,
  lowercase,
  digit,
  special,
  noTripleRepeat,
}

class PasswordEvaluation {
  const PasswordEvaluation({
    required this.failed,
    required this.satisfied,
    required this.score,
  });

  final Set<PasswordRequirement> failed;
  final Set<PasswordRequirement> satisfied;
  final int score;

  bool get isValid => failed.isEmpty;

  /// 0..4 used by the strength meter.
  int get strength => score;
}

const String _specialCharacters = r'''!@#$%^&*()_+-=[]{};:'",.<>/?\|`~''';
const int minPasswordLength = 8;
const int maxPasswordLength = 128;

PasswordEvaluation evaluatePassword(String value) {
  final failed = <PasswordRequirement>{};
  final satisfied = <PasswordRequirement>{};

  void check(PasswordRequirement requirement, bool passed) {
    if (passed) {
      satisfied.add(requirement);
    } else {
      failed.add(requirement);
    }
  }

  check(
    PasswordRequirement.minLength,
    value.length >= minPasswordLength && value.length <= maxPasswordLength,
  );
  check(PasswordRequirement.uppercase, RegExp(r'[A-Z]').hasMatch(value));
  check(PasswordRequirement.lowercase, RegExp(r'[a-z]').hasMatch(value));
  check(PasswordRequirement.digit, RegExp(r'[0-9]').hasMatch(value));
  check(
    PasswordRequirement.special,
    value.split('').any(_specialCharacters.contains),
  );
  check(
    PasswordRequirement.noTripleRepeat,
    !RegExp(r'(.)\1\1').hasMatch(value),
  );

  var score = 0;
  if (value.length >= minPasswordLength) {
    score += 1;
  }
  if (value.length >= 12) {
    score += 1;
  }
  if (satisfied.contains(PasswordRequirement.uppercase) &&
      satisfied.contains(PasswordRequirement.lowercase)) {
    score += 1;
  }
  if (satisfied.contains(PasswordRequirement.special) && failed.isEmpty) {
    score += 1;
  }
  return PasswordEvaluation(
    failed: failed,
    satisfied: satisfied,
    score: score.clamp(0, 4),
  );
}

bool passwordsMatch(String password, String confirmation) =>
    password.isNotEmpty && password == confirmation;

/// Validation used by forms before submitting to the API.
/// Validates a customer sign-in identifier.
///
/// Accepts a newly enrolled username or an existing numeric card/account
/// identifier. The backend resolves ownership using the same login endpoint.
String? validateLoginIdentifier(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]{2,29}$').hasMatch(value.trim())) {
    return null;
  }
  if (digits.length < 8) {
    return 'invalid';
  }
  return null;
}

String? validatePasswordField(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }
  return null;
}

String? validateAmountField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  if (parsed == null) {
    return 'invalid';
  }
  if (parsed <= 0) {
    return 'positive';
  }
  return null;
}

String? validateEmailField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return pattern.hasMatch(value.trim()) ? null : 'invalid';
}
