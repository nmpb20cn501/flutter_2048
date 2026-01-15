import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/board.dart';
import '../models/tile.dart';
import 'grid_helper.dart';
import 'next_direction.dart';
import 'round.dart';
import 'settings.dart';
import 'sound_manager.dart';

class BoardManager extends StateNotifier<Board> {
  final Ref ref;

  BoardManager(this.ref) : super(Board.newGame(0, [])) {
    //Load the last saved state or start a new game.
    load();
  }

  // Get current grid helper based on settings
  GridHelper get _gridHelper {
    final gridSize = ref.read(settingsManager).gridSize;
    return GridHelper(gridSize);
  }

  // Get vertical order based on current grid size
  List<int> get _verticalOrder => _gridHelper.verticalOrder;

  void load() async {
    //Access the box and get the first item at index 0
    //which will always be just one item of the Board model
    //and here we don't need to call fromJson function of the board model
    //in order to construct the Board model
    //instead the adapter we added earlier will do that automatically.
    var box = await Hive.openBox<Board>('boardBox');
    var savedBoard = box.get(0);
    //If there is save locally, load it. Otherwise start a new game but keep the best score
    if (savedBoard != null) {
      state = savedBoard;
    } else {
      // Start new game with best = 0 for first time
      state = _newGame();
    }
  }

  // Create New Game state.
  Board _newGame() {
    // Keep the current best score when starting a new game
    int bestScore = state.best > state.score ? state.best : state.score;
    return Board.newGame(bestScore, [random([])]);
  }

  // Start New Game
  void newGame() {
    state = _newGame();
  }

  // Check whether the indexes are in the same row or column in the board.
  bool _inRange(index, nextIndex) {
    return _gridHelper.inRange(index, nextIndex);
  }

  Tile _calculate(Tile tile, List<Tile> tiles, direction) {
    final gridSize = _gridHelper.size;
    final verticalOrder = _verticalOrder;

    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;

    int index = vert ? verticalOrder[tile.index] : tile.index;
    int nextIndex =
        ((index + 1) / gridSize).ceil() * gridSize - (asc ? gridSize : 1);

    // If the list of the new tiles to be rendered is not empty get the last tile
    // and if that tile is in the same row as the curren tile set the next index for the current tile to be after the last tile
    if (tiles.isNotEmpty) {
      var last = tiles.last;
      // If user swipes vertically use the verticalOrder list to retrieve the up/down index else use the existing index
      var lastIndex = last.nextIndex ?? last.index;
      lastIndex = vert ? verticalOrder[lastIndex] : lastIndex;
      if (_inRange(index, lastIndex)) {
        // If the order is ascending set the tile after the last processed tile
        // If the order is descending set the tile before the last processed tile
        nextIndex = lastIndex + (asc ? 1 : -1);
      }
    }

    // Return immutable copy of the current tile with the new next index
    // which can either be the top left index in the row or the last tile nextIndex/index + 1
    return tile.copyWith(
        nextIndex: vert ? verticalOrder.indexOf(nextIndex) : nextIndex);
  }

  //Move the tile in the direction
  bool move(SwipeDirection direction) {
    final verticalOrder = _verticalOrder;

    bool asc =
        direction == SwipeDirection.left || direction == SwipeDirection.up;
    bool vert =
        direction == SwipeDirection.up || direction == SwipeDirection.down;
    // Sort the list of tiles by index.
    // If user swipes vertically use the verticalOrder list to retrieve the up/down index
    state.tiles.sort(((a, b) =>
        (asc ? 1 : -1) *
        (vert
            ? verticalOrder[a.index].compareTo(verticalOrder[b.index])
            : a.index.compareTo(b.index))));

    List<Tile> tiles = [];

    for (int i = 0, l = state.tiles.length; i < l; i++) {
      var tile = state.tiles[i];

      // Calculate nextIndex for current tile.
      tile = _calculate(tile, tiles, direction);
      tiles.add(tile);

      if (i + 1 < l) {
        var next = state.tiles[i + 1];
        // Assign current tile nextIndex or index to the next tile if its allowed to be moved.
        if (tile.value == next.value) {
          // If user swipes vertically use the verticalOrder list to retrieve the up/down index else use the existing index
          var index = vert ? verticalOrder[tile.index] : tile.index,
              nextIndex = vert ? verticalOrder[next.index] : next.index;
          if (_inRange(index, nextIndex)) {
            tiles.add(next.copyWith(nextIndex: tile.nextIndex));
            // Skip next iteration if next tile was already assigned nextIndex.
            i += 1;
            continue;
          }
        }
      }
    }

    // Assign immutable copy of the new board state and trigger rebuild.
    state = state.copyWith(tiles: tiles, undo: state);

    // Play move sound
    ref.read(soundManagerProvider).playMove();

    return true;
  }

  // Generates tiles at random place on the board
  Tile random(List<int> indexes) {
    final totalTiles = _gridHelper.totalTiles;
    var i = 0;
    var rng = Random();
    do {
      i = rng.nextInt(totalTiles);
    } while (indexes.contains(i));

    return Tile(const Uuid().v4(), 2, i);
  }

  //Merge tiles
  void merge() {
    List<Tile> tiles = [];
    var tilesMoved = false;
    var hasMerged = false; // Track if any tiles merged
    List<int> indexes = [];
    var score = state.score;

    for (int i = 0, l = state.tiles.length; i < l; i++) {
      var tile = state.tiles[i];

      var value = tile.value, merged = false;

      if (i + 1 < l) {
        //sum the number of the two tiles with same index and mark the tile as merged and skip the next iteration.
        var next = state.tiles[i + 1];
        if (tile.nextIndex == next.nextIndex ||
            tile.index == next.nextIndex && tile.nextIndex == null) {
          value = tile.value + next.value;
          merged = true;
          hasMerged = true; // Mark that a merge happened
          score += tile.value;
          i += 1;
        }
      }

      if (merged || tile.nextIndex != null && tile.index != tile.nextIndex) {
        tilesMoved = true;
      }

      tiles.add(tile.copyWith(
          index: tile.nextIndex ?? tile.index,
          nextIndex: null,
          value: value,
          merged: merged));
      indexes.add(tiles.last.index);
    }

    //If tiles got moved then generate a new tile at random position of the available positions on the board.
    if (tilesMoved) {
      tiles.add(random(indexes));
    }

    // Update best score if current score is higher
    int best = state.best;
    bool bestUpdated = false;
    if (score > best) {
      best = score;
      bestUpdated = true;
    }

    state = state.copyWith(score: score, best: best, tiles: tiles);

    // Play merge sound if tiles merged
    if (hasMerged) {
      ref.read(soundManagerProvider).playMerge();
    }

    // Save immediately if best score was updated
    if (bestUpdated) {
      save();
    }
  }

  //Finish round, win or loose the game.
  void _endRound() {
    final gridSize = _gridHelper.size;
    final totalTiles = _gridHelper.totalTiles;
    var gameOver = true, gameWon = false;
    List<Tile> tiles = [];

    //If there is no more empty place on the board
    if (state.tiles.length == totalTiles) {
      state.tiles.sort(((a, b) => a.index.compareTo(b.index)));

      for (int i = 0, l = state.tiles.length; i < l; i++) {
        var tile = state.tiles[i];

        //If there is a tile with 2048 then the game is won.
        if (tile.value == 2048) {
          gameWon = true;
        }

        var x = (i - (((i + 1) / gridSize).ceil() * gridSize - gridSize));

        if (x > 0 && i - 1 >= 0) {
          //If tile can be merged with left tile then game is not lost.
          var left = state.tiles[i - 1];
          if (tile.value == left.value) {
            gameOver = false;
          }
        }

        if (x < gridSize - 1 && i + 1 < l) {
          //If tile can be merged with right tile then game is not lost.
          var right = state.tiles[i + 1];
          if (tile.value == right.value) {
            gameOver = false;
          }
        }

        if (i - gridSize >= 0) {
          //If tile can be merged with above tile then game is not lost.
          var top = state.tiles[i - gridSize];
          if (tile.value == top.value) {
            gameOver = false;
          }
        }

        if (i + gridSize < l) {
          //If tile can be merged with the bellow tile then game is not lost.
          var bottom = state.tiles[i + gridSize];
          if (tile.value == bottom.value) {
            gameOver = false;
          }
        }
        //Set the tile merged: false
        tiles.add(tile.copyWith(merged: false));
      }
    } else {
      //There is still a place on the board to add a tile so the game is not lost.
      gameOver = false;
      for (var tile in state.tiles) {
        //If there is a tile with 2048 then the game is won.
        if (tile.value == 2048) {
          gameWon = true;
        }
        //Set the tile merged: false
        tiles.add(tile.copyWith(merged: false));
      }
    }

    state = state.copyWith(tiles: tiles, won: gameWon, over: gameOver);
  }

  //Mark the merged as false after the merge animation is complete.
  bool endRound() {
    //End round.
    _endRound();
    ref.read(roundManager.notifier).end();

    //If player moved too fast before the current animation/transition finished, start the move for the next direction
    var nextDirection = ref.read(nextDirectionManager);
    if (nextDirection != null) {
      move(nextDirection);
      ref.read(nextDirectionManager.notifier).clear();
      return true;
    }
    return false;
  }

  //undo one round only
  void undo() {
    if (state.undo != null) {
      state = state.copyWith(
          score: state.undo!.score,
          best: state.undo!.best,
          tiles: state.undo!.tiles);
    }
  }

  //Move the tiles using the arrow keys on the keyboard.
  bool onKey(KeyEvent event) {
    SwipeDirection? direction;
    if (HardwareKeyboard.instance
        .isLogicalKeyPressed(LogicalKeyboardKey.arrowRight)) {
      direction = SwipeDirection.right;
    } else if (HardwareKeyboard.instance
        .isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft)) {
      direction = SwipeDirection.left;
    } else if (HardwareKeyboard.instance
        .isLogicalKeyPressed(LogicalKeyboardKey.arrowUp)) {
      direction = SwipeDirection.up;
    } else if (HardwareKeyboard.instance
        .isLogicalKeyPressed(LogicalKeyboardKey.arrowDown)) {
      direction = SwipeDirection.down;
    }

    if (direction != null) {
      move(direction);
      return true;
    }
    return false;
  }

  void save() async {
    //Here we don't need to call toJson function of the board model
    //in order to convert the data to json
    //instead the adapter we added earlier will do that automatically.
    var box = await Hive.openBox<Board>('boardBox');
    try {
      box.putAt(0, state);
    } catch (e) {
      box.add(state);
    }
  }
}

final boardManager = StateNotifierProvider<BoardManager, Board>((ref) {
  return BoardManager(ref);
});
