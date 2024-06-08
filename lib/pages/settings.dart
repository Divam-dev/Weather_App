import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:weather_app/apis/github.dart';
import 'package:weather_app/components/switch_row_preference.dart';
import 'package:weather_app/enum/speed_unit.dart';
import 'package:weather_app/enum/temperature_unit.dart';
import 'package:weather_app/preferences_storage.dart';
import 'package:weather_app/theme_manager.dart';
import 'package:http/http.dart' as http;

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _Settings();
}

class _Settings extends State<Settings> {
  // @override
  // void initState() {
  //   super.initState();
  //   setState(() {
  //     GithubApi.getLatestRelease().then((value) => newerVersion = value);
  //   });
  // }

  TextStyle titleStyle = const TextStyle(fontSize: 16, height: 2);
  TextStyle subTitleStyle = const TextStyle(fontSize: 14, height: 3);

  TemperatureUnit selectedTemperatureUnit = TemperatureUnit.CELSIUS;
  SpeedUnit selectedWindSpeedUnit = SpeedUnit.KMH;

  String version = "";
  String newerVersion = "";

  @override
  Widget build(BuildContext context) {
    //GithubApi.getVersionCode().then((value) => setState(() => version = value));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).viewPadding.top),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                92 -
                MediaQuery.of(context).viewPadding.top,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Налаштування теми", style: titleStyle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Світла/Темна тема", style: subTitleStyle),
                      IconButton(
                        icon: Icon(
                          ThemeManager.themeNotifier.value == ThemeMode.dark
                              ? Icons.brightness_3
                              : Icons.wb_sunny,
                        ),
                        onPressed: () {
                          setState(() {
                            ThemeManager.toggleTheme();
                          });
                          PreferencesStorage.setThemeMode(
                              ThemeManager.themeNotifier.value);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Text("Налаштування локації", style: titleStyle),
                  const SwitchRowPreference(
                      preference: SettingPreferences.USE_GPS_DEFAULT,
                      text: "Завжди використовувати GPS локацію"),
                  OutlinedButton(
                    onPressed: () async {
                      await PreferencesStorage.drop(
                          PreferencesStorage.GEO_LAST_LOAD);
                    },
                    child: const Text("Видалити останню локацію"),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  Text("Налаштування задньго фону", style: titleStyle),
                  const SwitchRowPreference(
                      preference: SettingPreferences.SHOW_COLOR_BACKGROUND,
                      text: "Показувати кольоровий фон в залежності від погоди",
                      defaultState: true),
                  const SizedBox(height: 20),
                  const Divider(),
                  Text("Інформація про додаток", style: titleStyle),
                  Text("Версія 1.0.0", style: subTitleStyle),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 92)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
