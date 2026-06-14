class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error']);
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication failed']);
}

class AccountSetupException implements Exception {
  final String message;
  const AccountSetupException([this.message = 'Account setup failed']);
}

class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Permission denied']);
}

class FileException implements Exception {
  final String message;
  const FileException([this.message = 'File error']);
}
