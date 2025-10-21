class UsernameValidationResult {
  final bool isValid;
  final String? errorMessage;
  final UsernameValidationError? errorType;

  const UsernameValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });

  static const UsernameValidationResult valid = UsernameValidationResult(isValid: true);

  static UsernameValidationResult invalid(String message, UsernameValidationError type) {
    return UsernameValidationResult(
      isValid: false,
      errorMessage: message,
      errorType: type,
    );
  }
}

enum UsernameValidationError {
  tooShort,
  tooLong,
  invalidCharacters,
  startsWithNumber,
  consecutiveUnderscores,
  unavailable,
  networkError,
}