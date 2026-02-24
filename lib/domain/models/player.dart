import 'mtg_color.dart';

class Player {
  final String id;
  final String name;
  final int life;
  final int poison;
  final int commanderTax;
  final Map<String, int> commanderDamage;
  final int? rotationQuarterTurns;
  final MtgColor mtgColor;

  const Player({
    required this.id,
    required this.name,
    required this.life,
    required this.poison,
    required this.commanderTax,
    required this.commanderDamage,
    required this.rotationQuarterTurns,
    required this.mtgColor,
  });

  Player copyWith({
    String? id,
    String? name,
    int? life,
    int? poison,
    int? commanderTax,
    Map<String, int>? commanderDamage,
    int? rotationQuarterTurns,
    MtgColor? mtgColor,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      life: life ?? this.life,
      poison: poison ?? this.poison,
      commanderTax: commanderTax ?? this.commanderTax,
      commanderDamage: commanderDamage ?? this.commanderDamage,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      mtgColor: mtgColor ?? this.mtgColor,
    );
  }
}
