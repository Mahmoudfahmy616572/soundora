import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:soundora/presentation/chooseMode/bloc/theme_cubit.dart';

import '../../../common/widget/basic_elevatedbutton.dart';
import '../../../common/widget/choose_mode_btn.dart';
import '../../../core/config/assets/app_vectors.dart';
import '../../Auth/page/signin_and_signup.dart';
import '../../intro/widgets/sound_wave_background.dart';

class ChooseMode extends StatelessWidget {
  const ChooseMode({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoundWaveBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            children: [
              Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(AppVectors.logo, width: 180)),
              const Spacer(),
              const Text(
                "Choose mode",
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
              const SizedBox(
                height: 25,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChooseModeBtn(
                    svgName: AppVectors.moon,
                    modeTitle: 'Dark Mode',
                    ontap: () {
                      context
                          .read<ThemeCubit>()
                          .updateTheme(ThemeMode.dark);
                    },
                  ),
                  const SizedBox(
                    width: 71,
                  ),
                  ChooseModeBtn(
                    svgName: AppVectors.sun,
                    modeTitle: 'Light mode',
                    ontap: () {
                      context
                          .read<ThemeCubit>()
                          .updateTheme(ThemeMode.light);
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 37,
              ),
              BasicElevatedbutton(
                title: 'Continue',
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              SigninAndSignup()));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
