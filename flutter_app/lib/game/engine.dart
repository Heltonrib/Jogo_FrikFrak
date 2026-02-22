import 'rules.dart';

class Move {
  /// from == null => placing; else moving
  final int? from;
  final int to;
  const Move({this.from, required this.to});
}

class GameEngine {
  /// Board indices:
  /// 0 1 2
  /// 3 4 5
  /// 6 7 8
  final List<Player?> board = List<Player?>.filled(9, null);

  Player turn = Player.o;
  int placedO = 0;
  int placedX = 0;

  int? selected; // index da peça selecionada na fase de mover
  int plyCount = 0;

  int? winningLineIndex;

  static const List<List<int>> lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  // Adjacências (estilo Three Men's Morris)
  static const List<List<int>> adj = [
    [1, 3, 4],
    [0, 2, 4],
    [1, 5, 4],
    [0, 6, 4],
    [0, 1, 2, 3, 5, 6, 7, 8],
    [2, 8, 4],
    [3, 7, 4],
    [6, 8, 4],
    [5, 7, 4],
  ];

  bool get isPlacementPhase => placedO < 3 || placedX < 3;
  bool get isMovePhase => placedO == 3 && placedX == 3;

  int placedCount(Player p) => p == Player.o ? placedO : placedX;

  void reset() {
    for (var i = 0; i < board.length; i++) board[i] = null;
    turn = Player.o;
    placedO = 0;
    placedX = 0;
    selected = null;
    plyCount = 0;
    winningLineIndex = null;
  }

  bool isWin(Player p) {
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (board[l[0]] == p && board[l[1]] == p && board[l[2]] == p) {
        winningLineIndex = i;
        return true;
      }
    }
    return false;
  }

  bool isDrawByLimit() => plyCount >= 250;

  List<int> legalDestinationsFrom(int from, Player p, MoveRule rule) {
    if (board[from] != p) return const [];
    final List<int> res = [];
    if (rule == MoveRule.free) {
      for (int i = 0; i < 9; i++) {
        if (board[i] == null) res.add(i);
      }
    } else {
      for (final to in adj[from]) {
        if (board[to] == null) res.add(to);
      }
    }
    return res;
  }

  List<Move> generateMoves(Player p, MoveRule rule) {
    final moves = <Move>[];

    if (isPlacementPhase) {
      // Se este jogador já colocou 3, não pode colocar mais.
      if (placedCount(p) >= 3) return moves;

      for (int i = 0; i < 9; i++) {
        if (board[i] == null) moves.add(Move(to: i));
      }
      return moves;
    }

    // Fase mover
    for (int from = 0; from < 9; from++) {
      if (board[from] != p) continue;
      for (final to in legalDestinationsFrom(from, p, rule)) {
        moves.add(Move(from: from, to: to));
      }
    }

    return moves;
  }

  void applyMove(Player p, Move m) {
    if (m.from == null) {
      board[m.to] = p;
      if (p == Player.o) {
        placedO++;
      } else {
        placedX++;
      }
    } else {
      board[m.from!] = null;
      board[m.to] = p;
    }

    plyCount++;
  }

  void nextTurn() {
    turn = other(turn);
    selected = null;
  }
}
