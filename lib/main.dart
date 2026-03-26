import 'package:cargo/Features/home/home_screen.dart';
import 'package:cargo/Features/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'Features/splash/splash_screen.dart';
import 'core/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenUtil.ensureScreenSize();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 832),
      minTextAdapt: true,
      builder: (ctx, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => HomeController()),
          ],
          child: MaterialApp(
            title: 'Tasky App',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}