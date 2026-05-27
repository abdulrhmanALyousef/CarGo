import 'package:cargo/core/controllers/user_avatar_controller.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'Features/splash/splash_screen.dart';
import 'core/theme/light_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  StripeService.init();
  await ScreenUtil.ensureScreenSize();
  await PreferencesManager().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAvatarController(),
      child: ScreenUtilInit(
        designSize: const Size(375, 832),
        minTextAdapt: true,
        builder: (ctx, _) {
          return MaterialApp(
            title: 'Car Go',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}