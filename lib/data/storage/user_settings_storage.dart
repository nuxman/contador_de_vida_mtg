import 'package:hive/hive.dart';

class UserSettingsStorage {
  static const String _boxName = 'user_settings';
  static const String _hapticsKey = 'haptics_enabled';

  Box<dynamic> get _box => Hive.box<dynamic>(_boxName);

  bool getHapticsEnabled() {
    final value = _box.get(_hapticsKey);
    if (value is bool) return value;
    return true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _box.put(_hapticsKey, enabled);
  }
}
