import 'package:dartz/dartz.dart';
import 'package:soundora/data/models/auth/create_user_req.dart';
import 'package:soundora/data/models/auth/signin_req.dart';

abstract class AuthRepo {
  Future<Either> signUp(CreateUserReq createUserReq);
  Future<Either> signIn(SigninReq signinReq);
}
