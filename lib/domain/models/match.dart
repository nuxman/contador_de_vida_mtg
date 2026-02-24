import 'counter_event.dart';
import 'player.dart';

class Match {
  final String id;
  final DateTime createdAt;
  final List<Player> players;
  final List<CounterEvent> history;

  const Match({
    required this.id,
    required this.createdAt,
    required this.players,
    required this.history,
  });

  Match copyWith({
    String? id,
    DateTime? createdAt,
    List<Player>? players,
    List<CounterEvent>? history,
  }) {
    return Match(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      history: history ?? this.history,
    );
  }
}
