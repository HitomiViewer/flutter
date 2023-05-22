import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store extends ChangeNotifier {
  SharedPreferences? _prefs;

  Store() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      language = prefs.getString('language') ?? language;
      blacklist = prefs.getStringList('blacklist') ?? blacklist;
    });
  }

  var language = 'korean';
  setLanguage(String language) {
    this.language = language;
    _prefs?.setString('language', language);
    notifyListeners();
  }

  var blacklist = <String>['male:yaoi'];
  addBlacklist(String tag) {
    blacklist.add(tag);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  removeBlacklist(String tag) {
    blacklist.remove(tag);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  removeAtBlacklist(int index) {
    blacklist.removeAt(index);
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }

  setBlacklist(List<String> blacklist) {
    this.blacklist = blacklist;
    _prefs?.setStringList('blacklist', blacklist);
    notifyListeners();
  }
}
