enum FailureCode {
  validation,
  unauthorized,
  invalidTransition,
  notFound,
  conflict,
  storage,
  corruption,
  unsupportedSchema,
  privacy,
}

final class DomainFailure extends Error {
  DomainFailure({
    required this.code,
    required this.message,
    this.field,
    this.retryable = false,
  });

  final FailureCode code;
  final String message;
  final String? field;
  final bool retryable;

  @override
  String toString() => 'DomainFailure($code, $message, field: $field)';
}

Never fail(
  FailureCode code,
  String message, {
  String? field,
  bool retryable = false,
}) {
  throw DomainFailure(
    code: code,
    message: message,
    field: field,
    retryable: retryable,
  );
}

