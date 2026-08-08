import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/common/widget/basic_elevatedbutton.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/domain/usecase/auth/sighnup_usecase.dart';
import 'package:soundora/presentation/Auth/cubit/otp_cubit.dart';
import 'package:soundora/presentation/Auth/page/otp_verification_page.dart';

import '../../../data/models/auth/create_user_req.dart';
import '../../../serviece_locator.dart';
import 'widgets/google_or_apple_btn.dart';
import 'widgets/row_text_and_textbtn.dart';

class RegisterPage extends StatefulWidget {
  final String? prefillEmail;
  const RegisterPage({super.key, this.prefillEmail});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        title: SvgPicture.asset(
          AppVectors.logo,
          width: 108.w,
          height: 33.h,
          fit: BoxFit.fill,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Register",
                style:
                    TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 15.h),
              RowTextAndTextBTN(
                title: "If you need any support ",
                clickedTitle: "Click Here",
                onTap: () {},
              ),
              SizedBox(height: 26.h),
              _fullNameTextField(context),
              SizedBox(height: 28.h),
              _emailTextField(context),
              SizedBox(height: 28.h),
              _passwordTextField(context),
              SizedBox(height: 28.h),
              _confirmPasswordTextField(context),
              SizedBox(height: 33.h),
              BasicElevatedbutton(
                title: "Register",
                onPressed: () async {
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Passwords do not match"),
                      ),
                    );
                    return;
                  }
                  if (_passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Password must be at least 6 characters"),
                      ),
                    );
                    return;
                  }
                  var result = await getIt<SighnupUsecase>().call(
                    param: CreateUserReq(
                      email: _emailController.text.toString(),
                      password: _passwordController.text.toString(),
                      username: _usernameController.text.toString(),
                    ),
                  );
                  if (!mounted) return;
                  result.fold((l) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l)),
                    );
                  }, (r) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: OtpCubit(),
                          child: OtpVerificationPage(
                            email: _emailController.text.trim(),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
              SizedBox(height: 25.h),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Divider(color: Colors.grey, thickness: 1),
                  ),
                  Text(" Or "),
                  Expanded(
                    child: Divider(color: Colors.grey, thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: 29.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleOrAppleBTN(
                    svgName: AppVectors.googleLogo,
                    onTap: () {},
                  ),
                  SizedBox(width: 58.8.w),
                  GoogleOrAppleBTN(
                    svgName: AppVectors.appleLogo,
                    onTap: () {},
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              RowTextAndTextBTN(
                title: 'Not A Member? ',
                clickedTitle: 'Register Now',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fullNameTextField(BuildContext context) {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        hintText: 'Full Name',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _emailTextField(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        hintText: 'Enter Email',
        prefixIcon: Icon(Icons.email_outlined),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _passwordTextField(BuildContext context) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Enter Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _confirmPasswordTextField(BuildContext context) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
          ),
          onPressed: () {
            setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}
