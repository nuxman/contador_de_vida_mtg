import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/counter_event.dart';
import '../../domain/models/counter_type.dart';
import '../../domain/models/match.dart';
import '../../domain/models/mtg_color.dart';
import '../../domain/models/player.dart';
import '../providers/match_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/player_panel.dart';

class TableScreen extends ConsumerWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider).match;
    final players = match.players;
    final hapticsEnabled = ref.watch(settingsProvider).hapticsEnabled;
    final rollResults = ref.watch(rollResultsProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildLayout(context, ref, players, hapticsEnabled, rollResults),
          Align(
            alignment: Alignment.center,
            child: _CenterHub(
              onOpen: () => _showHubMenu(
                context,
                ref,
                match,
                hapticsEnabled,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _gridPadding = 0;
const double _gridSpacing = 0;

Widget _buildLayout(
  BuildContext context,
  WidgetRef ref,
  List<Player> players,
  bool hapticsEnabled,
  Map<String, int> rollResults,
) {
  if (players.length == 3) {
    final topPlayer = players[0];
    final bottomLeft = players[1];
    final bottomRight = players[2];

    return Padding(
      padding: const EdgeInsets.all(_gridPadding),
      child: Column(
        children: [
          Expanded(
            child: _wrapPlayerPanel(
              context: context,
              ref: ref,
              player: topPlayer,
              allPlayers: players,
              hapticsEnabled: hapticsEnabled,
              rollResult: rollResults[topPlayer.id],
              rotate: true,
            ),
          ),
          const SizedBox(height: _gridSpacing),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: bottomLeft,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[bottomLeft.id],
                    rotate: false,
                  ),
                ),
                const SizedBox(width: _gridSpacing),
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: bottomRight,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[bottomRight.id],
                    rotate: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  if (players.length == 5) {
    final topLeft = players[0];
    final topRight = players[1];
    final midLeft = players[2];
    final midRight = players[3];
    final bottom = players[4];

    return Padding(
      padding: const EdgeInsets.all(_gridPadding),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: topLeft,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[topLeft.id],
                    rotate: true,
                  ),
                ),
                const SizedBox(width: _gridSpacing),
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: topRight,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[topRight.id],
                    rotate: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _gridSpacing),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: midLeft,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[midLeft.id],
                    rotate: false,
                  ),
                ),
                const SizedBox(width: _gridSpacing),
                Expanded(
                  child: _wrapPlayerPanel(
                    context: context,
                    ref: ref,
                    player: midRight,
                    allPlayers: players,
                    hapticsEnabled: hapticsEnabled,
                    rollResult: rollResults[midRight.id],
                    rotate: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _gridSpacing),
          Expanded(
            child: _wrapPlayerPanel(
              context: context,
              ref: ref,
              player: bottom,
              allPlayers: players,
              hapticsEnabled: hapticsEnabled,
              rollResult: rollResults[bottom.id],
              rotate: false,
            ),
          ),
        ],
      ),
    );
  }

  final grid = _gridSpec(players.length);

  return LayoutBuilder(
    builder: (context, constraints) {
      final tileWidth = (constraints.maxWidth -
              (grid.columns - 1) * _gridSpacing) /
          grid.columns;
      final tileHeight = (constraints.maxHeight -
              (grid.rows - 1) * _gridSpacing) /
          grid.rows;
      final aspectRatio = tileWidth / tileHeight;

      return GridView.builder(
        padding: const EdgeInsets.all(_gridPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: grid.columns,
          mainAxisSpacing: _gridSpacing,
          crossAxisSpacing: _gridSpacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final row = index ~/ grid.columns;
          final rotate = grid.rows > 1 && row == 0;
          return _wrapPlayerPanel(
            context: context,
            ref: ref,
            player: player,
            allPlayers: players,
            hapticsEnabled: hapticsEnabled,
            rollResult: rollResults[player.id],
            rotate: rotate,
          );
        },
      );
    },
  );
}

Widget _wrapPlayerPanel({
  required BuildContext context,
  required WidgetRef ref,
  required Player player,
  required List<Player> allPlayers,
  required bool hapticsEnabled,
  required int? rollResult,
  required bool rotate,
}) {
  final opponents = allPlayers
      .where((p) => p.id != player.id)
      .map((p) => Opponent(
            id: p.id,
            name: p.name,
            color: p.mtgColor.swatch,
          ))
      .toList();

  final panel = PlayerPanel(
    playerName: player.name,
    life: player.life,
    poison: player.poison,
    commanderTax: player.commanderTax,
    commanderDamage: player.commanderDamage,
    opponents: opponents,
    hapticsEnabled: hapticsEnabled,
    backgroundColor: player.mtgColor.swatch,
    rollResult: rollResult,
    rotationQuarterTurns: player.rotationQuarterTurns,
    onNameTap: () => _editPlayerName(context, ref, player),
    onRotateTap: () {
      ref.read(matchProvider.notifier).toggleRotation(
            playerId: player.id,
            autoRotated: rotate,
          );
    },
    onLifeDelta: (delta) {
      ref.read(matchProvider.notifier).applyDelta(
            playerId: player.id,
            type: CounterType.life,
            delta: delta,
          );
    },
    onPoisonDelta: (delta) {
      ref.read(matchProvider.notifier).applyDelta(
            playerId: player.id,
            type: CounterType.poison,
            delta: delta,
          );
    },
    onCommanderTaxDelta: (delta) {
      ref.read(matchProvider.notifier).applyDelta(
            playerId: player.id,
            type: CounterType.commanderTax,
            delta: delta,
          );
    },
    onCommanderDamageDelta: (sourcePlayerId, delta) {
      ref.read(matchProvider.notifier).applyDelta(
            playerId: player.id,
            type: CounterType.commanderDamage,
            delta: delta,
            sourcePlayerId: sourcePlayerId,
          );
    },
  );

  final override = player.rotationQuarterTurns;
  final turns = override ?? (rotate ? 2 : 0);
  if (turns == 0) return panel;
  return RotatedBox(
    quarterTurns: turns,
    child: panel,
  );
}

class _GridSpec {
  final int columns;
  final int rows;

  const _GridSpec(this.columns, this.rows);
}

_GridSpec _gridSpec(int playerCount) {
  if (playerCount <= 1) {
    return const _GridSpec(1, 1);
  }
  if (playerCount == 2) {
    return const _GridSpec(1, 2);
  }
  if (playerCount <= 4) {
    return const _GridSpec(2, 2);
  }
  return const _GridSpec(2, 3);
}

final _random = Random();
final rollResultsProvider = StateProvider<Map<String, int>>((ref) => {});

Future<void> _showDiceRoller(
  BuildContext context,
  WidgetRef ref,
  bool hapticsEnabled,
) async {
  _maybeHaptic(hapticsEnabled);
  final match = ref.read(matchProvider).match;
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return _DiceRollerSheet(
        playerNames: match.players.map((p) => p.name).toList(),
        hapticsEnabled: hapticsEnabled,
        onRollForPlayers: (sides) {
          final results = <String, int>{};
          for (final player in match.players) {
            results[player.id] = _rollDie(sides);
          }
          ref.read(rollResultsProvider.notifier).state = results;
          Future.delayed(const Duration(seconds: 3), () {
            ref.read(rollResultsProvider.notifier).state = {};
          });
        },
      );
    },
  );
}

class _DiceRollerSheet extends StatelessWidget {
  final List<String> playerNames;
  final bool hapticsEnabled;
  final ValueChanged<int> onRollForPlayers;

  const _DiceRollerSheet({
    required this.playerNames,
    required this.hapticsEnabled,
    required this.onRollForPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Lançador de Dados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RollButton(
                label: 'D6',
                onPressed: () {
                  Navigator.of(context).pop();
                  onRollForPlayers(6);
                },
                hapticsEnabled: hapticsEnabled,
              ),
              _RollButton(
                label: 'D20',
                onPressed: () {
                  Navigator.of(context).pop();
                  onRollForPlayers(20);
                },
                hapticsEnabled: hapticsEnabled,
              ),
              _RollButton(
                label: 'Moeda',
                onPressed: () => _showRollResult(
                  context,
                  _random.nextBool() ? 'Cara' : 'Coroa',
                  hapticsEnabled,
                ),
                hapticsEnabled: hapticsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RollButton(
            label: 'Rolar para decidir quem começa',
            isWide: true,
            hapticsEnabled: hapticsEnabled,
            onPressed: () {
              final results = <String, int>{};
              for (final name in playerNames) {
                results[name] = _rollDie(20) as int;
              }
              final sorted = results.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final text = sorted
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
              _showRollResult(
                context,
                text,
                hapticsEnabled,
                title: 'Resultados (D20)',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RollButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isWide;
  final bool hapticsEnabled;

  const _RollButton({
    required this.label,
    required this.onPressed,
    this.isWide = false,
    required this.hapticsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWide ? double.infinity : null,
      child: FilledButton.tonal(
        onPressed: () {
          _maybeHaptic(hapticsEnabled);
          onPressed();
        },
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

int _rollDie(int sides) => _random.nextInt(sides) + 1;

Future<void> _showRollResult(
  BuildContext context,
  Object result,
  bool hapticsEnabled, {
  String title = 'Resultado',
}) async {
  _maybeHaptic(hapticsEnabled);
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(
          result.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void _maybeHaptic(bool enabled) {
  if (!enabled) return;
  HapticFeedback.lightImpact();
}

Future<void> _showSettings(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final enabled = ref.watch(settingsProvider).hapticsEnabled;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Configurações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Feedback tátil'),
                  value: enabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setHapticsEnabled(value);
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _showQuickHistory(
  BuildContext context,
  Match match,
  bool hapticsEnabled,
) async {
  _maybeHaptic(hapticsEnabled);
  final byId = {for (final p in match.players) p.id: p.name};
  final events = match.history.reversed.take(10).toList();
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Histórico Recente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('Nenhum evento ainda.')
            else
              for (final event in events)
                ListTile(
                  dense: true,
                  leading: _eventBadge(event.type),
                  title: Text(_formatEvent(event, byId)),
                ),
          ],
        ),
      );
    },
  );
}

class _CenterHub extends StatelessWidget {
  final VoidCallback onOpen;

  const _CenterHub({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FloatingActionButton(
        heroTag: 'center_hub',
        onPressed: onOpen,
        child: const Icon(Icons.menu),
      ),
    );
  }
}

Future<void> _showHubMenu(
  BuildContext context,
  WidgetRef ref,
  Match match,
  bool hapticsEnabled,
) async {
  _maybeHaptic(hapticsEnabled);
  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Reset'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmReset(context, ref, hapticsEnabled);
              },
            ),
            ListTile(
              leading: const Icon(Icons.casino_outlined),
              title: const Text('Dados'),
              onTap: () {
                Navigator.of(context).pop();
                _showDiceRoller(context, ref, hapticsEnabled);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Jogadores'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.of(context).pop();
                _showSettings(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                Navigator.of(context).pop();
                _showQuickHistory(context, match, hapticsEnabled);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _confirmReset(
  BuildContext context,
  WidgetRef ref,
  bool hapticsEnabled,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Resetar partida'),
        content: const Text('Isso apagará a partida atual. Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    _maybeHaptic(hapticsEnabled);
    ref.read(matchProvider.notifier).resetMatch();
  }
}

Future<void> _editPlayerName(
  BuildContext context,
  WidgetRef ref,
  Player player,
) async {
  final controller = TextEditingController(text: player.name);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nome do jogador'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    ref.read(matchProvider.notifier).setPlayerName(
          playerId: player.id,
          name: controller.text,
        );
  }
}

Widget _eventBadge(CounterType type) {
  switch (type) {
    case CounterType.life:
      return const Icon(Icons.favorite, color: Colors.redAccent, size: 18);
    case CounterType.poison:
      return const Icon(Icons.opacity, color: Colors.purple, size: 18);
    case CounterType.commanderTax:
      return const Icon(Icons.local_atm, color: Colors.amber, size: 18);
    case CounterType.commanderDamage:
      return const Icon(Icons.shield, color: Colors.blueGrey, size: 18);
  }
}

String _formatEvent(
  CounterEvent event,
  Map<String, String> playerNames,
) {
  final player = playerNames[event.playerId] ?? event.playerId;
  final delta = event.delta as int;
  final sign = delta >= 0 ? '+' : '';
  switch (event.type) {
    case CounterType.life:
      return '$player: $sign$delta Vida (Total: ${event.newValue})';
    case CounterType.poison:
      return '$player: $sign$delta Veneno (Total: ${event.newValue})';
    case CounterType.commanderTax:
      return '$player: $sign$delta Taxa Cmdr (Total: ${event.newValue})';
    case CounterType.commanderDamage:
      final sourceId = event.sourcePlayerId as String?;
      final source = sourceId == null ? '?' : playerNames[sourceId] ?? sourceId;
      return '$player: $sign$delta Dano Cmdr de $source (Total: ${event.newValue})';
  }
}
