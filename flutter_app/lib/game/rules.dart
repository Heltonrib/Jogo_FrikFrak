enum GameMode { pvp, pve }
enum Difficulty { easy, hard }
enum MoveRule { adjacent, free }

enum Player { o, x }

Player other(Player p) => p == Player.o ? Player.x : Player.o;

String playerLabel(Player p) => p == Player.o ? 'O' : 'X';
