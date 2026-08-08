import 'package:dartz/dartz.dart';
import 'package:soundora/core/usecase/usecase.dart';
import 'package:soundora/data/models/auth/signin_req.dart';
import 'package:soundora/domain/repositories/auth/auth_repo.dart';
import 'package:soundora/serviece_locator.dart';

class SigninUsecase implements Usecase<Either, SigninReq> {
  @override
  Future<Either> call({SigninReq? param}) {
    if (param == null) {
      return Future.value(const Left("Missing sign-in credentials."));
    }
    return getIt<AuthRepo>().signIn(param);
  }
}
