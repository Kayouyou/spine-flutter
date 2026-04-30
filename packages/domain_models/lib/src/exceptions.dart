// 用户名不存在，还未注册
class DomainException implements Exception {
  final int code;
  final String message;
  DomainException({required this.code, required this.message});
}

class UserNameIsNotRegisterException implements Exception {}

class UserNameIsRegisterException implements Exception {}

class InvalidCredentialsException implements Exception {
  final int code;
  final String message;
  InvalidCredentialsException(this.code, this.message);
}

class EmptySearchResultException implements Exception {}

class UserAuthenticationRequiredException implements Exception {}

class UsernameAlreadyTakenException implements Exception {}

class EmailAlreadyRegisteredException implements Exception {}
