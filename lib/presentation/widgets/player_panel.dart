import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerPanel extends StatefulWidget {
  final String playerName;
  final int life;
  final int poison;
  final int commanderTax;
  final Map<String, int> commanderDamage;
  final List<Opponent> opponents;
  final bool hapticsEnabled;
  final Color backgroundColor;
  final int? rollResult;
  final ValueChanged<int> onLifeDelta;
  final ValueChanged<int> onPoisonDelta;
  final ValueChanged<int> onCommanderTaxDelta;
  final void Function(String sourcePlayerId, int delta) onCommanderDamageDelta;
  final VoidCallback? onRotateTap;
  final VoidCallback? onNameTap;
  final int? rotationQuarterTurns;

  const PlayerPanel({
    super.key,
    required this.playerName,
    required this.life,
    required this.poison,
    required this.commanderTax,
    required this.commanderDamage,
    required this.opponents,
    required this.hapticsEnabled,
    required this.backgroundColor,
    required this.rollResult,
    required this.onLifeDelta,
    required this.onPoisonDelta,
    required this.onCommanderTaxDelta,
    required this.onCommanderDamageDelta,
    this.onRotateTap,
    this.onNameTap,
    this.rotationQuarterTurns,
  });

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> {
  bool _showSecondary = false;

  void _toggleSecondary() {
    _maybeHaptic(widget.hapticsEnabled);
    setState(() {
      _showSecondary = !_showSecondary;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _foregroundFor(widget.backgroundColor);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: widget.backgroundColor,
          ),
        ),
        if (widget.rollResult == null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! > 600) {
                  _maybeHaptic(widget.hapticsEnabled);
                  widget.onLifeDelta(-10);
                } else if (details.primaryVelocity! < -600) {
                  _maybeHaptic(widget.hapticsEnabled);
                  widget.onLifeDelta(10);
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _maybeHaptic(widget.hapticsEnabled);
                        widget.onLifeDelta(1);
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _maybeHaptic(widget.hapticsEnabled);
                        widget.onLifeDelta(-1);
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Center(
          child: widget.rollResult == null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SideAdjustButton(
                      label: '-',
                      color: textColor.withOpacity(0.9),
                      onPressed: () {
                        _maybeHaptic(widget.hapticsEnabled);
                        widget.onLifeDelta(-1);
                      },
                    ),
                    const SizedBox(width: 16),
                    _OutlinedText(
                      text: '${widget.life}',
                      fontSize: 84,
                      color: textColor,
                    ),
                    const SizedBox(width: 16),
                    _SideAdjustButton(
                      label: '+',
                      color: textColor.withOpacity(0.9),
                      onPressed: () {
                        _maybeHaptic(widget.hapticsEnabled);
                        widget.onLifeDelta(1);
                      },
                    ),
                  ],
                )
              : _RollBadge(
                  value: widget.rollResult!,
                  foreground: textColor,
                ),
        ),
        Positioned(
          left: 12,
          top: 10,
          child: GestureDetector(
            onTap: widget.onNameTap,
            child: _OutlinedText(
              text: widget.playerName,
              fontSize: 20,
              color: textColor.withOpacity(0.95),
              strokeWidth: textColor == Colors.black ? 2 : 4,
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 6,
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onRotateTap == null
                    ? null
                    : () {
                        _maybeHaptic(widget.hapticsEnabled);
                        widget.onRotateTap?.call();
                      },
                tooltip: _rotationTooltip(widget.rotationQuarterTurns),
                icon: const Icon(Icons.screen_rotation_alt_outlined),
                color: textColor.withOpacity(0.9),
              ),
              IconButton(
                onPressed: _toggleSecondary,
                tooltip: 'Contadores',
                icon: const Icon(Icons.more_horiz),
                color: textColor.withOpacity(0.9),
              ),
            ],
          ),
        ),
        if (_showSecondary)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _SecondaryOverlay(
              poison: widget.poison,
              commanderTax: widget.commanderTax,
              commanderDamage: widget.commanderDamage,
              opponents: widget.opponents,
              hapticsEnabled: widget.hapticsEnabled,
              onPoisonDelta: widget.onPoisonDelta,
              onCommanderTaxDelta: widget.onCommanderTaxDelta,
              onCommanderDamageDelta: widget.onCommanderDamageDelta,
            ),
          ),
      ],
    );
  }
}

class _SecondaryOverlay extends StatelessWidget {
  final int poison;
  final int commanderTax;
  final Map<String, int> commanderDamage;
  final List<Opponent> opponents;
  final bool hapticsEnabled;
  final ValueChanged<int> onPoisonDelta;
  final ValueChanged<int> onCommanderTaxDelta;
  final void Function(String sourcePlayerId, int delta) onCommanderDamageDelta;

  const _SecondaryOverlay({
    required this.poison,
    required this.commanderTax,
    required this.commanderDamage,
    required this.opponents,
    required this.hapticsEnabled,
    required this.onPoisonDelta,
    required this.onCommanderTaxDelta,
    required this.onCommanderDamageDelta,
  });

  @override
  Widget build(BuildContext context) {
    final overlayColor = Theme.of(context).colorScheme.surface.withOpacity(0.8);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: overlayColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _MiniCounter(
            label: 'Veneno',
            value: poison,
            hapticsEnabled: hapticsEnabled,
            onDelta: onPoisonDelta,
          ),
          const SizedBox(width: 12),
          _MiniCounter(
            label: 'Taxa',
            value: commanderTax,
            hapticsEnabled: hapticsEnabled,
            onDelta: onCommanderTaxDelta,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Dano de comandante',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              _maybeHaptic(hapticsEnabled);
              showModalBottomSheet<void>(
                context: context,
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CommanderDamageGrid(
                      opponents: opponents,
                      commanderDamage: commanderDamage,
                      hapticsEnabled: hapticsEnabled,
                      onDelta: onCommanderDamageDelta,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final String label;
  final int value;
  final bool hapticsEnabled;
  final ValueChanged<int> onDelta;

  const _MiniCounter({
    required this.label,
    required this.value,
    required this.hapticsEnabled,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            IconButton(
              iconSize: 18,
              onPressed: () {
                _maybeHaptic(hapticsEnabled);
                onDelta(-1);
              },
              icon: const Icon(Icons.remove),
            ),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              iconSize: 18,
              onPressed: () {
                _maybeHaptic(hapticsEnabled);
                onDelta(1);
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class Opponent {
  final String id;
  final String name;
  final Color color;

  const Opponent({
    required this.id,
    required this.name,
    required this.color,
  });
}

class _CommanderDamageGrid extends StatelessWidget {
  final List<Opponent> opponents;
  final Map<String, int> commanderDamage;
  final void Function(String sourcePlayerId, int delta) onDelta;
  final bool hapticsEnabled;

  const _CommanderDamageGrid({
    required this.opponents,
    required this.commanderDamage,
    required this.onDelta,
    required this.hapticsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (opponents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dano de Cmdr',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        for (final opponent in opponents)
          _CommanderDamageRow(
            opponent: opponent,
            value: commanderDamage[opponent.id] ?? 0,
            onDelta: onDelta,
            hapticsEnabled: hapticsEnabled,
          ),
      ],
    );
  }
}

class _CommanderDamageRow extends StatelessWidget {
  final Opponent opponent;
  final int value;
  final void Function(String sourcePlayerId, int delta) onDelta;
  final bool hapticsEnabled;

  const _CommanderDamageRow({
    required this.opponent,
    required this.value,
    required this.onDelta,
    required this.hapticsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      children: [
        Tooltip(
          message: opponent.name,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: opponent.color,
            child: Text(
              _opponentInitials(opponent.name),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _foregroundFor(opponent.color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            _maybeHaptic(hapticsEnabled);
            onDelta(opponent.id, -1);
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: textStyle),
        IconButton(
          onPressed: () {
            _maybeHaptic(hapticsEnabled);
            onDelta(opponent.id, 1);
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

String _rotationTooltip(int? rotationQuarterTurns) {
  if (rotationQuarterTurns == null) {
    return 'Rotação automática';
  }
  if (rotationQuarterTurns == 0) {
    return 'Forçar normal';
  }
  return 'Forçar 180°';
}

String _opponentInitials(String name) {
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

void _maybeHaptic(bool enabled) {
  if (!enabled) return;
  HapticFeedback.lightImpact();
}

Color _foregroundFor(Color background) {
  return background.computeLuminance() < 0.4
      ? Colors.white
      : Colors.black;
}

class _OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  final double strokeWidth;

  const _OutlinedText({
    required this.text,
    required this.fontSize,
    required this.color,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = color == Colors.black
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SideAdjustButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SideAdjustButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RollBadge extends StatelessWidget {
  final int value;
  final Color foreground;

  const _RollBadge({
    required this.value,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: foreground,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
