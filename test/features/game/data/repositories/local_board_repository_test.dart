import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:piecemeal/piecemeal.dart' as pm;

import 'package:flutter_web_2048/core/enums/direction.dart';
import 'package:flutter_web_2048/features/game/data/datasources/board_datasource.dart';
import 'package:flutter_web_2048/features/game/data/repositories/local_board_repository.dart';
import 'package:flutter_web_2048/features/game/domain/entities/board.dart';
import 'package:flutter_web_2048/features/game/domain/entities/tile.dart';

class MockBoardDataSource extends Mock implements BoardDataSource {}

void main() {
  LocalBoardRepository repository;
  MockBoardDataSource mockDatasource;

  setUp(() {
    mockDatasource = MockBoardDataSource();
    repository = LocalBoardRepository(datasource: mockDatasource);
  });

  test('should throw when initialized with null argument', () async {
    // ACT & ASSERT
    expect(() => LocalBoardRepository(datasource: null), throwsA(isA<AssertionError>()));
  });

  group('getCurrentBoard', () {
    test('should return a board with 16 tiles', () async {
      // ARRANGE

      // ACT
      final actual = await repository.getCurrentBoard();
      // ASSERT
      expect(actual.tiles.length, 16);
    });
    test("should return a board with 14 empty tiles", () async {
      // ARRANGE

      // ACT
      final actual = await repository.getCurrentBoard();
      // ASSERT
      final emptyTiles = actual.tiles.where((tile) => tile == null);
      expect(emptyTiles.length, 14);
    });
    test("should return a board with 2 '2' tiles", () async {
      // ACT
      final actual = await repository.getCurrentBoard();
      // ASSERT
      final tiles2 = actual.tiles.where((tile) => tile?.value == 2);
      expect(tiles2.length, 2);
    });

    test('should return the same board on every call', () async {
      // ACT
      final firstActual = await repository.getCurrentBoard();
      final secondActual = await repository.getCurrentBoard();

      // ASSERT
      expect(firstActual, secondActual);
    });
  });

  group('resetBoard', () {
    test('should reset board. A new one should be generated after', () async {
      // ACT
      final boardBeforeReset = await repository.getCurrentBoard();
      await repository.resetBoard();
      final boardAfterReset = await repository.getCurrentBoard();

      // ASSERT
      expect(boardBeforeReset, isNot(equals(boardAfterReset)));
    });
  });

  group('updateBoard', () {
    test("should add a '2' or '4' tile each update if move is possible", () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final board = Board(tiles);

      const int x = 1;
      const int y = 0;

      // free tile should be able to move down
      final freeTile = Tile(2, x: x, y: y);
      board.tiles.set(x, y, freeTile);

      // starting board
      // |0|2|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|

      // ACT
      final actual = await repository.updateBoard(board, direction);

      // ASSERT
      expect(
          actual.tiles.where((tile) => tile != null && (tile.value == 2 || tile.value == 4)).length,
          2);
    });

    test("should return the same amount of empty tiles if move is not possible", () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final board = Board(tiles);

      const int x = 1;
      const int y = 3;

      // blocked tile should not be able to move down
      final blockedTile = Tile(2, x: x, y: y);
      board.tiles.set(x, y, blockedTile);

      // starting board
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|2|0|0|

      // ACT
      final actual = await repository.updateBoard(board, direction);

      // ASSERT
      expect(actual.tiles.where((tile) => tile == null).length, 15);
    });

    test(
        'should call datasource to save highscore when game is over and the score is higher than the previous one',
        () async {
      // ARRANGE
      const previousScore = 10;
      const newScore = 9000;
      final tiles =
          pm.Array2D<Tile>.generated(4, 4, (final int x, final int y) => Tile(2, x: x, y: y));

      // put '4' tiles in between
      tiles.set(1, 0, Tile(4, x: 1, y: 0));
      tiles.set(3, 0, Tile(4, x: 3, y: 0));
      tiles.set(0, 1, Tile(4, x: 0, y: 1));
      tiles.set(2, 1, Tile(4, x: 2, y: 1));
      tiles.set(1, 2, Tile(4, x: 1, y: 2));
      tiles.set(3, 2, Tile(4, x: 3, y: 2));
      tiles.set(0, 3, Tile(4, x: 0, y: 3));
      tiles.set(2, 3, Tile(4, x: 2, y: 3));

      final board = Board(tiles);
      board.score = newScore;

      // arrange mock
      when(mockDatasource.getHighscore()).thenAnswer((_) async => previousScore);
      when(mockDatasource.setHighscore(newScore));

      // ACT
      await repository.updateBoard(board, Direction.down);

      // ASSERT
      verify(mockDatasource.setHighscore(newScore)).called(1);
    });

    test(
        'should not call datasource to save highscore when game is over and the score is lower than the previous one',
        () async {
      // ARRANGE
      const previousScore = 9000;
      const newScore = 10;
      final tiles =
          pm.Array2D<Tile>.generated(4, 4, (final int x, final int y) => Tile(2, x: x, y: y));

      // put '4' tiles in between
      tiles.set(1, 0, Tile(4, x: 1, y: 0));
      tiles.set(3, 0, Tile(4, x: 3, y: 0));
      tiles.set(0, 1, Tile(4, x: 0, y: 1));
      tiles.set(2, 1, Tile(4, x: 2, y: 1));
      tiles.set(1, 2, Tile(4, x: 1, y: 2));
      tiles.set(3, 2, Tile(4, x: 3, y: 2));
      tiles.set(0, 3, Tile(4, x: 0, y: 3));
      tiles.set(2, 3, Tile(4, x: 2, y: 3));

      final board = Board(tiles);
      board.score = newScore;

      // arrange mock
      when(mockDatasource.getHighscore()).thenAnswer((_) => Future.value(previousScore));
      when(mockDatasource.setHighscore(newScore));

      // ACT
      await repository.updateBoard(board, Direction.down);

      // ASSERT
      verifyNever(mockDatasource.setHighscore(newScore));
    }, skip: true);

    group('merge', () {
      test("when 2 '2' are on the same row, direction is left and the merged tile move to the left",
          () async {
        // ARRANGE
        const direction = Direction.left;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int leftX = 0;
        const int rightX = 3;

        const int y = 3;

        final leftTile = Tile(2, x: leftX, y: y);
        board.tiles.set(leftX, y, leftTile);
        final rightTile = Tile(2, x: rightX, y: y);
        board.tiles.set(rightX, y, rightTile);

        // starting board
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|2|

        // ending board
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |4|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final mergedTile = actual.tiles.get(leftX, y);
        expect(mergedTile.value, 4);
      });

      test(
          "when 2 '2' are on the same row, direction is right and the merged tile move to the right",
          () async {
        // ARRANGE
        const direction = Direction.right;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int leftX = 0;
        const int rightX = 3;

        const int y = 3;

        final leftTile = Tile(2, x: leftX, y: y);
        board.tiles.set(leftX, y, leftTile);
        final rightTile = Tile(2, x: rightX, y: y);
        board.tiles.set(rightX, y, rightTile);

        // starting board
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|2|

        // ending board
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|4|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final mergedTile = actual.tiles.get(rightX, y);
        expect(mergedTile.value, 4);
      });

      test("when 2 '2' are on the same column, direction is down and the merged tile move down",
          () async {
        // ARRANGE
        const direction = Direction.down;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int topY = 0;
        const int bottomY = 3;

        const int x = 0;

        final topTile = Tile(2, x: x, y: topY);
        board.tiles.set(x, topY, topTile);
        final downTile = Tile(2, x: x, y: bottomY);
        board.tiles.set(x, bottomY, downTile);

        // starting board
        // |2|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|0|

        // ending board
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |4|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final mergedTile = actual.tiles.get(x, bottomY);
        expect(mergedTile.value, 4);
      });

      test("when 2 '2' are on the same column, direction is up and should move the merged tile up",
          () async {
        // ARRANGE
        const direction = Direction.up;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int topY = 0;
        const int bottomY = 3;

        const int x = 0;

        final topTile = Tile(2, x: x, y: topY);
        board.tiles.set(x, topY, topTile);
        final downTile = Tile(2, x: x, y: bottomY);
        board.tiles.set(x, bottomY, downTile);

        // starting board
        // |2|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|0|

        // ending board
        // |4|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final mergedTile = actual.tiles.get(x, topY);
        expect(mergedTile.value, 4);
      });
    });

    group('no merge', () {
      test("when 2 different tiles are on the same column, moving up", () async {
        // ARRANGE
        const direction = Direction.up;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int topY = 0;
        const int bottomY = 3;

        const int x = 0;

        final topTile = Tile(4, x: x, y: topY);
        board.tiles.set(x, topY, topTile);
        final downTile = Tile(2, x: x, y: bottomY);
        board.tiles.set(x, bottomY, downTile);

        // starting board
        // |4|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|0|

        // ending board
        // |4|0|0|0|
        // |2|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final stillTile = actual.tiles.get(0, 0);
        final movedTile = actual.tiles.get(0, 1);
        expect(stillTile.value, 4);
        expect(movedTile.value, 2);
      });
      test("when 2 different tiles are on the same column, moving down", () async {
        // ARRANGE
        const direction = Direction.down;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int topY = 0;
        const int bottomY = 3;

        const int x = 0;

        final topTile = Tile(4, x: x, y: topY);
        board.tiles.set(x, topY, topTile);
        final downTile = Tile(2, x: x, y: bottomY);
        board.tiles.set(x, bottomY, downTile);

        // starting board
        // |4|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |2|0|0|0|

        // ending board
        // |0|0|0|0|
        // |0|0|0|0|
        // |4|0|0|0|
        // |2|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final stillTile = actual.tiles.get(0, 3);
        final movedTile = actual.tiles.get(0, 2);
        expect(stillTile.value, 2);
        expect(movedTile.value, 4);
      });
      test("when 2 different tiles are on the same row, moving to the right", () async {
        // ARRANGE
        const direction = Direction.right;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int leftX = 0;
        const int rightX = 3;

        const int y = 0;

        final leftTile = Tile(4, x: leftX, y: y);
        board.tiles.set(leftX, y, leftTile);
        final rightTile = Tile(2, x: rightX, y: y);
        board.tiles.set(rightX, y, rightTile);

        // starting board
        // |4|0|0|2|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ending board
        // |0|0|4|2|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final stillTile = actual.tiles.get(3, 0);
        final movedTile = actual.tiles.get(2, 0);
        expect(stillTile.value, 2);
        expect(movedTile.value, 4);
      });
      test("when 2 different tiles are on the same row, moving to the left", () async {
        // ARRANGE
        const direction = Direction.left;

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final board = Board(tiles);

        const int leftX = 0;
        const int rightX = 3;

        const int y = 0;

        final leftTile = Tile(4, x: leftX, y: y);
        board.tiles.set(leftX, y, leftTile);
        final rightTile = Tile(2, x: rightX, y: y);
        board.tiles.set(rightX, y, rightTile);

        // starting board
        // |4|0|0|2|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ending board
        // |4|2|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ACT
        final actual = await repository.updateBoard(board, direction);

        // ASSERT
        final stillTile = actual.tiles.get(0, 0);
        final movedTile = actual.tiles.get(1, 0);
        expect(stillTile.value, 4);
        expect(movedTile.value, 2);
      });
    });
  });

  group('getHighscore', () {
    test('should call datasource', () async {
      // ACT
      await repository.getHighscore();
      // ASSERT
      verify(mockDatasource.getHighscore()).called(1);
    });

    test('should return datasource output', () async {
      // ARRANGE
      const int highscore = 70000;
      when(mockDatasource.getHighscore()).thenAnswer((_) async => highscore);

      // ACT
      final int actual = await repository.getHighscore();

      // ASSERT
      expect(actual, highscore);
    }, skip: true);
  });

  group('getPreviousBoard', () {
    test('should be initialized by getCurrentBoard function if not set yet', () async {
      // ARRANGE
      final currentBoard = await repository.getCurrentBoard();

      // ACT
      final actual = await repository.getPreviousBoard();

      // ASSERT
      final int actualBoardTilesCount = actual.tiles.where((tile) => tile != null).length;
      final int currentBoardTilesCount = currentBoard.tiles.where((tile) => tile != null).length;
      expect(actualBoardTilesCount == currentBoardTilesCount, true);
    });

    test('should not be initialized by getCurrentBoard function if already set', () async {
      // ARRANGE
      final currentBoard = await repository.getCurrentBoard();

      // ACT
      final actual = await repository.getPreviousBoard();

      // ASSERT
      expect(actual, isNot(equals(currentBoard)));
    });
    test('should be set on updateBoard function with the given board', () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final currentBoard = Board(tiles);

      const int x = 1;
      const int y = 0;

      // free tile should be able to move down
      final freeTile = Tile(2, x: x, y: y);
      currentBoard.tiles.set(x, y, freeTile);

      // starting board
      // |0|2|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      final newBoard = await repository.updateBoard(currentBoard, direction);

      // ACT
      final actual = await repository.getPreviousBoard();

      // ASSERT
      final int previousBoardTilesCount = actual.tiles.where((tile) => tile != null).length;
      final int newBoardTilesCount = newBoard.tiles.where((tile) => tile != null).length;

      // previous and new board are not the same
      expect(previousBoardTilesCount == newBoardTilesCount, false);
    });

    test('should return the same previous board on multiple call', () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final currentBoard = Board(tiles);

      const int x = 1;
      const int y = 0;

      // free tile should be able to move down
      final freeTile = Tile(2, x: x, y: y);
      currentBoard.tiles.set(x, y, freeTile);

      // starting board
      // |0|2|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      await repository.updateBoard(currentBoard, direction);

      // ACT
      final actual1 = await repository.getPreviousBoard();
      final actual2 = await repository.getPreviousBoard();

      // ASSERT
      final int previousBoardTilesCount1 = actual1.tiles.where((tile) => tile != null).length;
      final int previousBoardTilesCount2 = actual2.tiles.where((tile) => tile != null).length;

      // previous and new board are not the same
      expect(previousBoardTilesCount1, previousBoardTilesCount2);
    });

    test('should return the same previous board event after moving', () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final currentBoard = Board(tiles);

      const int x = 1;
      const int y = 0;

      // free tile should be able to move down
      final freeTile = Tile(2, x: x, y: y);
      currentBoard.tiles.set(x, y, freeTile);

      // starting board
      // |0|2|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|

      // ACT
      await repository.updateBoard(currentBoard, direction);
      final previous1 = await repository.getPreviousBoard();
      await repository.updateBoard(currentBoard, direction);
      final previous2 = await repository.getPreviousBoard();

      // ASSERT
      final int previousBoardTilesCount1 = previous1.tiles.where((tile) => tile != null).length;
      final int previousBoardTilesCount2 = previous2.tiles.where((tile) => tile != null).length;

      // previous and new board are not the same
      expect(previousBoardTilesCount1, previousBoardTilesCount2);
    });

    test('should clone the previous one to set it on the current one', () async {
      // ARRANGE
      const direction = Direction.down;

      final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
      final currentBoard = Board(tiles);

      const int x = 1;
      const int y = 0;

      // free tile should be able to move down
      final freeTile = Tile(2, x: x, y: y);
      currentBoard.tiles.set(x, y, freeTile);

      // starting board
      // |0|2|0|0|
      // |0|0|0|0|
      // |0|0|0|0|
      // |0|0|0|0|

      // ACT
      await repository.updateBoard(currentBoard, direction);
      final actual = await repository.getPreviousBoard();
      final current = await repository.getCurrentBoard();

      // ASSERT
      final int currentTilesCount = current.tiles.where((tile) => tile != null).length;
      final int previousBoardTilesCount = actual.tiles.where((tile) => tile != null).length;

      // previous and new board are not the same
      expect(currentTilesCount, previousBoardTilesCount);
    });

    test(
      'should return the previous board even when the board did not move',
      () async {
        // ARRANGE

        final tiles = pm.Array2D<Tile>.generated(4, 4, () {});
        final currentBoard = Board(tiles);

        const int x = 1;
        const int y = 0;

        // free tile should be able to move down
        final freeTile = Tile(2, x: x, y: y);
        currentBoard.tiles.set(x, y, freeTile);

        // starting board
        // |0|2|0|0|
        // |0|0|0|0|
        // |0|0|0|0|
        // |0|0|0|0|

        // ACT
        final movedBoard = await repository.updateBoard(currentBoard, Direction.down);
        // moving up should not update the board
        final notMovedBoard = await repository.updateBoard(movedBoard, Direction.up);
        final actual = await repository.getPreviousBoard();

        // ASSERT
        final notMovedBoardTilesCount = notMovedBoard.tiles.where((tile) => tile != null).length;
        final movedBoardTilesCount = movedBoard.tiles.where((tile) => tile != null).length;
        final actualTilesCount = actual.tiles.where((tile) => tile != null).length;

        // the previous board should be equal to the board that moved and not the board that did not move
        expect(movedBoardTilesCount, equals(actualTilesCount));
        expect(notMovedBoardTilesCount, isNot(equals(actualTilesCount)));
      },
      retry: 5,
    );

    test('should return currentBoard if previousBoard does not exist yet', () async {
      // ACT
      final actual = await repository.getPreviousBoard();

      // ASSERT
      // _currentBoard is not set yet so it should be null
      expect(actual, null);
    });
  });
}
