import 'package:hive/hive.dart';

import '../../domain/models/counter_event.dart';
import '../../domain/models/counter_type.dart';
import '../../domain/models/match.dart';
import '../../domain/models/mtg_color.dart';
import '../../domain/models/player.dart';

class MatchStorage {
  static const String _playerPrefsBox = 'player_prefs';
  static const String _matchStateBox = 'match_state';
  static const String _matchKey = 'current_match';
  static const String _recentNamesKey = 'recent_names';
  static const String _setupPrefsKey = 'setup_prefs';

  Box<dynamic> get _playerPrefs => Hive.box<dynamic>(_playerPrefsBox);
  Box<dynamic> get _matchState => Hive.box<dynamic>(_matchStateBox);

  int? getRotationQuarterTurns(String playerId) {
    return _playerPrefs.get('rotation_$playerId') as int?;
  }

  Future<void> setRotationQuarterTurns(String playerId, int? turns) async {
    final key = 'rotation_$playerId';
    if (turns == null) {
      await _playerPrefs.delete(key);
      return;
    }
    await _playerPrefs.put(key, turns);
  }

  Match? readMatch() {
    final data = _matchState.get(_matchKey);
    if (data is! Map) return null;
    return _matchFromMap(Map<String, dynamic>.from(data));
  }

  Future<void> saveMatch(Match match) async {
    await _matchState.put(_matchKey, _matchToMap(match));
  }

  Future<void> clearMatch() async {
    await _matchState.delete(_matchKey);
  }

  List<String> getRecentNames() {
    final raw = _playerPrefs.get(_recentNamesKey);
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> addRecentNames(Iterable<String> names) async {
    final existing = getRecentNames();
    final merged = <String>{...existing, ...names.map((n) => n.trim())}
      ..removeWhere((n) => n.isEmpty);
    await _playerPrefs.put(_recentNamesKey, merged.toList());
  }

  Map<String, dynamic> getSetupPrefs() {
    final raw = _playerPrefs.get(_setupPrefsKey);
    if (raw is! Map) return const {};
    return Map<String, dynamic>.from(raw);
  }

  Future<void> setSetupPrefs({
    required int playerCount,
    required int life,
    required List<Map<String, dynamic>> slots,
  }) async {
    await _playerPrefs.put(_setupPrefsKey, {
      'playerCount': playerCount,
      'life': life,
      'slots': slots,
    });
  }

  Map<String, dynamic> _matchToMap(Match match) {
    return {
      'id': match.id,
      'createdAt': match.createdAt.millisecondsSinceEpoch,
      'players': match.players.map(_playerToMap).toList(),
      'history': match.history.map(_eventToMap).toList(),
    };
  }

  Match _matchFromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
      players: (map['players'] as List<dynamic>)
          .map((item) => _playerFromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      history: (map['history'] as List<dynamic>)
          .map((item) => _eventFromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> _playerToMap(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'life': player.life,
      'poison': player.poison,
      'commanderTax': player.commanderTax,
      'commanderDamage': player.commanderDamage,
      'rotationQuarterTurns': player.rotationQuarterTurns,
      'mtgColor': player.mtgColor.name,
    };
  }

  Player _playerFromMap(Map<String, dynamic> map) {
    final colorName = map['mtgColor'] as String?;
    final color = MtgColor.values
        .firstWhere((c) => c.name == colorName, orElse: () => MtgColor.colorless);
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      life: map['life'] as int,
      poison: map['poison'] as int,
      commanderTax: map['commanderTax'] as int,
      commanderDamage:
          Map<String, int>.from(map['commanderDamage'] as Map<dynamic, dynamic>),
      rotationQuarterTurns: map['rotationQuarterTurns'] as int?,
      mtgColor: color,
    );
  }

  Map<String, dynamic> _eventToMap(CounterEvent event) {
    return {
      'timestamp': event.timestamp.millisecondsSinceEpoch,
      'playerId': event.playerId,
      'type': event.type.name,
      'delta': event.delta,
      'newValue': event.newValue,
      'sourcePlayerId': event.sourcePlayerId,
    };
  }

  CounterEvent _eventFromMap(Map<String, dynamic> map) {
    return CounterEvent(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      playerId: map['playerId'] as String,
      type: CounterType.values.firstWhere((e) => e.name == map['type']),
      delta: map['delta'] as int,
      newValue: map['newValue'] as int,
      sourcePlayerId: map['sourcePlayerId'] as String?,
    );
  }
}
