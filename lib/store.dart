import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store extends ChangeNotifier {
  SharedPreferences? _prefs;

  Store() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      language = prefs.getString('language') ?? language;
      favorite =
          prefs.getStringList('favorite')?.map((e) => int.parse(e)).toList() ??
              favorite;
      blacklist = prefs.getStringList('blacklist') ?? blacklist;

      favorite.sort((a, b) => b.compareTo(a));

      print(favorite);
      notifyListeners();
    });
  }

  var language = 'korean';
  setLanguage(String language) {
    this.language = language;
    _prefs?.setString('language', language);
    notifyListeners();
  }

  var favorite = <int>[];
  addFavorite(int id) {
    favorite.add(id);
    favorite.sort((a, b) => b.compareTo(a));
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  removeFavorite(int id) {
    favorite.remove(id);
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  removeAtFavorite(int index) {
    favorite.removeAt(index);
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  setFavorite(List<int> favorite) {
    this.favorite = favorite;
    this.favorite.sort((a, b) => b.compareTo(a));
    _prefs?.setStringList(
        'favorite', favorite.map((e) => e.toString()).toList());
    notifyListeners();
  }

  containsFavorite(int id) {
    return favorite.contains(id);
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
