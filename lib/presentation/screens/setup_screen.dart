import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/mtg_color.dart';
import '../providers/match_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _playerCount = 4;
  int _initialLife = 40;
  final List<TextEditingController> _nameControllers = [];
  final List<MtgColor> _colors = [];
  List<String> _recentNames = const [];

  @override
  void initState() {
    super.initState();
    final storage = ref.read(matchStorageProvider);
    _recentNames = storage.getRecentNames();
    final prefs = storage.getSetupPrefs();
    final prefPlayers = prefs['playerCount'] as int?;
    final prefLife = prefs['life'] as int?;
    final prefSlots = prefs['slots'];
    if (prefPlayers != null && prefPlayers >= 2 && prefPlayers <= 6) {
      _playerCount = prefPlayers;
    }
    if (prefLife == 20) {
      _initialLife = 20;
    } else if (prefLife == 30) {
      _initialLife = 30;
    } else if (prefLife == 40) {
      _initialLife = 40;
    }
    _syncPlayers(_playerCount);
    if (prefSlots is List) {
      for (var i = 0; i < _playerCount && i < prefSlots.length; i++) {
        final slot = prefSlots[i];
        if (slot is Map) {
          final name = slot['name']?.toString();
          final colorName = slot['color']?.toString();
          if (name != null && name.isNotEmpty) {
            _nameControllers[i].text = name;
          }
          final color = MtgColor.values.firstWhere(
            (c) => c.name == colorName,
            orElse: () => _colors[i],
          );
          _colors[i] = color;
        }
      }
    }
    _ensureUniqueColors();
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncPlayers(int count) {
    const palette = [
      MtgColor.white,
      MtgColor.blue,
      MtgColor.black,
      MtgColor.red,
      MtgColor.green,
      MtgColor.colorless,
    ];

    while (_nameControllers.length < count) {
      final index = _nameControllers.length;
      _nameControllers.add(
        TextEditingController(text: 'Jogador ${index + 1}'),
      );
      _colors.add(palette[index % palette.length]);
    }

    while (_nameControllers.length > count) {
      _nameControllers.removeLast().dispose();
      _colors.removeLast();
    }

    _ensureUniqueColors();
  }

  void _ensureUniqueColors() {
    const palette = [
      MtgColor.white,
      MtgColor.blue,
      MtgColor.black,
      MtgColor.red,
      MtgColor.green,
      MtgColor.colorless,
    ];

    final used = <MtgColor>{};
    for (var i = 0; i < _colors.length; i++) {
      final current = _colors[i];
      if (!used.contains(current)) {
        used.add(current);
        continue;
      }
      final replacement = palette.firstWhere(
        (c) => !used.contains(c),
        orElse: () => current,
      );
      _colors[i] = replacement;
      used.add(replacement);
    }
  }

  void _resolveColorConflict(int index, MtgColor newColor) {
    if (_colors[index] == newColor) return;
    _colors[index] = newColor;

    const palette = [
      MtgColor.white,
      MtgColor.blue,
      MtgColor.black,
      MtgColor.red,
      MtgColor.green,
      MtgColor.colorless,
    ];

    final used = <MtgColor>{};
    for (var i = 0; i < _colors.length; i++) {
      if (i == index) continue;
      used.add(_colors[i]);
    }

    for (var i = 0; i < _colors.length; i++) {
      if (i == index) continue;
      if (_colors[i] == newColor) {
        final replacement = palette.firstWhere(
          (c) => !used.contains(c) && c != newColor,
          orElse: () => newColor,
        );
        _colors[i] = replacement;
        used.add(replacement);
      }
    }
  }
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final controller = _nameControllers.removeAt(oldIndex);
      _nameControllers.insert(newIndex, controller);

      final color = _colors.removeAt(oldIndex);
      _colors.insert(newIndex, color);

      _ensureUniqueColors();
    });
  }

  bool get _hasDuplicateColors {
    final set = _colors.toSet();
    return set.length != _colors.length;
  }

  void _startMatch() {
    final seeds = <PlayerSeed>[];
    final slots = <Map<String, dynamic>>[];
    for (var i = 0; i < _playerCount; i++) {
      final rawName = _nameControllers[i].text.trim();
      final name = rawName.isEmpty ? 'Jogador ${i + 1}' : rawName;
      final color = _colors[i];
      seeds.add(
        PlayerSeed(
          name: name,
          color: color,
        ),
      );
      slots.add({
        'name': name,
        'color': color.name,
      });
    }

    ref.read(matchProvider.notifier).startNewMatch(
          life: _initialLife,
          players: seeds,
        );
    ref.read(matchStorageProvider).setSetupPrefs(
          playerCount: _playerCount,
          life: _initialLife,
          slots: slots,
        );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Partida'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Número de Jogadores',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _playerCount,
                    items: [
                      for (var i = 2; i <= 6; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('$i jogadores'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _playerCount = value;
                        _syncPlayers(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de Jogo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _LifeButton(
                        label: '20',
                        selected: _initialLife == 20,
                        onPressed: () {
                          setState(() {
                            _initialLife = 20;
                          });
                        },
                      ),
                      _LifeButton(
                        label: '30',
                        selected: _initialLife == 30,
                        onPressed: () {
                          setState(() {
                            _initialLife = 30;
                          });
                        },
                      ),
                      _LifeButton(
                        label: '40',
                        selected: _initialLife == 40,
                        onPressed: () {
                          setState(() {
                            _initialLife = 40;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jogadores (arraste para ordenar)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverReorderableList(
            itemCount: _playerCount,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey(_nameControllers[index]),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PlayerSetupCard(
                  index: index,
                  controller: _nameControllers[index],
                  recentNames: _recentNames,
                  selectedColor: _colors[index],
                  onColorSelected: (color) {
                    setState(() {
                      _resolveColorConflict(index, color);
                    });
                  },
                  isColorDisabled: (_) => false,
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _TablePreview(
                playerCount: _playerCount,
                names: _nameControllers.map((c) => c.text).toList(),
                colors: _colors,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _startMatch,
                    child: const Text('Iniciar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSetupCard extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final List<String> recentNames;
  final MtgColor selectedColor;
  final ValueChanged<MtgColor> onColorSelected;
  final bool Function(MtgColor) isColorDisabled;

  const _PlayerSetupCard({
    required this.index,
    required this.controller,
    required this.recentNames,
    required this.selectedColor,
    required this.onColorSelected,
    required this.isColorDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Jogador ${index + 1}')),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nome',
                suffixIcon: recentNames.isEmpty
                    ? null
                    : PopupMenuButton<String>(
                        tooltip: 'Sugestões',
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (value) => controller.text = value,
                        itemBuilder: (context) {
                          return [
                            for (final name in recentNames)
                              PopupMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                          ];
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final color in MtgColor.values)
                  ChoiceChip(
                    label: Text(color.label),
                    selected: selectedColor == color,
                    selectedColor: color.swatch,
                    onSelected: isColorDisabled(color)
                        ? null
                        : (_) => onColorSelected(color),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _LifeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 84,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: selected
              ? colorScheme.primary
              : colorScheme.surfaceVariant,
          foregroundColor: selected
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class _TablePreview extends StatelessWidget {
  final int playerCount;
  final List<String> names;
  final List<MtgColor> colors;

  const _TablePreview({
    required this.playerCount,
    required this.names,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final count = playerCount.clamp(1, 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Preview da Mesa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AspectRatio(
            aspectRatio: count <= 2 ? 1.6 : 1.2,
            child: _buildPreviewLayout(count),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewLayout(int count) {
    if (count == 3) {
      return Column(
        children: [
          Expanded(
            child: _previewTile(0, rotated: true),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _previewTile(1, rotated: false)),
                const SizedBox(width: 6),
                Expanded(child: _previewTile(2, rotated: false)),
              ],
            ),
          ),
        ],
      );
    }

    final grid = _previewGrid(count);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: grid.columns,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final row = index ~/ grid.columns;
        final rotated = grid.rows > 1 && row == 0;
        return _previewTile(index, rotated: rotated);
      },
    );
  }

  Widget _previewTile(int index, {required bool rotated}) {
    final name = index < names.length ? names[index] : 'Jogador ${index + 1}';
    final initials = _initials(name);
    final color = index < colors.length
        ? colors[index].swatch
        : MtgColor.colorless.swatch;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: rotated ? Colors.black87 : Colors.black26,
              width: rotated ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _previewTextColor(color),
              ),
            ),
          ),
        ),
        if (rotated)
          const Positioned(
            top: 4,
            right: 4,
            child: Icon(Icons.sync_alt, size: 14),
          ),
      ],
    );
  }
}

Color _previewTextColor(Color background) {
  return background.computeLuminance() < 0.4 ? Colors.white : Colors.black;
}

class _PreviewGrid {
  final int columns;
  final int rows;

  const _PreviewGrid(this.columns, this.rows);
}

_PreviewGrid _previewGrid(int count) {
  if (count <= 1) return const _PreviewGrid(1, 1);
  if (count == 2) return const _PreviewGrid(1, 2);
  if (count <= 4) return const _PreviewGrid(2, 2);
  return const _PreviewGrid(2, 3);
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts[0].substring(0, 1).toUpperCase();
  }
  final first = parts.first.substring(0, 1).toUpperCase();
  final last = parts.last.substring(0, 1).toUpperCase();
  return '$first$last';
}
