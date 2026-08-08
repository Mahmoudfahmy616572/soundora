import 'package:dartz/dartz.dart';
import 'package:soundora/data/models/auth/create_user_req.dart';
import 'package:soundora/data/models/auth/signin_req.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthSupabaseServieces {
  Future<Either> signUp(CreateUserReq createUserReq);
  Future<Either> signIn(SigninReq signinReq);
}

class AuthSupabaseServiecesImpl implements AuthSupabaseServieces {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Either> signUp(createUserReq) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: createUserReq.email,
        password: createUserReq.password,
        data: {'Full_name': createUserReq.username},
      );

      if (res.user != null) {
        await _supabase.from('Users').insert(
          {
            'id': res.user!.id,
            'username': res.user?.userMetadata?["Full_name"],
            'email': res.user?.email,
          },
        );
      }

      final User? user = res.user;

      if (user != null) {
        return const Right(
            "Account Created! Check your email for verification if enabled.");
      }
    } on AuthException catch (e) {
      if (e.code == 'email_exists') {
        return const Left('This email is already registered. Please log in.');
      } else {
        return Left(e.message);
      }
    } catch (e) {
      return left("An unexpected error occurred: $e");
    }
    return left("error");
  }

  @override
  Future<Either> signIn(signinReq) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: signinReq.email,
        password: signinReq.password,
      );

      if (res.user != null) {
        return Right('Login successful: ${res.user!.email}');
      }
    } on AuthException catch (error) {
      if (error.code == 'invalid_credentials') {
        return const Left('Wrong email or password.');
      } else if (error.code == 'email_not_confirmed') {
        return const Left('Please verify your email before logging in.');
      } else if (error.code == 'too_many_requests') {
        return const Left('Too many attempts. Please wait a moment.');
      } else {
        return Left('Login failed:${error.message}');
      }
    }
    return const Left("Unknown Error");
  }
}
