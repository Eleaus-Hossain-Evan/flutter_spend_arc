class CacheException implements Exception {
  final String? message;

  const CacheException([this.message]);

  @override
  String toString() => 'CacheException: ${message ?? "Cache error occurred"}';
}

class NetworkException implements Exception {
  final String? message;

  const NetworkException([this.message]);

  @override
  String toString() =>
      'NetworkException: ${message ?? "Network error occurred"}';
}

class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  const ServerException([this.message, this.statusCode]);

  @override
  String toString() =>
      'ServerException: ${message ?? "Server error"} (code: $statusCode)';
}

class NotFoundException implements Exception {
  final String? message;

  const NotFoundException([this.message]);

  @override
  String toString() => 'NotFoundException: ${message ?? "Resource not found"}';
}

class InvalidInputException implements Exception {
  final String? message;

  const InvalidInputException([this.message]);

  @override
  String toString() =>
      'InvalidInputException: ${message ?? "Invalid input provided"}';
}
