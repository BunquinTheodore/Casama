import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _prefKey = 'casama_theme_mode';
  SharedPreferences? _prefs;

  ThemeNotifier([SharedPreferences? initialPrefs]) : super(ThemeMode.light) {
    if (initialPrefs != null) {
      _prefs = initialPrefs;
      _applyPersisted();
    } else {
      _loadAsync();
    }
  }

  void _applyPersisted() {
    final val = _prefs?.getString(_prefKey);
    if (val == 'dark') {
      state = ThemeMode.dark;
    } else if (val == 'system') {
      state = ThemeMode.system;
    } else if (val == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> _loadAsync() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _applyPersisted();
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  return ThemeNotifier();
});
