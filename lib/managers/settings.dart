import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/settings.dart';

class SettingsManager extends StateNotifier<Settings> {
  SettingsManager() : super(Settings()) {
    load();
  }

  void load() async {
    var box = await Hive.openBox<Settings>('settingsBox');
    state = box.get(0) ?? Settings();
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    save();
  }

  void toggleSound() {
    state = state.copyWith(isSoundEnabled: !state.isSoundEnabled);
    save();
  }

  void setGridSize(int size) {
    state = state.copyWith(gridSize: size);
    save();
  }

  void save() async {
    var box = await Hive.openBox<Settings>('settingsBox');
    try {
      box.putAt(0, state);
    } catch (e) {
      box.add(state);
    }
  }
}

final settingsManager = StateNotifierProvider<SettingsManager, Settings>((ref) {
  return SettingsManager();
});
