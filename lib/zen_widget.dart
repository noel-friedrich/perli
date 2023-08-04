import 'package:flutter/material.dart';
import 'package:perli/game_widget.dart';

import 'settings.dart';
import 'gameboard.dart';

class ZenWidget extends StatefulWidget {
  const ZenWidget({Key? key}) : super(key: key);

  @override
  State createState() => _ZenWidgetState();
}

class _ZenWidgetState extends State<ZenWidget> {
  Key gameKey = UniqueKey();

  Future<void> loadSettings() async {
    await Settings.load();
    if (!mounted) {
      return;
    }

    gameKey = UniqueKey();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 10),
                  const Text(
                    'Zen mode is a relaxing mode where you can play at your own pace. '
                    'You may customize it in the settings. Have fun!',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GameWidget(
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
        ],
      ),
    );
  }
}
