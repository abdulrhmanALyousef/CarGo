import 'package:cargo/core/controllers/favorites_notifier.dart';
import 'package:cargo/core/controllers/user_avatar_controller.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'Features/splash/splash_screen.dart';
import 'core/theme/light_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserAvatarController()),
        ChangeNotifierProvider(create: (_) => FavoritesNotifier()),
      ],
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