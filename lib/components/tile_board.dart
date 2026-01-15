import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../const/colors.dart';
import '../const/colors_dark.dart';
import '../managers/board.dart';
import '../managers/settings.dart';
import 'animated_tile.dart';
import 'button.dart';

class TileBoardWidget extends ConsumerWidget {
  const TileBoardWidget(
      {super.key, required this.moveAnimation, required this.scaleAnimation});

  final CurvedAnimation moveAnimation;
  final CurvedAnimation scaleAnimation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(boardManager);
    final settings = ref.watch(settingsManager);
    final gridSize = settings.gridSize;
    final isDark = settings.isDarkMode;

    //Decides the maximum size the Board can be based on the shortest size of the screen.
    final size = max(
        290.0,
        min((MediaQuery.of(context).size.shortestSide * 0.90).floorToDouble(),
            460.0));

    //Decide the size of the tile based on the size of the board minus the space between each tile.
    final sizePerTile = (size / gridSize).floorToDouble();
    final tileSize = sizePerTile - 12.0 - (12.0 / gridSize);
    final boardSize = sizePerTile * gridSize;

    // Dynamic font size based on grid size
    final fontSize = gridSize == 3
        ? 28.0
        : gridSize == 4
            ? 24.0
            : gridSize == 5
                ? 20.0
                : 16.0;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: [
          ...List.generate(board.tiles.length, (i) {
            var tile = board.tiles[i];

            final tileColorMap = isDark ? tileColorsDark : tileColors;
            final txtColor = tile.value < 8
                ? (isDark ? textColorDark : textColor)
                : textColorWhite;

            return AnimatedTile(
              key: ValueKey(tile.id),
              tile: tile,
              moveAnimation: moveAnimation,
              scaleAnimation: scaleAnimation,
              size: tileSize,
              gridSize: gridSize,
              //In order to optimize performances and prevent unneeded re-rendering the actual tile is passed as child to the AnimatedTile
              //as the tile won't change for the duration of the movement (apart from it's position)
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                    color: tileColorMap[tile.value] ?? tileColorMap[2],
                    borderRadius: BorderRadius.circular(6.0)),
                child: Center(
                    child: Text(
                  '${tile.value}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: txtColor),
                )),
              ),
            );
          }),
          if (board.over)
            Positioned.fill(
                child: Container(
              color: isDark ? overlayColorDark : overlayColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    board.won ? 'You win!' : 'Game over!',
                    style: TextStyle(
                        color: isDark ? textColorDark : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 64.0),
                  ),
                  ButtonWidget(
                    text: board.won ? 'New Game' : 'Try again',
                    onPressed: () {
                      ref.read(boardManager.notifier).newGame();
                    },
                  )
                ],
              ),
            ))
        ],
      ),
    );
  }
}
