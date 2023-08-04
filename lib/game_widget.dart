import 'package:flutter/material.dart';

import 'colors.dart';
import 'gameconstants.dart';
import 'gameboard.dart';
import 'gameboardanimator.dart';

class GameWidget extends StatefulWidget {
  final int size;
  final int viewSeconds;
  final Function? onLevelComplete;
  final Function? onLevelFailed;
  final Function? makeGameBoard;

  const GameWidget({
    Key? key,
    required this.size,
    this.viewSeconds = 2,
    this.onLevelComplete,
    this.onLevelFailed,
    this.makeGameBoard,
  }) : super(key: key);

  @override
  State createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  final GlobalKey key = GlobalKey();
  GameBoard gameBoard = GameBoard.transparent(5);

  GameBoard makeNewGameBoardDefault() {
    GameBoard gameBoard = GameBoard(widget.size);
    gameBoard.generateLevel();
    return gameBoard;
  }

  Future<void> startNewLevel(bool isInitialGeneration) async {
    if (!mounted) {
      return;
    }

    GameBoard oldGameBoard = gameBoard.copy();
    GameBoard newGameBoard = GameBoard(gameBoard.size);
    if (widget.makeGameBoard != null) {
      newGameBoard = widget.makeGameBoard!(gameBoard.size);
    } else {
      newGameBoard = makeNewGameBoardDefault();
    }

    GameBoardAnimator animator = GameBoardAnimator(oldGameBoard, newGameBoard);
    if (isInitialGeneration) {
      animator.interpolationOffset = 0;
      animator.animationTotalMs = 300;
    }

    while (!animator.isDone()) {
      setState(() {
        gameBoard = animator.getFrame();
      });
      animator.nextFrame();
      await Future.delayed(Duration(milliseconds: animator.waitMs()));
      if (!mounted) {
        return;
      }
    }

    setState(() {
      gameBoard = newGameBoard;
    });

    Future.delayed(Duration(seconds: widget.viewSeconds), () {
      if (!mounted) {
        return;
      }
      setState(() {
        gameBoard.phase = GamePhase.DRAWING_PATH;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    gameBoard = GameBoard.transparent(widget.size);
    startNewLevel(true);
  }

  void onPointerUpdate(PointerEvent event) {
    if (key.currentContext == null) {
      return;
    }

    RenderBox? referenceBox =
        key.currentContext!.findRenderObject() as RenderBox?;
    Offset localPosition = referenceBox!.globalToLocal(event.position);

    var xStep = referenceBox.size.width / gameBoard.size;
    var yStep = referenceBox.size.height / gameBoard.size;
    int x = (localPosition.dx / xStep).floor();
    int y = (localPosition.dy / yStep).floor();

    if (x >= 0 && x < gameBoard.size && y >= 0 && y < gameBoard.size) {
      onCellTap(x, y);
    }
  }

  void onCellTap(int x, int y) {
    if (gameBoard.phase != GamePhase.DRAWING_PATH) {
      return;
    }

    CellType value = gameBoard.getValue(x, y);
    if (value == CellType.BOMB) {
      setState(() {
        gameBoard.phase = GamePhase.LEVEL_FAILED;
      });
      if (widget.onLevelFailed != null) {
        widget.onLevelFailed!();
      }
      Future.delayed(const Duration(seconds: 2), () {
        startNewLevel(false);
      });
      return;
    }

    if (value != CellType.EMPTY) {
      return;
    }

    setState(() {
      if (gameBoard.lastPlacedCellType == CellType.VISITED) {
        if (gameBoard.isValidPath(x, y)) {
          gameBoard.setValue(x, y, CellType.VISITED);
        } else if (gameBoard.isClosedPath(x, y)) {
          gameBoard.setValue(x, y, CellType.GOAL);
        }
      } else {
        if (gameBoard.isClosedPath(x, y)) {
          gameBoard.setValue(x, y, CellType.GOAL);
        } else if (gameBoard.isValidPath(x, y)) {
          gameBoard.setValue(x, y, CellType.VISITED);
        }
      }

      if (gameBoard.isCompleted()) {
        gameBoard.phase = GamePhase.LEVEL_COMPLETE;
        if (widget.onLevelComplete != null) {
          widget.onLevelComplete!();
        }
        Future.delayed(const Duration(seconds: 1), () {
          startNewLevel(false);
        });
      }
    });
  }

  Widget makeButtonGrid() {
    return Container(
      color: Theme.of(context).colorScheme.tertiary,
      padding: const EdgeInsets.all(2.0),
      child: Listener(
        onPointerDown: onPointerUpdate,
        onPointerMove: onPointerUpdate,
        child: GridView.count(
          shrinkWrap: true,
          key: key,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: gameBoard.size,
          childAspectRatio: 1 / 1,
          children: List.generate(gameBoard.area(), (index) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: GameCell(
                value: gameBoard.getVisibleValue(
                  index % gameBoard.size,
                  index ~/ gameBoard.size,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return makeButtonGrid();
  }
}

class GameCell extends StatelessWidget {
  final CellType value;

  const GameCell({
    Key? key,
    required this.value,
  }) : super(key: key);

  Color valueToColor(BuildContext context) {
    switch (value) {
      case CellType.TRANSPARENT:
        return Theme.of(context).colorScheme.tertiary;
      case CellType.EMPTY:
        return white;
      case CellType.VISITED:
        return logoYellow;
      case CellType.GOAL:
        return logoGreen;
      case CellType.BOMB:
        return logoRed;
      default:
        return white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: valueToColor(context),
      ),
    );
  }
}
