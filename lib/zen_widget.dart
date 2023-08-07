import 'package:flutter/material.dart';
import 'package:perli/audiomanager.dart';
import 'package:perli/game_widget.dart';

import 'settings_page.dart';
import 'settings.dart';
import 'shop.dart';
import 'gameboard.dart';

class ZenWidget extends StatefulWidget {
  final AudioManager audioManager;

  const ZenWidget({Key? key, required this.audioManager}) : super(key: key);

  @override
  State createState() => _ZenWidgetState();
}

class _ZenWidgetState extends State<ZenWidget> {
  bool playing = false;
  Key gameKey = UniqueKey();
  AudioManager audioManager = AudioManager();

  Future<void> loadSettings() async {
    await Shop.load();
    await Settings.load();
    if (!mounted) {
      return;
    }

    gameKey = UniqueKey();
    setState(() {});
  }

  Future<void> audioLoop() async {
    await loadSettings();
    await Future.wait([
      audioManager.load(AudioFile.zenExtended),
    ]);
    if (mounted) {
      await audioManager.play(AudioFile.zenExtended, isMusic: true, loop: true);
    }
  }

  @override
  void initState() {
    super.initState();
    audioManager = widget.audioManager;
  }

  void startPlaying() {
    audioLoop();
    playing = true;
  }

  void stopPlaying() {
    audioManager.stopAll();
    playing = false;
  }

  @override
  Widget build(BuildContext context) {
    if (playing) {
      return ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          Card(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'Zen#${Settings.getSetting('zen_levels_completed').integerValue + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GameWidget(
            audioManager: audioManager,
            key: gameKey,
            size: Settings.getSetting('zen_mode_size').integerValue,
            viewSeconds: Settings.getSetting('zen_mode_view_time').integerValue,
            onLevelComplete: () {
              if (!mounted) {
                return;
              }

              Setting completed = Settings.getSetting('zen_levels_completed');
              completed.setValue(completed.integerValue + 1);
              completed.save();
              setState(() {});
            },
            makeGameBoard: (int size) {
              GameBoard gameBoard = GameBoard(size);
              gameBoard.generateLevel(
                bombsPercentage: Settings.getSetting("zen_mode_bomb_percentage")
                    .integerValue,
              );
              return gameBoard;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            onPressed: () {
              setState(() {
                stopPlaying();
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Customize',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      shrinkWrap: true,
      children: <Widget>[
        const SettingsWidget(
          sections: ["Zen-Mode"],
          physics: NeverScrollableScrollPhysics(),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiary),
          onPressed: () {
            setState(() {
              startPlaying();
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              'Start Zen Mode',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: const <Widget>[
                Text(
                  'Zen-Mode is a relaxing mode where you can play at your own pace. '
                  'You may customize it in the settings. Have fun!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  @override
  void dispose() {
    audioManager.stopAll();
    super.dispose();
  }
}
