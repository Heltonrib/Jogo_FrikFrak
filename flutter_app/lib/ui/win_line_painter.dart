import 'package:flutter/material.dart';
import '../game/engine.dart';

class WinLinePainter extends CustomPainter {
  final int? winLineIndex;
  final double progress; // 0..1
  final Color color;

  WinLinePainter({
    required this.winLineIndex,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (winLineIndex == null) return;

    final line = GameEngine.lines[winLineIndex!];
    final a = line.first;
    final d = line.last;

    Offset centerOf(int idx) {
      final row = idx ~/ 3;
      final col = idx % 3;
      final cellW = size.width / 3;
      final cellH = size.height / 3;
      return Offset(col * cellW + cellW / 2, row * cellH + cellH / 2);
    }

    final p1 = centerOf(a);
    final p2 = centerOf(d);
    final current = Offset.lerp(p1, p2, progress)!;

    final paint = Paint()
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.75);

    canvas.drawLine(p1, current, paint);
  }

  @override
  bool shouldRepaint(covariant WinLinePainter oldDelegate) {
    return oldDelegate.winLineIndex != winLineIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
