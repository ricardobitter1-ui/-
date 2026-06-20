import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chave de persistência do tema em [SharedPreferences].
const String kEximiumThemeKey = 'eximium-theme';

/// Notifier do modo de tema (dark padrão), persistido em shared_preferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Padrão: dark. Carrega o valor salvo de forma assíncrona.
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(kEximiumThemeKey);
    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'dark') {
      state = ThemeMode.dark;
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kEximiumThemeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  /// Define o modo explicitamente e persiste.
  void set(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
    _persist(mode);
  }

  /// Alterna entre dark e light.
  void toggle() {
    set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
