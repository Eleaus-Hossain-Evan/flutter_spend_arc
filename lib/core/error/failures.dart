import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List<Object?> properties = const <Object?>[]]);

  @override
  List<Object?> get props => [];
}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

class NotFoundFailure extends Failure {
  final String message;

  const NotFoundFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {}

class InvalidInputFailure extends Failure {}

class AuthenticationFailure extends Failure {}

class UnknownFailure extends Failure {
  final String? message;

  const UnknownFailure([this.message]);

  @override
  List<Object?> get props => [message];
}
