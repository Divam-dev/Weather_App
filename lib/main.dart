import 'package:flutter/material.dart';
import 'package:semaphore_plus/semaphore_plus.dart';
import 'package:weather_app/pages/current_weather.dart';
import 'package:weather_app/pages/historical_weather.dart';
import 'package:weather_app/pages/settings.dart';
import 'package:weather_app/preferences_storage.dart';
import 'package:weather_app/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeMode themeMode = await PreferencesStorage.getThemeMode();
  ThemeManager.themeNotifier.value = themeMode;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Flutter Demo',
          darkTheme: ThemeData.dark(useMaterial3: true),
          theme: ThemeData.light(useMaterial3: true),
          themeMode: currentMode,
          home: const ApplicationRoot(),
        );
      },
    );
  }
}

class ApplicationRoot extends StatefulWidget {
  const ApplicationRoot({super.key});

  @override
  State<ApplicationRoot> createState() => _ApplicationRoot();
}

class _ApplicationRoot extends State<ApplicationRoot> {
  int currentPageIndex = 0;
  LocalSemaphore semaphore = LocalSemaphore(1);
  bool enabled = true;

  @override
  void initState() {
    super.initState();
    FileStorage.initialize();
    PreferencesStorage.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const CurrentWeather(),
        const HistoricalWeather(),
        const Settings()
      ][currentPageIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        height: 80,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_cloudy_outlined),
            selectedIcon: const Icon(Icons.wb_cloudy_rounded),
            label: "Погода",
            enabled: enabled,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: "Історія",
            enabled: enabled,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: "Налаштування",
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
