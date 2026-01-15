import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../const/colors.dart';
import '../const/colors_dark.dart';
import '../managers/settings.dart';

class EmptyBoardWidget extends ConsumerWidget {
  const EmptyBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final totalTiles = gridSize * gridSize;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
          color: isDark ? boardColorDark : boardColor,
          borderRadius: BorderRadius.circular(6.0)),
      child: Stack(
        children: List.generate(totalTiles, (i) {
          //Render the empty board in dynamic grid
          var x = ((i + 1) / gridSize).ceil();
          var y = x - 1;

          var top = y * (tileSize) + (x * 12.0);
          var z = (i - (gridSize * y));
          var left = z * (tileSize) + ((z + 1) * 12.0);

          return Positioned(
            top: top,
            left: left,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                  color: isDark ? emptyTileColorDark : emptyTileColor,
                  borderRadius: BorderRadius.circular(6.0)),
            ),
          );
        }),
      ),
    );
  }
}
