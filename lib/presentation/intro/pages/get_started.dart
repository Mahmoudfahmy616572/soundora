import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soundora/core/config/assets/app_vectors.dart';
import 'package:soundora/core/config/theme/app_colors.dart';

import '../../../common/widget/basic_elevatedbutton.dart';
import '../../Auth/page/signin_and_signup.dart';
import '../widgets/sound_wave_background.dart';

class GetStarted extends StatelessWidget {
  const GetStarted({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoundWaveBackground(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
          child: Column(
            children: [
              Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(AppVectors.logo, width: 180.w)),
              Spacer(),
              Text(
                "Enjoy listening to music",
                style: TextStyle(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              SizedBox(
                height: 25.h,
              ),
              Text(
                "Smart synced lyrics, karaoke mode, and a listening journey that truly understands your taste.",
                style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.normal,
                    color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 37.h,
              ),
              BasicElevatedbutton(
                title: 'Get started',
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => SigninAndSignup()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
