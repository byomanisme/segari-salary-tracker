import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segari_salary_tracker_app/games/block_blast/block_blast_game.dart';
import 'package:segari_salary_tracker_app/games/block_blast/block_shape.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlockBlastGame Logic Tests', () {
    test('Initialization has clean 8x8 board, 3 pieces, level 1, timer, and bonus cells', () {
      final game = BlockBlastGame();
      expect(game.board.length, 8);
      expect(game.board[0].length, 8);
      expect(game.score, 0);
      expect(game.combo, 0);
      expect(game.level, 1);
      expect(game.remainingSeconds, 90);
      expect(game.isGameOver, false);
      expect(game.currentPieces.where((p) => p != null).length, 3);
      expect(game.bonusCells.isNotEmpty, true, reason: 'Mystery bonus tiles should spawn');
      game.dispose();
    });

    test('canPlace and placePiece places block and updates score', () {
      final game = BlockBlastGame();
      const dotShape = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.amber,
        emoji: '🌽',
        icon: Icons.wb_sunny_rounded,
        label: 'Jagung Manis',
      );
      game.currentPieces[0] = dotShape;

      expect(game.canPlace(dotShape, 0, 0), true);
      final success = game.placePiece(0, 0, 0);
      expect(success, true);
      expect(game.board[0][0], Colors.amber);
      expect(game.score, greaterThanOrEqualTo(10));
      expect(game.currentPieces[0], isNull);

      // Cannot place on occupied cell
      expect(game.canPlace(dotShape, 0, 0), false);
      game.dispose();
    });

    test('Full row fills and triggers BLAST line clear and combo', () {
      final game = BlockBlastGame();
      for (int c = 0; c < 7; c++) {
        game.board[0][c] = Colors.blue;
      }

      const dot = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.blue,
        emoji: '🥩',
        icon: Icons.restaurant_rounded,
        label: 'Daging Sapi',
      );
      game.currentPieces[0] = dot;

      final placed = game.placePiece(0, 0, 7);
      expect(placed, true);

      for (int c = 0; c < 8; c++) {
        expect(game.board[0][c], isNull, reason: 'Col $c should be cleared');
      }

      expect(game.combo, 1);
      expect(game.lastBlast, isNotNull);
      expect(game.lastBlast!.clearedRows, contains(0));
      expect(game.lastBlast!.randomBonus, greaterThan(0));
      game.dispose();
    });

    test('Clearing a row with a Mystery Bonus Tile awards special bonus points', () {
      final game = BlockBlastGame();
      game.bonusCells.clear();
      game.bonusCells['2-5'] = const BonusTile(
        id: 'gift',
        label: 'Kado Segari',
        icon: Icons.card_giftcard_rounded,
        color: Colors.red,
        bonusPoints: 150,
      );

      for (int c = 0; c < 7; c++) {
        game.board[2][c] = Colors.green;
      }

      const dot = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.green,
        emoji: '🥦',
        icon: Icons.eco_rounded,
        label: 'Brokoli',
      );
      game.currentPieces[0] = dot;

      final placed = game.placePiece(0, 2, 7);
      expect(placed, true);

      expect(game.lastBlast, isNotNull);
      expect(game.lastBlast!.specialBonusPoints, 150);
      expect(game.lastBlast!.collectedBonusTiles.length, 1);
      expect(game.lastBlast!.collectedBonusTiles.first.label, 'Kado Segari');
      game.dispose();
    });

    test('Slithering Mascot interaction awards bonus points', () {
      final game = BlockBlastGame();
      game.currentMascot = SlitheringMascot(
        skinId: 'caterpillar',
        name: 'Ulat Sayur Segari',
        emoji: '🐛',
        body: [const Point(3, 3), const Point(3, 2), const Point(3, 1)],
        direction: const Point(0, 1),
        bonusPoints: 75,
      );

      final pts = game.interactMascot(3, 3);
      expect(pts, 75);
      expect(game.score, 75);
      expect(game.currentMascot, isNull);
      game.dispose();
    });

    test('getSmartSet guarantees at least one fitting shape on non-full board', () {
      final game = BlockBlastGame();
      // Fill most of the board, leave top-left 2x2 open
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (r >= 2 || c >= 2) {
            game.board[r][c] = Colors.red;
          }
        }
      }

      final smartPieces = BlockShape.getSmartSet(game.board);
      expect(smartPieces.length, 3);
      final canFitAny = smartPieces.any((s) => s.canFitInBoard(game.board));
      expect(canFitAny, true, reason: 'Anti-deadlock smart spawner must guarantee at least one fitting piece');
      game.dispose();
    });

    test('reviveGame clears central 4x4 area and restores playability', () {
      final game = BlockBlastGame();
      // Fill entire board
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          game.board[r][c] = Colors.purple;
        }
      }
      game.isGameOver = true;
      expect(game.canRevive, true);

      game.reviveGame();

      expect(game.isGameOver, false);
      expect(game.canRevive, false);

      // Verify central 4x4 (rows 2..5, cols 2..5) is cleared
      for (int r = 2; r <= 5; r++) {
        for (int c = 2; c <= 5; c++) {
          expect(game.board[r][c], isNull);
        }
      }
      game.dispose();
    });

    test('Combo grace period maintains combo for 1 non-clearing move', () {
      final game = BlockBlastGame();
      // Set combo to 2
      game.combo = 2;
      game.comboGraceTurns = 1;

      // Place a dot in empty board that does not clear a row
      const dot = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.orange,
        emoji: '🥕',
        icon: Icons.agriculture_rounded,
        label: 'Wortel',
      );
      game.currentPieces[0] = dot;
      game.placePiece(0, 0, 0);

      // Combo is held due to grace period!
      expect(game.combo, 2);
      expect(game.comboGraceTurns, 0);

      // Next placement without clear resets combo
      game.currentPieces[0] = dot;
      game.placePiece(0, 0, 1);
      expect(game.combo, 0);
      game.dispose();
    });
  });
}
