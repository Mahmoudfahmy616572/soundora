import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class OtpDataSource {
  Future<bool> sendOtp({required String email, required String otp});
}

class OtpDataSourceImpl implements OtpDataSource {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<bool> sendOtp({required String email, required String otp}) async {
    try {
      final apiKey = dotenv.env['BREVO_API_KEY'] ?? '';
      final senderEmail = dotenv.env['BREVO_SENDER_EMAIL'] ?? '';

      final response = await _dio.post(
        'https://api.brevo.com/v3/smtp/email',
        options: Options(
          headers: {
            'accept': 'application/json',
            'content-type': 'application/json',
            'api-key': apiKey,
          },
        ),
        data: jsonEncode({
          "sender": {"email": senderEmail, "name": "Soundora"},
          "to": [
            {"email": email, "name": "User"}
          ],
          "subject": "Your Soundora Verification Code",
          "htmlContent":
              '''<!DOCTYPE html><html><body style="font-family: Arial, sans-serif; background-color: #121212; color: white; padding: 20px; text-align: center;"><div style="max-width: 400px; margin: 0 auto; background-color: #1a1a1a; border-radius: 16px; padding: 30px;"><h1 style="color: #42C83C;">Soundora</h1><p style="font-size: 16px; color: #b3b3b3;">Your verification code is:</p><div style="font-size: 32px; font-weight: bold; color: white; letter-spacing: 8px; padding: 20px; background-color: #282828; border-radius: 8px; margin: 20px 0;">$otp</div><p style="font-size: 14px; color: #666;">This code expires in 5 minutes.</p><p style="font-size: 14px; color: #666;">If you didn't request this, please ignore this email.</p></div></body></html>''',
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
