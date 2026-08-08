import 'dart:math';
import 'package:soundora/data/sources/otp/otp_data_source.dart';
import 'package:soundora/domain/repositories/otp/otp_repo.dart';

class OtpRepositoryImpl implements OtpRepository {
  final OtpDataSource _otpDataSource;
  final Map<String, String> _otpStore = {};

  OtpRepositoryImpl({OtpDataSource? otpDataSource})
      : _otpDataSource = otpDataSource ?? OtpDataSourceImpl();

  @override
  String generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  @override
  Future<bool> sendOtp({required String email}) async {
    final otp = generateOtp();
    _otpStore[email] = otp;
    return await _otpDataSource.sendOtp(email: email, otp: otp);
  }

  @override
  bool verifyOtp({required String inputOtp, required String correctOtp}) {
    return inputOtp == correctOtp;
  }

  String? getStoredOtp(String email) => _otpStore[email];
  void clearOtp(String email) => _otpStore.remove(email);
}
