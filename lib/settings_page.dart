import 'package:settings_ui/settings_ui.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: const SettingsWidget(),
    );
  }
}

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  List<SettingsSection> sections = <SettingsSection>[];

  SettingsTile tileFromSetting(Setting setting) {
    switch (setting.type) {
      case SettingType.boolean:
        return SettingsTile.switchTile(
          onToggle: (value) {
            setting.setValue(value);
            setting.save().then((value) => initAsync());
          },
          initialValue: setting.booleanValue,
          leading: Icon(setting.icon),
          title: Text(setting.title),
          description: Text(setting.description),
          activeSwitchColor: logoGreen,
        );
      case SettingType.integer:
        return SettingsTile(
          onPressed: (context) {
            setting.nextOption();
            setting.save().then((value) => initAsync());
          },
          leading: Icon(setting.icon),
          title: Text(setting.title),
          description: Text(setting.description),
          trailing: Text(
            setting.integerValue.toString(),
            style: TextStyle(color: logoGreen, fontSize: 20),
          ),
        );
      case SettingType.button:
        return SettingsTile(
          onPressed: (context) {
            setting.onPressed?.call();
            setting.save().then((value) => initAsync());
          },
          leading: Icon(setting.icon),
          title: Text(setting.title),
          description: Text(setting.description),
        );
    }
  }

  Future<void> initAsync() async {
    sections.clear();
    await Settings.load();
    List<String> sectionTitles = Settings.getSectionTitles();
    for (String sectionTitle in sectionTitles) {
      List<Setting> settings = Settings.getSettingsForSection(sectionTitle);
      if (settings.isEmpty) {
        // true when all settings in section are invisible
        continue;
      }

      List<SettingsTile> tiles =
          settings.map((setting) => tileFromSetting(setting)).toList();
      sections.add(SettingsSection(
          title: Text(
            sectionTitle,
            style: TextStyle(color: logoGreen),
          ),
          tiles: tiles));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: sections,
      lightTheme: const SettingsThemeData(
        settingsListBackground: Colors.white,
      ),
      darkTheme: const SettingsThemeData(
        settingsListBackground: Colors.black,
      ),
    );
  }
}
