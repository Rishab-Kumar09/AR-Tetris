import 'package:flutter/material.dart';
import '../models/game_model.dart';

class TetrisGrid extends StatelessWidget {
  final List<List<Color?>> grid;
  final TetrisPiece? currentPiece;

  const TetrisGrid({
    Key? key,
    required this.grid,
    required this.currentPiece,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.5, // 10:20 grid
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        child: Column(
          children: List.generate(
            grid.length,
            (y) => Expanded(
              child: Row(
                children: List.generate(
                  grid[y].length,
                  (x) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getCellColor(x, y),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _getCellColor(int x, int y) {
    // Check if current piece occupies this cell
    if (currentPiece != null) {
      final blocks = currentPiece!.blocks;
      final pieceX = currentPiece!.x;
      final pieceY = currentPiece!.y;

      for (int blockY = 0; blockY < blocks.length; blockY++) {
        for (int blockX = 0; blockX < blocks[blockY].length; blockX++) {
          if (blocks[blockY][blockX] == 1 &&
              pieceX + blockX == x &&
              pieceY + blockY == y) {
            return currentPiece!.color;
          }
        }
      }
    }

    // Return the grid color if no current piece at this position
    return grid[y][x];
  }
}
