import 'package:perli/audiomanager.dart';
import 'package:perli/gameboard.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'colors.dart';
import 'game_widget.dart';
import 'settings.dart';

class MinuteChallengePage extends StatelessWidget {
  final AudioManager audioManager;

  const MinuteChallengePage({Key? key, required this.audioManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("One Minute Challenge")),
      body: MinuteChallengeWidget(audioManager: audioManager),
    );
  }
}

class MinuteChallengeWidget extends StatefulWidget {
  final AudioManager audioManager;

  const MinuteChallengeWidget({Key? key, required this.audioManager})
      : super(key: key);

  @override
  _MinuteChallengeWidgetState createState() => _MinuteChallengeWidgetState();
}

class _MinuteChallengeWidgetState extends State<MinuteChallengeWidget>
    with TickerProviderStateMixin {
  int startTimerSeconds = 5;
  int currTimerSeconds = -1;
  bool startTimerCompleted = false;
  bool challengeRunning = false;
  AnimationController? progressController;
  int score = 0;
  int levelsCompleted = 0;
  int? lastLevelCompletedTime;
  bool challengeCompleted = false;

  AudioManager audioManager = AudioManager();
  bool audioHasLoaded = false;

  void startChallenge() {
    challengeRunning = true;
    progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(() {
        setState(() {});
      });
    progressController!.forward();
    lastLevelCompletedTime = DateTime.now().millisecondsSinceEpoch;
    audioManager.play(AudioFile.challenge, isMusic: true);
  }

  int scoreFromTime(int timeMs) {
    return (exp(-0.0006 * (timeMs - 2000)) * 200).toInt() + 100;
  }

  Future<void> startTimer() async {
    setState(() {
      currTimerSeconds = startTimerSeconds;
    });
    while (currTimerSeconds > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) {
        return;
      }

      setState(() {
        if (audioHasLoaded) {
          if (currTimerSeconds == startTimerSeconds) {
            audioManager.play(AudioFile.countdown);
          }
          currTimerSeconds--;
        }
      });
    }
    setState(() {
      startTimerCompleted = true;
      startChallenge();
    });
  }

  int getTimeLeft() {
    if (progressController == null) {
      return 60;
    }

    return 60 - (progressController!.value * 60).toInt();
  }

  Future<void> loadAudio() async {
    audioManager = widget.audioManager;
    await Settings.load();
    await audioManager.loadMultiple([
      AudioFile.challenge,
      AudioFile.countdown,
    ]);
    audioHasLoaded = true;
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    loadAudio();
  }

  int getCurrBoardBombPercentage() {
    if (levelsCompleted <= 3) {
      return 20 + Random().nextInt(10);
    }

    if (levelsCompleted <= 6) {
      return Random().nextInt(20) + 40;
    }

    return 40;
  }

  int getCurrBoardSize() {
    if (levelsCompleted <= 3) {
      return 5;
    }

    if (levelsCompleted <= 6) {
      return 6;
    }

    if (levelsCompleted <= 9) {
      return 7;
    }

    return 8;
  }

  Future<void> finishChallenge() async {
    if (progressController != null) {
      progressController!.stop();
    }

    await Settings.load();
    Setting highscore = Settings.getSetting("1_minute_challenge_highscore");
    if (highscore.integerValue < score) {
      highscore.value = score;
      await Settings.save();
    }

    challengeRunning = false;
    challengeCompleted = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!startTimerCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (audioHasLoaded)
                Text(
                  currTimerSeconds.toString(),
                  style: const TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!audioHasLoaded) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: const <Widget>[
                      Text(
                        'Play as many levels as you can in one minute! The more levels you play, the harder they get! You get more points for completing levels faster.',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (challengeRunning && getTimeLeft() == 0) {
      finishChallenge().then((_) {
        setState(() {});
      });
    }

    if (challengeRunning) {
      return ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                "Score: $score",
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
            audioManager: audioManager,
            size: 6,
            viewSeconds: 1,
            makeGameBoard: (int size) {
              size = getCurrBoardSize();
              GameBoard board = GameBoard(size);
              board.generateLevel(
                bombsPercentage: getCurrBoardBombPercentage(),
              );
              return board;
            },
            onLevelComplete: () {
              int msElapsed = DateTime.now().millisecondsSinceEpoch -
                  lastLevelCompletedTime!;
              score += scoreFromTime(msElapsed);
              levelsCompleted++;
              lastLevelCompletedTime = DateTime.now().millisecondsSinceEpoch;
            },
            onLevelFailed: () {
              if (levelsCompleted > 0) {
                levelsCompleted--;
              }
              lastLevelCompletedTime = DateTime.now().millisecondsSinceEpoch;
            },
          ),
          const SizedBox(height: 10),
          Card(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: const <Widget>[
                  Text(
                    'Play as many levels as you can in one minute! The more levels you play, the harder they get! You get more points for completing levels faster.',
                    style: TextStyle(
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

    if (challengeCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Score: $score",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Highscore: ${Settings.getSetting("1_minute_challenge_highscore").integerValue}",
                style: const TextStyle(
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    startTimerCompleted = false;
                    challengeRunning = false;
                    challengeCompleted = false;
                    score = 0;
                    levelsCompleted = 0;
                  });
                  startTimer();
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Play Again",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Text("Something went wrong! Please restart the app.");
  }

  @override
  void dispose() {
    audioManager.stopAll();
    progressController?.dispose();
    super.dispose();
  }
}
