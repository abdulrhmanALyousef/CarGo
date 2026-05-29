import 'package:cargo/core/controllers/favorites_notifier.dart';
import 'package:cargo/core/controllers/user_avatar_controller.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/services/stripe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'Features/splash/splash_screen.dart';
import 'Features/notifications/notification_service.dart';
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

  // Initialise FCM and local notification infrastructure.
  await NotificationService().initialize();

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
            // Global navigator key lets NotificationService push screens
            // from notification taps regardless of where the user is in the app.
            navigatorKey: NotificationService.navigatorKey,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
