import 'package:dartz/dartz.dart';
import 'package:soundora/core/usecase/usecase.dart';
import 'package:soundora/data/models/auth/create_user_req.dart';
import 'package:soundora/domain/repositories/auth/auth_repo.dart';
import 'package:soundora/serviece_locator.dart';

class SighnupUsecase implements Usecase<Either, CreateUserReq> {
  @override
  Future<Either> call({CreateUserReq? param}) {
    if (param == null) {
      return Future.value(const Left("Missing registration data."));
    }
    return getIt<AuthRepo>().signUp(param);
  }
}
