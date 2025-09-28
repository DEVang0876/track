import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/app_settings.dart';
import 'package:trackizer/view/main_tab/main_tab_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    return MaterialApp(
      title: 'Trackizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme.apply(bodyColor: Colors.black),
        // ...add more light theme customizations...
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181820),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white),
        // ...add more dark theme customizations...
      ),
      themeMode: appSettings.themeMode,
      home: const MainTabView(),
    );
  }
}
