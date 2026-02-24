import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/user_settings_storage.dart';

final settingsStorageProvider = Provider<UserSettingsStorage>((ref) {
  return UserSettingsStorage();
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsState {
  final bool hapticsEnabled;

  const SettingsState({required this.hapticsEnabled});

  SettingsState copyWith({bool? hapticsEnabled}) {
    return SettingsState(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final UserSettingsStorage _storage;

  @override
  SettingsState build() {
    _storage = ref.read(settingsStorageProvider);
    return SettingsState(hapticsEnabled: _storage.getHapticsEnabled());
  }

  void setHapticsEnabled(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
    _storage.setHapticsEnabled(enabled);
  }
}
