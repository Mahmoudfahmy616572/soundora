import 'package:dartz/dartz.dart';
import 'package:soundora/data/sources/auth/auth_supabase_servieces.dart';
import 'package:soundora/domain/repositories/auth/auth_repo.dart';
import 'package:soundora/serviece_locator.dart';

class AuthRepoImpl implements AuthRepo {
  @override
  Future<Either> signIn(signinReq) async {
    return await getIt<AuthSupabaseServieces>().signIn(signinReq);
  }

  @override
  Future<Either> signUp(createUserReq) async {
    return await getIt<AuthSupabaseServieces>().signUp(createUserReq);
  }
}
