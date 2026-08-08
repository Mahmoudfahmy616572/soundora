import 'package:dartz/dartz.dart';
import 'package:soundora/domain/repositories/otp/otp_repo.dart';
import 'package:soundora/domain/usecase/usecase.dart';
import 'package:soundora/serviece_locator.dart';

class SendOtpUsecase implements Usecase<Either, String> {
  @override
  Future<Either> call({String? param}) async {
    if (param == null || param.isEmpty) {
      return const Left("Email is required.");
    }
    try {
      final result = await getIt<OtpRepository>().sendOtp(email: param);
      if (result) {
        return const Right("OTP sent successfully");
      } else {
        return const Left("Failed to send OTP. Please try again.");
      }
    } catch (e) {
      return Left("Error: $e");
    }
  }
}

class VerifyOtpUsecase implements Usecase<Either, Map<String, String>> {
  @override
  Future<Either> call({Map<String, String>? param}) async {
    if (param == null) {
      return const Left("Invalid parameters.");
    }
    try {
      final email = param['email'];
      final inputOtp = param['inputOtp'];
      if (email == null || inputOtp == null) {
        return const Left("Missing email or OTP code.");
      }
      final repo = getIt<OtpRepository>();
      final correctOtp = (repo as dynamic).getStoredOtp(email);

      if (correctOtp == null) {
        return const Left("OTP expired. Please request a new one.");
      }

      final isVerified = repo.verifyOtp(
          inputOtp: inputOtp, correctOtp: correctOtp);

      if (isVerified) {
        (repo as dynamic).clearOtp(email);
        return const Right("OTP verified successfully");
      } else {
        return const Left("Invalid OTP. Please try again.");
      }
    } catch (e) {
      return Left("Error: $e");
    }
  }
}
