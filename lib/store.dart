import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store extends ChangeNotifier {
  SharedPreferences? _prefs;

  Store() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      language = prefs.getString('language') ?? language;
    });
  }

  var language = 'korean';
  setLanguage(String language) {
    this.language = language;
    _prefs?.setString('language', language);
    notifyListeners();
  }
}
