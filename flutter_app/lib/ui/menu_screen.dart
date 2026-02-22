import 'package:flutter/material.dart';
import '../game/rules.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  GameMode mode = GameMode.pve;
  Difficulty difficulty = Difficulty.easy;
  MoveRule rule = MoveRule.adjacent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frik Frak'),
        actions: [
          IconButton(
            tooltip: 'Ajuda',
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.grid_3x3, color: cs.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Coloca 3 peças (O e X).\n'
                          'Se ninguém vencer, começa a fase de mover até alinhar 3.',
                          style: TextStyle(fontSize: 15, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _SectionTitle('Modo de jogo'),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<GameMode>(
                        segments: const [
                          ButtonSegment(
                            value: GameMode.pvp,
                            label: Text('2 Jogadores'),
                            icon: Icon(Icons.people),
                          ),
                          ButtonSegment(
                            value: GameMode.pve,
                            label: Text('Vs Máquina'),
                            icon: Icon(Icons.smart_toy),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) => setState(() => mode = s.first),
                      ),
                      const SizedBox(height: 12),

                      if (mode == GameMode.pve) ...[
                        const Text('Dificuldade', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        SegmentedButton<Difficulty>(
                          segments: const [
                            ButtonSegment(value: Difficulty.easy, label: Text('Fácil')),
                            ButtonSegment(value: Difficulty.hard, label: Text('Difícil')),
                          ],
                          selected: {difficulty},
                          onSelectionChanged: (s) => setState(() => difficulty = s.first),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          difficulty == Difficulty.easy
                              ? 'Fácil: a máquina joga de forma simples.'
                              : 'Difícil: a máquina joga mais inteligente (minimax).',
                          style: TextStyle(color: Colors.black.withOpacity(0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _SectionTitle('Regras'),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Movimento', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SegmentedButton<MoveRule>(
                        segments: const [
                          ButtonSegment(value: MoveRule.adjacent, label: Text('Adjacente')),
                          ButtonSegment(value: MoveRule.free, label: Text('Livre')),
                        ],
                        selected: {rule},
                        onSelectionChanged: (s) => setState(() => rule = s.first),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rule == MoveRule.adjacent
                            ? 'Adjacente: move apenas para casas vizinhas (mais estratégico).'
                            : 'Livre: move para qualquer casa vazia (mais rápido).',
                        style: TextStyle(color: Colors.black.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar partida'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        mode: mode,
                        difficulty: difficulty,
                        rule: rule,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const _HelpSheet(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Como jogar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 10),
          Text('1) Cada jogador coloca 3 peças (O e X).'),
          Text('2) Se ninguém vencer, começa a fase de mover.'),
          Text('3) Toca numa peça tua → toca no destino permitido.'),
          Text('4) Alinha 3 para vencer.'),
          SizedBox(height: 10),
          Text('Dica: em “Adjacente” o jogo fica mais estratégico.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
