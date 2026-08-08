import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/presentation/Auth/page/forgot_password_page.dart';
import 'package:soundora/presentation/MainWrapper/main_wrapper.dart';

import '../../../common/widget/basic_elevatedbutton.dart';
import '../../../data/models/auth/signin_req.dart';
import '../../../domain/usecase/auth/signin_usecase.dart';
import '../../../serviece_locator.dart';
import 'widgets/google_or_apple_btn.dart';
import 'widgets/row_text_and_textbtn.dart';

class SigninPage extends StatefulWidget {
  final String? prefillEmail;
  const SigninPage({super.key, this.prefillEmail});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
    _passwordController.dispose();
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
                "Sign In",
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
              _emailTextField(context),
              SizedBox(height: 28.h),
              _passwordTextField(context),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Recovery password",
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      )),
                ],
              ),
              SizedBox(height: 10.h),
              BasicElevatedbutton(
                  title: "Sign In",
                  onPressed: () async {
                    var result = await getIt<SigninUsecase>().call(
                        param: SigninReq(
                      email: _emailController.text.toString(),
                      password: _passwordController.text.toString(),
                    ));
                    if (!mounted) return;
                    result.fold((l) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l)),
                      );
                    }, (r) async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(r)),
                      );
                      await Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                MainWrapper()),
                        (route) => false,
                      );
                    });
                  }),
              SizedBox(height: 31.h),
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
              SizedBox(height: 36.h),
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
              SizedBox(height: 40.h),
              RowTextAndTextBTN(
                title: 'Don\'t have an account? ',
                clickedTitle: 'Sign Up',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailTextField(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        hintText: 'Enter Username Or Email',
        prefixIcon: Icon(Icons.person_outline_rounded),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _passwordTextField(BuildContext context) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password',
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
}
