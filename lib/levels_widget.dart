import 'package:flutter/material.dart';
import 'package:perli/game_widget.dart';
import 'package:perli/gameboard.dart';

import 'levelmanager.dart';
import 'colors.dart';
import 'shop.dart';
import 'settings.dart';
import 'audiomanager.dart';

class LevelsWidget extends StatefulWidget {
  final AudioManager audioManager;

  const LevelsWidget({Key? key, required this.audioManager}) : super(key: key);

  @override
  State createState() => _LevelsWidgetState();
}

class _LevelsWidgetState extends State<LevelsWidget>
    with TickerProviderStateMixin {
  int? selectedLevel;
  bool playingLevel = false;
  bool levelFinished = false;
  bool levelFinishedWin = false;
  int secondsLeftWin = 0;
  int dieTimestamp = -1;
  int stageIndex = 0;
  int numStages = 0;
  bool gainedCoins = false;

  ScrollController scrollController = ScrollController();
  AnimationController? progressController;

  int getTimeLeft() {
    if (dieTimestamp == -1) {
      return -2;
    }

    int currTime = DateTime.now().millisecondsSinceEpoch;
    int difference = dieTimestamp - currTime;
    int secondsLeft = difference ~/ 1000;

    if (secondsLeft <= 0 && mounted) {
      setState(() {
        endLevel(-1);
      });
    }

    return secondsLeft;
  }

  void updateProgressbar() {
    if (progressController != null) {
      progressController!.dispose();
    }

    progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: getTimeLeft() + 1),
    )..addListener(() {
        setState(() {});
      });
    progressController!.reverse(from: 1);
  }

  void startLevel() {
    LevelDifficulty difficulty =
        LevelManager.getLevelDifficulty(selectedLevel!);
    int startSeconds = LevelManager.startSecondsFromDifficulty(difficulty);
    dieTimestamp = DateTime.now().millisecondsSinceEpoch + startSeconds * 1000;

    stageIndex = 0;
    levelFinished = false;
    levelFinishedWin = false;
    gainedCoins = false;

    playingLevel = true;
    updateProgressbar();
  }

  void endLevel(int secondsLeft) {
    if (!playingLevel) {
      return;
    }

    playingLevel = false;
    levelFinished = true;
    levelFinishedWin = secondsLeft >= 0;
    secondsLeftWin = secondsLeft;

    if (levelFinishedWin) {
      Setting levelsCompleted = Settings.getSetting('levels_completed');
      if (levelsCompleted.integerValue < selectedLevel! + 1) {
        levelsCompleted.value = selectedLevel! + 1;
        levelsCompleted.save();

        Setting coins = Settings.getSetting('coins');
        coins.setValue(coins.integerValue + secondsLeft);
        coins.save();
        gainedCoins = true;
      }
    }
  }

  Future<void> loadSettings() async {
    await Settings.load();
    await Shop.load();
    if (!mounted) {
      return;
    }

    setState(() {});

    int levelIndex = Settings.getSetting('levels_completed').integerValue;
    scrollTo(levelIndex);
  }

  Future<void> audioLoop() async {
    await loadSettings();
    await Future.wait([
      widget.audioManager.loadMultiple(AudioFile.buttons),
      widget.audioManager.load(AudioFile.level),
      Future.delayed(const Duration(seconds: 5))
    ]);

    if (mounted) {
      await widget.audioManager
          .play(AudioFile.level, isMusic: true, loop: true);
    }
  }

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController(
      keepScrollOffset: true,
      initialScrollOffset: 0,
    );

    audioLoop();
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

  Widget buildLevelsView(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
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
                children:
                    List.generate(LevelManager.numLevelsPerDifficulty, (index) {
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
                        widget.audioManager.playRandom(AudioFile.buttons);
                        setState(() {
                          selectedLevel = levelIndex;
                          levelFinished = false;
                          levelFinishedWin = false;
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
  }

  Widget buildLevelStartView(BuildContext context) {
    LevelDifficulty difficulty =
        LevelManager.getLevelDifficulty(selectedLevel!);
    String difficultyName = LevelManager.nameFromDifficulty(difficulty);
    Color difficultyColor = LevelManager.colorFromDifficulty(difficulty, true);
    int secondsPerStage =
        LevelManager.secondsPerStageFromDifficulty(difficulty);
    numStages = LevelManager.stagesFromDifficulty(difficulty);

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
          difficultyName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            color: difficultyColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.tertiary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You will have to complete $numStages unique stages before the time runs out. '
              'For each stage you complete, you will receive $secondsPerStage additional seconds. '
              'If the time runs out before you complete all 10 stages, you lose. '
              '\nHave fun and enjoy the level :)',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            widget.audioManager.playRandom(AudioFile.buttons);
            setState(() {
              startLevel();
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Start Level',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            widget.audioManager.playRandom(AudioFile.buttons);
            setState(() {
              selectedLevel = null;
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'View Levels',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLevelView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              "Stage ${stageIndex + 1}",
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            Text(
              "Time Left: ${getTimeLeft()}s",
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progressController!.value,
          valueColor: AlwaysStoppedAnimation<Color>(logoGreen),
        ),
        const SizedBox(height: 20),
        GameWidget(
          audioManager: widget.audioManager,
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
              bombsPercentage:
                  LevelManager.bombPercentageFromLevel(selectedLevel!),
            );

            return gameBoard;
          },
          onLevelComplete: () {
            stageIndex++;

            LevelDifficulty difficulty =
                LevelManager.getLevelDifficulty(selectedLevel!);
            int secondsPerStage =
                LevelManager.secondsPerStageFromDifficulty(difficulty);
            dieTimestamp += secondsPerStage * 1000;
            updateProgressbar();

            if (stageIndex >= numStages) {
              endLevel(getTimeLeft());
            }
          },
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.tertiary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Complete $numStages Stages before the time runs out. Good Luck!',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLevelCompleteFail(BuildContext context) {
    LevelDifficulty difficulty =
        LevelManager.getLevelDifficulty(selectedLevel!);
    String difficultyName = LevelManager.nameFromDifficulty(difficulty);
    Color difficultyColor = LevelManager.colorFromDifficulty(difficulty, true);
    int secondsPerStage =
        LevelManager.secondsPerStageFromDifficulty(difficulty);
    numStages = LevelManager.stagesFromDifficulty(difficulty);

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
          difficultyName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            color: difficultyColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.tertiary,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'You didn\'t make it. Sorry. But maybe next time?',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.tertiary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You will have to complete $numStages unique stages before the time runs out. '
              'For each stage you complete, you will receive $secondsPerStage additional seconds. '
              'If the time runs out before you complete all 10 stages, you lose (as you know). '
              '\nHave fun and enjoy the level :)',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            widget.audioManager.playRandom(AudioFile.buttons);
            setState(() {
              startLevel();
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Play Again',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            widget.audioManager.playRandom(AudioFile.buttons);
            setState(() {
              selectedLevel = null;
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'View Levels',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String getCoinsReceivedText() {
    if (!gainedCoins) return "";
    return "That means that you received $secondsLeftWin coins that you can now spend in the shop!";
  }

  Widget buildLevelCompleteSuccess(BuildContext context) {
    LevelDifficulty difficulty =
        LevelManager.getLevelDifficulty(selectedLevel!);
    String difficultyName = LevelManager.nameFromDifficulty(difficulty);
    Color difficultyColor = LevelManager.colorFromDifficulty(difficulty, true);
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
          difficultyName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            color: difficultyColor,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.tertiary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You made it! In the end, you had $secondsLeftWin '
              'seconds left. ${getCoinsReceivedText()}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedLevel! < LevelManager.numTotalLevels() - 1)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary),
            onPressed: () {
              widget.audioManager.playRandom(AudioFile.buttons);
              setState(() {
                levelFinished = false;
                levelFinishedWin = false;
                selectedLevel = selectedLevel! + 1;
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Next Level',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
        if (selectedLevel! < LevelManager.numTotalLevels() - 1)
          const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            widget.audioManager.playRandom(AudioFile.buttons);
            setState(() {
              selectedLevel = null;
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'View Levels',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLevel == null) {
      return buildLevelsView(context);
    } else if (levelFinished) {
      if (levelFinishedWin) {
        return buildLevelCompleteSuccess(context);
      } else {
        return buildLevelCompleteFail(context);
      }
    } else if (!playingLevel) {
      return buildLevelStartView(context);
    } else {
      return buildLevelView(context);
    }
  }

  @override
  void dispose() {
    progressController?.dispose();
    widget.audioManager.stopAll();
    super.dispose();
  }
}
