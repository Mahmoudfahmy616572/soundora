import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soundora/common/widget/basic_elevatedbutton.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/presentation/Auth/page/register.dart';
import 'package:soundora/presentation/Auth/page/signin.dart';

import '../../../common/appbar/basic_appbar.dart';

class SigninAndSignup extends StatelessWidget {
  const SigninAndSignup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BasicAppbar(),
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AppVectors.topRightUnion),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(AppVectors.bottomRightUnion),
          ),

          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppVectors.logo,
                    width: 235.w,
                    height: 71.h,
                  ),
                  SizedBox(
                    height: 55.h,
                  ),
                  Text(
                    "Enjoy listening to music",
                    style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 21.h),
                  Text(
                    "Soundora understands your music â€” smart lyrics, karaoke, and a listening journey built around you.",
                    style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.normal,
                        color: Color(0xff797979)),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Expanded(
                          flex: 1,
                          child: BasicElevatedbutton(
                              title: "Register",
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            RegisterPage()));
                              })),
                      Expanded(
                          flex: 1,
                          child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            SigninPage()));
                              },
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19.sp,
                                    color: Colors.white),
                              )))
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
