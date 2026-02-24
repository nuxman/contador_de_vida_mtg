import 'counter_type.dart';

class CounterEvent {
  final DateTime timestamp;
  final String playerId;
  final CounterType type;
  final int delta;
  final int newValue;
  final String? sourcePlayerId;

  const CounterEvent({
    required this.timestamp,
    required this.playerId,
    required this.type,
    required this.delta,
    required this.newValue,
    this.sourcePlayerId,
  });
}
