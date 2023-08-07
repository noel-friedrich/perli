import 'package:flutter/material.dart';

import 'colors.dart';
import 'gameconstants.dart';
import 'gameboard.dart';
import 'gameboardanimator.dart';
import 'settings.dart';
import 'shop.dart';
import 'audiomanager.dart';
import 'package:vibration/vibration.dart';

class GameWidget extends StatefulWidget {
  final int size;
  final int viewSeconds;
  final AudioManager audioManager;
  final Function? onLevelComplete;
  final Function? onLevelFailed;
  final Function? makeGameBoard;

  const GameWidget({
    Key? key,
    required this.size,
    required this.audioManager,
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
  AudioManager audioManager = AudioManager();
  bool failed = false;
  bool completed = false;

  GameBoard makeNewGameBoardDefault() {
    GameBoard gameBoard = GameBoard(widget.size);
    gameBoard.generateLevel();
    return gameBoard;
  }

  Future<void> startNewLevel(bool isInitialGeneration) async {
    failed = false;
    completed = false;

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

  Future<void> loadAudio() async {
    audioManager = widget.audioManager;

    List<String> allFiles = [];
    allFiles.addAll(AudioFile.wins);
    allFiles.add(AudioFile.fail);

    await audioManager.loadMultiple(allFiles);
  }

  @override
  void initState() {
    super.initState();
    gameBoard = GameBoard.transparent(widget.size);
    startNewLevel(true);

    loadAudio();
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

  Future<void> vibrate() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  void onCellTap(int x, int y) {
    if (gameBoard.phase != GamePhase.DRAWING_PATH) {
      return;
    }

    CellType value = gameBoard.getValue(x, y);
    if (value == CellType.BOMB && !failed) {
      audioManager.play(AudioFile.fail);

      if (Settings.getSetting("vibration_on_fail").booleanValue) {
        vibrate();
      }

      setState(() {
        gameBoard.phase = GamePhase.LEVEL_FAILED;
      });

      if (widget.onLevelFailed != null) {
        widget.onLevelFailed!();
      }

      Future.delayed(const Duration(seconds: 2), () {
        startNewLevel(false);
      });

      failed = true;
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

      if (gameBoard.isCompleted() && !completed) {
        gameBoard.phase = GamePhase.LEVEL_COMPLETE;
        audioManager.playRandom(AudioFile.wins);
        if (widget.onLevelComplete != null) {
          widget.onLevelComplete!();
        }
        Future.delayed(const Duration(seconds: 1), () {
          startNewLevel(false);
        });
        completed = true;
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

  String assetPath(ShopItem item) {
    switch (value) {
      case CellType.EMPTY:
        return item.whiteImagePath();
      case CellType.VISITED:
        return item.yellowImagePath();
      case CellType.GOAL:
        return item.greenImagePath();
      case CellType.BOMB:
        return item.redImagePath();
      default:
        return "assets/images/logo.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    ShopItem? selectedItem = Shop.getActive(ShopItemType.skin);

    if (value != CellType.TRANSPARENT && selectedItem != null) {
      return GestureDetector(
        // prevent scrolling
        onHorizontalDragUpdate: (_) {},
        onVerticalDragUpdate: (_) {},
        child: AnimatedContainer(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(assetPath(selectedItem)),
              fit: BoxFit.cover,
            ),
          ),
          curve: Curves.ease,
          duration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      return GestureDetector(
        // prevent scrolling
        onHorizontalDragUpdate: (_) {},
        onVerticalDragUpdate: (_) {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          color: valueToColor(context),
        ),
      );
    }
  }
}
