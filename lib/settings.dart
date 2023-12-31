import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum SettingType {
  integer,
  boolean,
  button,
}

class Setting {
  Setting({
    required this.key,
    required this.defaultValue,
    required this.type,
    this.sectionTitle = "",
    this.title = "",
    this.description = "",
    this.icon = Icons.settings,
    this.options = const <dynamic>[],
    this.visible = true,
    this.onPressed,
  }) : value = defaultValue;

  final String key;
  final dynamic defaultValue;
  dynamic value;
  final SettingType type;
  final String title;
  final String sectionTitle;
  final String description;
  final IconData icon;
  List<dynamic> options = <dynamic>[];
  final Function? onPressed;
  final bool visible;

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (type) {
      case SettingType.boolean:
        prefs.setBool(key, value);
        break;
      case SettingType.integer:
        prefs.setInt(key, value);
        break;
      case SettingType.button:
        break;
    }
  }

  @override
  String toString() {
    return 'Setting{key: $key, defaultValue: $defaultValue, value: $value, type: $type, title: $title, description: $description}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Setting &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          defaultValue == other.defaultValue &&
          value == other.value &&
          type == other.type &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode =>
      key.hashCode ^
      defaultValue.hashCode ^
      value.hashCode ^
      type.hashCode ^
      title.hashCode ^
      description.hashCode;

  void setValue(dynamic value) {
    this.value = value;
  }

  bool get booleanValue {
    return value as bool;
  }

  int get integerValue {
    return value as int;
  }

  void nextOption() {
    int index = options.indexOf(value);
    if (index == -1) {
      return;
    }

    if (index == options.length - 1) {
      index = 0;
    } else {
      index++;
    }
    value = options[index];
  }
}

class Settings {
  static final List<Setting> _settings = <Setting>[
    Setting(
      key: "sounds_volume",
      defaultValue: 100,
      type: SettingType.integer,
      title: "Soundeffect Volume",
      sectionTitle: "Audio & Vibration",
      description:
          "Volume of soundeffects (in percent). Set to 0 to disable soundeffects.",
      icon: Icons.speaker_outlined,
      options: <int>[0, 25, 50, 75, 100],
    ),

    Setting(
      key: "music_volume",
      defaultValue: 50,
      type: SettingType.integer,
      title: "Music Volume",
      sectionTitle: "Audio & Vibration",
      description: "Volume of music (in percent). Set to 0 to disable music.",
      icon: Icons.music_note_outlined,
      options: <int>[0, 25, 50, 75, 100],
    ),

    Setting(
      key: "zen_mode_size",
      defaultValue: 5,
      type: SettingType.integer,
      title: "Field-Size",
      sectionTitle: "Zen-Mode",
      description:
          "The size of the field. The larger, the more difficult the game.",
      icon: Icons.crop,
      options: <int>[4, 5, 6, 7, 8],
    ),

    Setting(
      key: "zen_mode_view_time",
      defaultValue: 2,
      type: SettingType.integer,
      title: "View-Time",
      sectionTitle: "Zen-Mode",
      description:
          "The seconds you have to memorize the field. The smaller, the more difficult the game.",
      icon: Icons.timer_outlined,
      options: <int>[1, 2, 3, 4, 5],
    ),

    Setting(
      key: "zen_mode_bomb_percentage",
      defaultValue: 40,
      type: SettingType.integer,
      title: "Bomb-Percentage",
      sectionTitle: "Zen-Mode",
      description:
          "The percentage of bombs on the field. The bigger, the more difficult the game.",
      icon: Icons.percent,
      options: <int>[10, 20, 30, 40, 50, 60, 70],
    ),

    Setting(
      key: "vibration_on_fail",
      defaultValue: true,
      type: SettingType.boolean,
      title: "Vibrate on Fail",
      sectionTitle: "Audio & Vibration",
      description: "Toggle wether to vibrate when you fail a game.",
      icon: Icons.vibration_outlined,
    ),

    Setting(
      key: "reset",
      defaultValue: null,
      type: SettingType.button,
      title: "Reset Settings",
      sectionTitle: "Miscellaneous",
      description: "Reset all settings to their default value.",
      icon: Icons.restore_rounded,
      onPressed: () {
        reset();
      },
    ),

    Setting(
      key: "fullreset",
      defaultValue: null,
      type: SettingType.button,
      title: "Reset all data",
      sectionTitle: "Miscellaneous",
      description:
          "Reset all data that is stored. This includes scores, levels and shop-items.",
      icon: Icons.delete_forever_outlined,
      visible: false,
      onPressed: () {
        fullReset();
      },
    ),

    Setting(
      key: "thanks_mattis",
      defaultValue: null,
      type: SettingType.button,
      title: "Music Credit",
      sectionTitle: "Miscellaneous",
      description:
          "All sound tracks and effects were created by Mattis Strickert. Thanks for that, you did an awesome job!",
      icon: Icons.info_outline,
      onPressed: () async {},
    ),

    // invisible settings
    Setting(
        key: "zen_levels_completed",
        defaultValue: 0,
        type: SettingType.integer,
        visible: false),

    Setting(
        key: "levels_completed",
        defaultValue: 0,
        type: SettingType.integer,
        visible: false),

    Setting(
        key: "1_minute_challenge_highscore",
        defaultValue: -1,
        type: SettingType.integer,
        visible: false),

    Setting(
      key: "coins",
      defaultValue: 0,
      type: SettingType.integer,
      visible: false,
    )
  ];

  static List<Setting> get settings => _settings;

  static Setting getSetting(String key) {
    return _settings.firstWhere((element) => element.key == key);
  }

  static List<String> getSectionTitles() {
    List<String> sectionTitles = <String>[];
    for (Setting setting in _settings) {
      if (!sectionTitles.contains(setting.sectionTitle)) {
        sectionTitles.add(setting.sectionTitle);
      }
    }
    return sectionTitles;
  }

  static List<Setting> getSettingsForSection(String sectionTitle) {
    return _settings
        .where((element) => element.sectionTitle == sectionTitle)
        .where((element) => element.visible)
        .toList();
  }

  static Future<void> load() async {
    // using SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (Setting setting in _settings) {
      switch (setting.type) {
        case SettingType.boolean:
          setting.setValue(prefs.getBool(setting.key) ?? setting.defaultValue);
          break;
        case SettingType.integer:
          setting.setValue(prefs.getInt(setting.key) ?? setting.defaultValue);
          break;
        case SettingType.button:
          break;
      }
    }
  }

  static Future<void> save() async {
    for (Setting setting in _settings) {
      await setting.save();
    }
  }

  static void reset() {
    for (Setting setting in _settings) {
      if (!setting.visible) continue;
      setting.setValue(setting.defaultValue);
      setting.save();
    }
  }

  static Future<void> fullReset() async {
    for (Setting setting in _settings) {
      setting.setValue(setting.defaultValue);
      setting.save();
    }
  }
}
