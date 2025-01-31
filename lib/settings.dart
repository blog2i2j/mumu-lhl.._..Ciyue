import "package:ciyue/main.dart";
import "package:flutter/material.dart";

final settings = _Settings();

class _Settings {
  late bool autoExport;
  late String exportFileName;
  late String? exportDirectory;
  late ThemeMode themeMode;
  late bool autoRemoveSearchWord;
  late bool secureScreen;
  String? language;
  late bool searchBarInAppBar;

  _Settings() {
    autoExport = prefs.getBool("autoExport") ?? false;
    exportFileName = prefs.getString("exportFileName") ?? "ciyue";
    exportDirectory = prefs.getString("exportDirectory");
    autoRemoveSearchWord = prefs.getBool("autoRemoveSearchWord") ?? false;
    secureScreen = prefs.getBool("secureScreen") ?? false;
    searchBarInAppBar = prefs.getBool("searchBarInAppBar") ?? true;

    language = prefs.getString("language");
    language ??= "system";

    final themeModeString = prefs.getString("themeMode");
    switch (themeModeString) {
      case "light":
        themeMode = ThemeMode.light;
      case "dark":
        themeMode = ThemeMode.dark;
      case "system" || null:
        themeMode = ThemeMode.system;
    }
  }
}
