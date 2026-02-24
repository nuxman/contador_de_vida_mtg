import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/storage/match_storage.dart';
import '../../domain/models/counter_event.dart';
import '../../domain/models/counter_type.dart';
import '../../domain/models/match.dart';
import '../../domain/models/mtg_color.dart';
import '../../domain/models/player.dart';

final matchStorageProvider = Provider<MatchStorage>((ref) {
  return MatchStorage();
});

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(
  MatchNotifier.new,
);

class MatchState {
  final Match match;

  const MatchState({required this.match});

  MatchState copyWith({Match? match}) {
    return MatchState(match: match ?? this.match);
  }
}

class MatchNotifier extends Notifier<MatchState> {
  late final MatchStorage _storage;

  @override
  MatchState build() {
    _storage = ref.read(matchStorageProvider);
    final restored = _storage.readMatch();
    if (restored != null) {
      return MatchState(match: restored);
    }

    final match = _createDefaultMatch();
    return MatchState(match: match);
  }

  void applyDelta({
    required String playerId,
    required CounterType type,
    required int delta,
    String? sourcePlayerId,
  }) {
    final match = state.match;
    final players = match.players.map((player) {
      if (player.id != playerId) return player;
      return _applyDeltaToPlayer(
        player: player,
        type: type,
        delta: delta,
        sourcePlayerId: sourcePlayerId,
      );
    }).toList();

    final newValue = _getPlayerCounterValue(
      players.firstWhere((player) => player.id == playerId),
      type,
      sourcePlayerId: sourcePlayerId,
    );

    final event = CounterEvent(
      timestamp: DateTime.now(),
      playerId: playerId,
      type: type,
      delta: delta,
      newValue: newValue,
      sourcePlayerId: sourcePlayerId,
    );

    state = state.copyWith(
      match: match.copyWith(
        players: players,
        history: [...match.history, event],
      ),
    );
    unawaited(_storage.saveMatch(state.match));
  }

  Player _applyDeltaToPlayer({
    required Player player,
    required CounterType type,
    required int delta,
    String? sourcePlayerId,
  }) {
    switch (type) {
      case CounterType.life:
        return player.copyWith(life: player.life + delta);
      case CounterType.poison:
        return player.copyWith(poison: player.poison + delta);
      case CounterType.commanderTax:
        return player.copyWith(commanderTax: player.commanderTax + delta);
      case CounterType.commanderDamage:
        final sourceId = sourcePlayerId ?? 'unknown';
        final current = player.commanderDamage[sourceId] ?? 0;
        final updated = Map<String, int>.from(player.commanderDamage)
          ..[sourceId] = current + delta;
        return player.copyWith(
          commanderDamage: updated,
          life: player.life - delta,
        );
    }
  }

  int _getPlayerCounterValue(
    Player player,
    CounterType type, {
    String? sourcePlayerId,
  }) {
    switch (type) {
      case CounterType.life:
        return player.life;
      case CounterType.poison:
        return player.poison;
      case CounterType.commanderTax:
        return player.commanderTax;
      case CounterType.commanderDamage:
        final sourceId = sourcePlayerId ?? 'unknown';
        return player.commanderDamage[sourceId] ?? 0;
    }
  }

  Player _newPlayer({
    required String id,
    required String name,
    required int life,
    required MtgColor mtgColor,
  }) {
    return Player(
      id: id,
      name: name,
      life: life,
      poison: 0,
      commanderTax: 0,
      commanderDamage: const {},
      rotationQuarterTurns: _storage.getRotationQuarterTurns(id),
      mtgColor: mtgColor,
    );
  }

  void toggleRotation({
    required String playerId,
    required bool autoRotated,
  }) {
    final match = state.match;
    final players = match.players.map((player) {
      if (player.id != playerId) return player;

      final current = player.rotationQuarterTurns;
      final next = current == null
          ? (autoRotated ? 0 : 2)
          : null;

      unawaited(_storage.setRotationQuarterTurns(player.id, next));
      return player.copyWith(rotationQuarterTurns: next);
    }).toList();

    state = state.copyWith(
      match: match.copyWith(players: players),
    );
    unawaited(_storage.saveMatch(state.match));
  }

  void resetMatch() {
    final match =
        _createMatchFromSetupPrefs(useSlotNames: false) ?? _createDefaultMatch();
    state = state.copyWith(match: match);
    unawaited(_storage.clearMatch());
    unawaited(_storage.saveMatch(match));
  }

  void startNewMatch({
    required int life,
    required List<PlayerSeed> players,
  }) {
    final now = DateTime.now();
    final newPlayers = [
      for (var i = 0; i < players.length; i++)
        _newPlayer(
          id: 'p${i + 1}',
          name: players[i].name,
          life: life,
          mtgColor: players[i].color,
        ),
    ];

    final match = Match(
      id: 'match-${now.millisecondsSinceEpoch}',
      createdAt: now,
      players: newPlayers,
      history: const [],
    );

    state = state.copyWith(match: match);
    unawaited(_storage.clearMatch());
    unawaited(_storage.saveMatch(match));
    unawaited(_storage.addRecentNames(players.map((p) => p.name)));
  }

  Match _createDefaultMatch() {
    final now = DateTime.now();
    final colors = [
      MtgColor.white,
      MtgColor.blue,
      MtgColor.black,
      MtgColor.red,
      MtgColor.green,
      MtgColor.colorless,
    ];
    final players = [
      _newPlayer(
        id: 'p1',
        name: 'Jogador 1',
        life: 40,
        mtgColor: colors[0],
      ),
      _newPlayer(
        id: 'p2',
        name: 'Jogador 2',
        life: 40,
        mtgColor: colors[1],
      ),
    ];

    return Match(
      id: 'match-${now.millisecondsSinceEpoch}',
      createdAt: now,
      players: players,
      history: const [],
    );
  }

  void setPlayerColor({
    required String playerId,
    required MtgColor mtgColor,
  }) {
    final match = state.match;
    final players = match.players.map((player) {
      if (player.id != playerId) return player;
      return player.copyWith(mtgColor: mtgColor);
    }).toList();
    state = state.copyWith(match: match.copyWith(players: players));
    unawaited(_storage.saveMatch(state.match));
  }

  void setPlayerName({
    required String playerId,
    required String name,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final match = state.match;
    final players = match.players.map((player) {
      if (player.id != playerId) return player;
      return player.copyWith(name: trimmed);
    }).toList();
    state = state.copyWith(match: match.copyWith(players: players));
    unawaited(_storage.saveMatch(state.match));
  }

  Match? _createMatchFromSetupPrefs({required bool useSlotNames}) {
    final prefs = _storage.getSetupPrefs();
    final playerCount = prefs['playerCount'] as int?;
    final life = prefs['life'] as int?;
    final slots = prefs['slots'];
    if (playerCount == null || life == null) return null;
    if (playerCount < 1 || playerCount > 6) return null;

    final colorsFallback = [
      MtgColor.white,
      MtgColor.blue,
      MtgColor.black,
      MtgColor.red,
      MtgColor.green,
      MtgColor.colorless,
    ];

    final now = DateTime.now();
    final players = <Player>[];
    for (var i = 0; i < playerCount; i++) {
      String name = 'Jogador ${i + 1}';
      MtgColor color = colorsFallback[i % colorsFallback.length];
      if (slots is List && i < slots.length) {
        final slot = slots[i];
        if (slot is Map) {
          final slotName = slot['name']?.toString();
          final colorName = slot['color']?.toString();
          if (useSlotNames && slotName != null && slotName.trim().isNotEmpty) {
            name = slotName.trim();
          }
          color = MtgColor.values.firstWhere(
            (c) => c.name == colorName,
            orElse: () => color,
          );
        }
      }
      players.add(
        _newPlayer(
          id: 'p${i + 1}',
          name: name,
          life: life,
          mtgColor: color,
        ),
      );
    }

    return Match(
      id: 'match-${now.millisecondsSinceEpoch}',
      createdAt: now,
      players: players,
      history: const [],
    );
  }
}

class PlayerSeed {
  final String name;
  final MtgColor color;

  const PlayerSeed({
    required this.name,
    required this.color,
  });
}
