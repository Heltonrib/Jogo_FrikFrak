import 'dart:async';

import 'package:flutter/material.dart';
import '../game/ai.dart';
import '../game/engine.dart';
import '../game/rules.dart';
import 'win_line_painter.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty difficulty;
  final MoveRule rule;

  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.rule,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final g = GameEngine();
  final ai = GameAI();

  bool aiThinking = false;
  Player? winner;
  bool draw = false;

  late final AnimationController winAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

  Player get human => Player.o;
  Player get bot => Player.x;

  bool get isAITurn => widget.mode == GameMode.pve && g.turn == bot;

  @override
  void dispose() {
    winAnim.dispose();
    super.dispose();
  }

  void reset() {
    setState(() {
      g.reset();
      aiThinking = false;
      winner = null;
      draw = false;
      winAnim.reset();
    });
  }

  void _autoPassIfNeeded() {
    // Segurança: se algum jogador já colocou 3 e o outro ainda não, passa a vez.
    if (!g.isPlacementPhase) return;
    final p = g.turn;
    if (g.placedCount(p) >= 3 && g.placedCount(other(p)) < 3) {
      g.nextTurn();
    }
  }

  Future<void> _checkEndAfterMove(Player p) async {
    if (g.isWin(p)) {
      setState(() {
        winner = p;
      });
      winAnim.forward(from: 0);
      await _showEndDialog();
      return;
    }

    if (g.isDrawByLimit()) {
      setState(() => draw = true);
      await _showEndDialog();
      return;
    }
  }

  Future<void> _showEndDialog() async {
    if (!mounted) return;

    final text = winner != null
        ? (winner == Player.o
            ? 'O venceu!'
            : (widget.mode == GameMode.pve ? 'A máquina venceu!' : 'X venceu!'))
        : 'Empate.';

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          title: const Text('Fim do jogo'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Menu'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                reset();
              },
              child: const Text('Jogar de novo'),
            ),
          ],
        );
      },
    );
  }

  void maybePlayAI() {
    if (!mounted) return;
    if (!isAITurn) return;
    if (aiThinking) return;
    if (winner != null || draw) return;

    aiThinking = true;

    Future.delayed(const Duration(milliseconds: 280), () async {
      if (!mounted) return;

      _autoPassIfNeeded();
      if (!isAITurn || winner != null || draw) {
        aiThinking = false;
        return;
      }

      final move = (widget.difficulty == Difficulty.easy)
          ? ai.bestMoveEasy(g, bot, widget.rule)
          : ai.bestMoveHard(g, bot, widget.rule);

      setState(() {
        g.applyMove(bot, move);
      });

      await _checkEndAfterMove(bot);
      if (winner != null || draw) {
        aiThinking = false;
        return;
      }

      setState(() {
        g.nextTurn();
      });

      aiThinking = false;
    });
  }

  Future<void> onTapCell(int idx) async {
    if (winner != null || draw) return;
    if (isAITurn) return;

    _autoPassIfNeeded();
    if (isAITurn) {
      maybePlayAI();
      return;
    }

    final p = g.turn;

    // 1) Fase de colocar
    if (g.isPlacementPhase) {
      if (g.placedCount(p) >= 3) {
        setState(() => g.nextTurn());
        maybePlayAI();
        return;
      }

      if (g.board[idx] == null) {
        setState(() => g.applyMove(p, Move(to: idx)));

        await _checkEndAfterMove(p);
        if (winner != null || draw) return;

        setState(() => g.nextTurn());
        maybePlayAI();
      }
      return;
    }

    // 2) Fase de mover
    if (g.selected == null) {
      if (g.board[idx] == p) {
        setState(() => g.selected = idx);
      }
      return;
    }

    final sel = g.selected!;

    // clicar numa peça tua -> muda seleção
    if (g.board[idx] == p) {
      setState(() => g.selected = idx);
      return;
    }

    // mover para vazio permitido
    if (g.board[idx] == null) {
      final legal = g.legalDestinationsFrom(sel, p, widget.rule);
      final ok = legal.contains(idx);

      if (!ok) {
        setState(() => g.selected = null);
        return;
      }

      setState(() => g.applyMove(p, Move(from: sel, to: idx)));

      await _checkEndAfterMove(p);
      if (winner != null || draw) return;

      setState(() => g.nextTurn());
      maybePlayAI();
    } else {
      setState(() => g.selected = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => maybePlayAI());

    final cs = Theme.of(context).colorScheme;

    final modeText = widget.mode == GameMode.pvp
        ? '2 Jogadores'
        : 'Vs Máquina (${widget.difficulty == Difficulty.easy ? 'Fácil' : 'Difícil'})';

    final ruleText = widget.rule == MoveRule.adjacent ? 'Adjacente' : 'Livre';

    final phase = g.isPlacementPhase ? 'Colocar' : 'Mover';

    final status = winner != null
        ? (winner == Player.o
            ? 'O venceu'
            : (widget.mode == GameMode.pve ? 'Máquina venceu' : 'X venceu'))
        : draw
            ? 'Empate'
            : 'Vez de ${playerLabel(g.turn)} · Fase: $phase';

    final instruction = winner != null || draw
        ? 'Podes jogar novamente ou voltar ao menu.'
        : g.isPlacementPhase
            ? 'Toque numa casa vazia para colocar a tua peça.'
            : (g.selected == null
                ? 'Toque numa peça tua para selecionar.'
                : 'Escolha um destino destacado.');

    final highlight = <int>{};
    if (g.isMovePhase && g.selected != null) {
      highlight.addAll(g.legalDestinationsFrom(g.selected!, g.turn, widget.rule));
    }

    final winColor = (winner == Player.x)
        ? Colors.red
        : (winner == Player.o)
            ? Colors.blue
            : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida'),
        actions: [
          IconButton(
            tooltip: 'Reiniciar',
            onPressed: reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.sports_esports, size: 18),
                        label: Text(modeText),
                      ),
                      Chip(
                        avatar: const Icon(Icons.rule, size: 18),
                        label: Text('Mov.: $ruleText'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (aiThinking)
                              Row(
                                children: const [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Máquina...'),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(instruction, style: TextStyle(color: Colors.black.withOpacity(0.7))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _CounterChip(label: 'O', value: '${g.placedO}/3', color: Colors.blue),
                            const SizedBox(width: 10),
                            _CounterChip(label: 'X', value: '${g.placedX}/3', color: Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedBuilder(
                        animation: winAnim,
                        builder: (_, __) {
                          return Stack(
                            children: [
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: 9,
                                itemBuilder: (context, idx) {
                                  final v = g.board[idx];
                                  final isSel = g.selected == idx;
                                  final isHi = highlight.contains(idx);

                                  final bg = isHi
                                      ? cs.tertiaryContainer.withOpacity(0.45)
                                      : cs.surfaceContainerHighest.withOpacity(0.55);

                                  final borderColor = isSel
                                      ? Colors.orange
                                      : isHi
                                          ? cs.tertiary
                                          : Colors.black26;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => onTapCell(idx),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOut,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: bg,
                                        border: Border.all(
                                          width: isSel ? 3 : 1.5,
                                          color: borderColor,
                                        ),
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 180),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                                          child: Text(
                                            v == null ? '' : playerLabel(v),
                                            key: ValueKey(v == null ? 'empty-$idx' : '${playerLabel(v)}-$idx'),
                                            style: TextStyle(
                                              fontSize: 60,
                                              fontWeight: FontWeight.w900,
                                              color: v == Player.x ? Colors.red : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: WinLinePainter(
                                    winLineIndex: g.winningLineIndex,
                                    progress: winAnim.value,
                                    color: winColor,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Menu'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reiniciar'),
                        onPressed: reset,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CounterChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(value),
        ],
      ),
    );
  }
}
