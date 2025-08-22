import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _currency = "₹";

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }
}
