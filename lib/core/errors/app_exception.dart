class AppException implements Exception {
  final String userMessage;
  final String? debugMessage;

  const AppException(this.userMessage, {this.debugMessage});

  @override
  String toString() => userMessage;
}
