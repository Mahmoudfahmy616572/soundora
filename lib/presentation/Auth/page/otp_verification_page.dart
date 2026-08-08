import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/common/widget/basic_elevatedbutton.dart';
import 'package:soundora/presentation/Auth/cubit/otp_cubit.dart';
import 'package:soundora/presentation/Auth/cubit/otp_state.dart';
import 'package:soundora/presentation/MainWrapper/main_wrapper.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OtpCubit>().sendOtp(widget.email);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<OtpCubit, OtpState>(
        listener: (context, state) {
          if (state is OtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is OtpVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registration successful!")),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => MainWrapper()),
              (route) => false,
            );
          } else if (state is OtpFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "We sent a verification code to",
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B2FBE),
                ),
              ),
              SizedBox(height: 40.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48.w,
                    height: 56.h,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                          fontSize: 24.sp, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide:
                              const BorderSide(color: Color(0xFF2A2A3E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(
                              color: Color(0xFF7B2FBE), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(
                              color: Color(0xFF2A2A3E), width: 1.2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1C1C2E),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_otpCode.length == 6) {
                          context.read<OtpCubit>().verifyOtp(_otpCode);
                        }
                      },
                    ),
                  );
                }),
              ),
              SizedBox(height: 30.h),
              BlocBuilder<OtpCubit, OtpState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      if (state is OtpSending || state is OtpVerifying)
                        const CircularProgressIndicator(
                            color: Color(0xFF7B2FBE)),
                      SizedBox(height: 16.h),
                      TextButton(
                        onPressed: state is OtpSending
                            ? null
                            : () {
                                context
                                    .read<OtpCubit>()
                                    .sendOtp(widget.email);
                              },
                        child: Text(
                          "Resend Code",
                          style: TextStyle(
                            color: const Color(0xFF7B2FBE),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              BasicElevatedbutton(
                title: "Verify",
                onPressed: () {
                  if (_otpCode.length == 6) {
                    context.read<OtpCubit>().verifyOtp(_otpCode);
                  }
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
