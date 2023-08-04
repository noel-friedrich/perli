import 'package:flutter/material.dart';
import 'package:perli/game_widget.dart';
import 'package:perli/gameboard.dart';

import 'levelmanager.dart';
import 'colors.dart';
import 'settings.dart';

class LevelsWidget extends StatefulWidget {
  const LevelsWidget({Key? key}) : super(key: key);

  @override
  State createState() => _LevelsWidgetState();
}

class _LevelsWidgetState extends State<LevelsWidget> {
  int? selectedLevel;
  ScrollController scrollController = ScrollController();

  Future<void> loadSettings() async {
    await Settings.load();
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadSettings();

    scrollController = ScrollController(
      keepScrollOffset: true,
      initialScrollOffset: 0,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }

      int levelIndex = Settings.getSetting('levels_completed').integerValue;
      scrollTo(levelIndex);
    });
  }

  void tellUser(String text) {
    // remove any existing snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void scrollTo(int levelIndex) {
    double offset = 0;
    if (levelIndex > 0) {
      offset = scrollController.position.maxScrollExtent *
          (levelIndex / LevelManager.numTotalLevels());
    }

    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLevel == null) {
      return ListView(
        padding: const EdgeInsets.all(20.0),
        controller: scrollController,
        children: [
          for (int i = 0; i < LevelDifficulty.values.length; i++)
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    '${LevelManager.nameFromDifficulty(LevelDifficulty.values[i])} Levels',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  childAspectRatio: 1 / 1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(LevelManager.numLevelsPerDifficulty,
                      (index) {
                    int levelIndex =
                        index + LevelManager.numLevelsPerDifficulty * i;
                    LevelDifficulty difficulty =
                        LevelManager.getLevelDifficulty(levelIndex);
                    bool isPlayable =
                        Settings.getSetting('levels_completed').integerValue >=
                            levelIndex;
                    return Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isPlayable) {
                            tellUser(
                                'You must complete all previous levels to unlock a level.');
                            return;
                          }
                          setState(() {
                            selectedLevel = levelIndex;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LevelManager.colorFromDifficulty(
                              difficulty, isPlayable),
                        ),
                        child: Text(
                          '${levelIndex + 1}',
                          style: TextStyle(fontSize: 15, color: black),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          const SizedBox(height: 10),
          Text(
            'Level ${selectedLevel! + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
            ),
          ),
          Text(
            LevelManager.nameFromDifficulty(
                LevelManager.getLevelDifficulty(selectedLevel!)),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              color: LevelManager.colorFromDifficulty(
                  LevelManager.getLevelDifficulty(selectedLevel!), true),
            ),
          ),
          const SizedBox(height: 20),
          GameWidget(
            size: 5,
            viewSeconds: LevelManager.viewSecondsFromDifficulty(
                LevelManager.getLevelDifficulty(selectedLevel!)),
            makeGameBoard: (int size) {
              if (selectedLevel == null) {
                return GameBoard.transparent(size);
              }

              LevelDifficulty difficulty =
                  LevelManager.getLevelDifficulty(selectedLevel!);
              GameBoard gameBoard =
                  GameBoard(LevelManager.sizeFromDifficulty(difficulty));
              gameBoard.generateLevel(
                seed: selectedLevel!,
                bombsPercentage:
                    LevelManager.bombPercentageFromLevel(selectedLevel!),
              );

              return gameBoard;
            },
            onLevelComplete: () {
              Setting levelsCompleted = Settings.getSetting('levels_completed');
              if (levelsCompleted.integerValue < selectedLevel! + 1) {
                levelsCompleted.value = selectedLevel! + 1;
                levelsCompleted.save();
              }

              if (mounted) {
                setState(() {
                  LevelDifficulty currentDifficulty =
                      LevelManager.getLevelDifficulty(selectedLevel!);
                  if (selectedLevel! < LevelManager.numTotalLevels() - 1) {
                    selectedLevel = selectedLevel! + 1;
                    LevelDifficulty newDifficulty =
                        LevelManager.getLevelDifficulty(selectedLevel!);
                    if (currentDifficulty != newDifficulty) {
                      selectedLevel = null;
                      tellUser(
                          'You have unlocked ${LevelManager.nameFromDifficulty(newDifficulty)} Levels!');
                    }
                  } else {
                    selectedLevel = null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedLevel = null;
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Back to Levels',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
