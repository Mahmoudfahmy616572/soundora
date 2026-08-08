import 'package:bloc/bloc.dart';
import 'package:soundora/domain/usecase/otp/otp_usecase.dart';
import 'package:soundora/serviece_locator.dart';

import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(OtpInitial());

  String _email = '';
  String get email => _email;

  Future<void> sendOtp(String email) async {
    _email = email;
    emit(OtpSending());
    final result = await getIt<SendOtpUsecase>().call(param: email);
    result.fold(
      (failure) => emit(OtpFailure(failure)),
      (success) => emit(OtpSent(success)),
    );
  }

  Future<void> verifyOtp(String inputOtp) async {
    emit(OtpVerifying());
    final result = await getIt<VerifyOtpUsecase>().call(param: {
      'email': _email,
      'inputOtp': inputOtp,
    });
    result.fold(
      (failure) => emit(OtpFailure(failure)),
      (success) => emit(OtpVerified(success)),
    );
  }

  void reset() {
    emit(OtpInitial());
  }
}
