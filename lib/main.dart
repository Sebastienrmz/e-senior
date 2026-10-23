import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart' show AppTheme;
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await AppPreferences.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ESeniorApp());
}

class ESeniorApp extends StatelessWidget {
  const ESeniorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'E-Senior',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    builder: (context, child) => ValueListenableBuilder<double>(
      valueListenable: AppPreferences.textScale,
      builder: (context, scale, _) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) * scale,
          ),
        ),
        child: child!,
      ),
    ),
    home: const HomeScreen(),
  );
}
