import 'package:flutter/material.dart';
import '../models/game_model.dart';

class NextPiecePreview extends StatelessWidget {
  final TetrisPiece piece;

  const NextPiecePreview({
    Key? key,
    required this.piece,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocks = piece.blocks;
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          blocks.length,
          (y) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              blocks[y].length,
              (x) => Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.all(1),
                color: blocks[y][x] == 1 ? piece.color : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
