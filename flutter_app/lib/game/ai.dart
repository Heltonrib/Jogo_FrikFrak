import 'dart:math';
import 'engine.dart';
import 'rules.dart';

class GameAI {
  final _rnd = Random();

  Move bestMoveEasy(GameEngine g, Player ai, MoveRule rule) {
    final moves = g.generateMoves(ai, rule);
    if (moves.isEmpty) return const Move(to: 0);

    // 1) ganhar
    for (final m in moves) {
      final copy = _clone(g);
      copy.applyMove(ai, m);
      if (copy.isWin(ai)) return m;
    }

    // 2) bloquear (simples)
    final op = other(ai);
    final opMoves = g.generateMoves(op, rule);
    for (final om in opMoves) {
      final copy = _clone(g);
      copy.applyMove(op, om);
      if (copy.isWin(op)) {
        return moves[_rnd.nextInt(moves.length)];
      }
    }

    // 3) aleatório
    return moves[_rnd.nextInt(moves.length)];
  }

  Move bestMoveHard(GameEngine g, Player ai, MoveRule rule) {
    final moves = g.generateMoves(ai, rule);
    if (moves.isEmpty) return const Move(to: 0);

    int bestVal = -999999;
    Move best = moves.first;

    for (final m in moves) {
      final copy = _clone(g);
      copy.applyMove(ai, m);
      final val = _minimax(copy, ai, other(ai), rule, depth: 9, alpha: -999999, beta: 999999);
      if (val > bestVal) {
        bestVal = val;
        best = m;
      }
    }

    return best;
  }

  int _minimax(GameEngine g, Player me, Player turn, MoveRule rule,
      {required int depth, required int alpha, required int beta}) {
    if (g.isWin(me)) return 1000 + depth;
    if (g.isWin(other(me))) return -1000 - depth;
    if (depth == 0) return _heuristic(g, me);

    final moves = g.generateMoves(turn, rule);
    if (moves.isEmpty) return 0;

    int a = alpha;
    int b = beta;

    if (turn == me) {
      int best = -999999;
      for (final m in moves) {
        final copy = _clone(g);
        copy.applyMove(turn, m);
        final val = _minimax(copy, me, other(turn), rule, depth: depth - 1, alpha: a, beta: b);
        if (val > best) best = val;
        if (best > a) a = best;
        if (b <= a) break;
      }
      return best;
    } else {
      int best = 999999;
      for (final m in moves) {
        final copy = _clone(g);
        copy.applyMove(turn, m);
        final val = _minimax(copy, me, other(turn), rule, depth: depth - 1, alpha: a, beta: b);
        if (val < best) best = val;
        if (best < b) b = best;
        if (b <= a) break;
      }
      return best;
    }
  }

  int _heuristic(GameEngine g, Player me) {
    int score = 0;
    for (final line in GameEngine.lines) {
      int meCnt = 0, opCnt = 0, empty = 0;
      for (final idx in line) {
        final v = g.board[idx];
        if (v == me) {
          meCnt++;
        } else if (v == other(me)) {
          opCnt++;
        } else {
          empty++;
        }
      }
      if (meCnt == 2 && empty == 1) score += 30;
      if (opCnt == 2 && empty == 1) score -= 35;
      if (meCnt == 1 && empty == 2) score += 4;
      if (opCnt == 1 && empty == 2) score -= 4;
    }
    return score;
  }

  GameEngine _clone(GameEngine g) {
    final c = GameEngine();
    for (int i = 0; i < 9; i++) c.board[i] = g.board[i];
    c.turn = g.turn;
    c.placedO = g.placedO;
    c.placedX = g.placedX;
    c.selected = g.selected;
    c.plyCount = g.plyCount;
    c.winningLineIndex = g.winningLineIndex;
    return c;
  }
}
