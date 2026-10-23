import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static final textScale = ValueNotifier<double>(1.0);
  static bool vibration = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    textScale.value = (prefs.getDouble('fontScale') ?? 1.0).clamp(0.8, 1.4);
    vibration = prefs.getBool('vibrationOn') ?? true;
  }
}
