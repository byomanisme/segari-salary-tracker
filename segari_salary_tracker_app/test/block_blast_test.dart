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
        icon: Icons.wb_sunny_rounded,
        label: 'Lemon',
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
      // Pre-fill row 0 with 7 blocks
      for (int c = 0; c < 7; c++) {
        game.board[0][c] = Colors.blue;
      }

      // 8th block to complete row 0
      const dot = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.blue,
        icon: Icons.water_drop_rounded,
        label: 'Air Mineral',
      );
      game.currentPieces[0] = dot;

      final placed = game.placePiece(0, 0, 7);
      expect(placed, true);

      // Row 0 should be cleared (all nulls)!
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
      // Place a mystery bonus tile at (2, 5)
      game.bonusCells['2-5'] = const BonusTile(
        id: 'gift',
        label: 'Kado Segari',
        icon: Icons.card_giftcard_rounded,
        color: Colors.red,
        bonusPoints: 150,
      );

      // Pre-fill row 2 with 7 blocks
      for (int c = 0; c < 7; c++) {
        game.board[2][c] = Colors.green;
      }

      const dot = BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: Colors.green,
        icon: Icons.eco_rounded,
        label: 'Sawi',
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
  });
}
