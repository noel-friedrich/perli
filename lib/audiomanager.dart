import 'package:just_audio/just_audio.dart';
import 'dart:math';
import 'settings.dart';

class PerliAudioPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PerliAudioPlayer();

  Future<void> load(String path) async {
    int numTries = 0;
    int maxTries = 3;

    // try to load the file
    for (numTries = 0; numTries < maxTries; numTries++) {
      try {
        await _audioPlayer.setAsset(path);
      } catch (e) {
        if (numTries >= maxTries - 1) {
          print("Failed to load audio file: '$path'");
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // wait for the player to be ready
    await _audioPlayer.playerStateStream
        .firstWhere((state) => state.processingState == ProcessingState.ready);

    print("Successfully loaded audio file: '$path'");
  }

  Future<void> play({
    bool isMusic = false,
    bool loop = false,
  }) {
    int volumePercent = 100;
    if (isMusic) {
      volumePercent = Settings.getSetting("music_volume").integerValue;
    } else {
      volumePercent = Settings.getSetting("sounds_volume").integerValue;
    }

    if (volumePercent == 0) {
      return Future.value();
    }

    double volume = volumePercent / 100.0;
    _audioPlayer.setVolume(volume);

    if (loop) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }

    // always play from the beginning
    _audioPlayer.seek(const Duration());
    return _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void stop() {
    _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

class AudioFile {
  static List<String> wins = [
    "Win/Win-01",
    "Win/Win-02",
    "Win/Win-03",
    "Win/Win-04",
    "Win/Win-05",
    "Win/Win-06",
    "Win/Win-07",
    "Win/Win-08",
    "Win/Win-09",
    "Win/Win-10",
    "Win/Win-11",
    "Win/Win-12",
    "Win/Win-13",
    "Win/Win-14",
  ];

  static List<String> buttons = [
    "Button-01.mp3",
    "Button-02.mp3",
    "Button-03.mp3"
  ];

  static String challenge = "Challenge.mp3";
  static String countdown = "Countdown.mp3";
  static String fail = "Fail.mp3";
  static String zenExtended = "ZenExt.mp3";
  static String level = "Level.mp3";
}

class AudioManager {
  String folder = "assets/sounds/";
  final Map<String, PerliAudioPlayer> _audioPlayers = {};

  AudioManager();

  String _getFullPath(String path) {
    if (!path.endsWith(".mp3") && !path.endsWith(".wav")) {
      path += ".mp3";
    }

    if (!path.startsWith(folder)) {
      path = folder + path;
    }

    return path;
  }

  Future<void> load(String path) async {
    path = _getFullPath(path);

    if (_audioPlayers.containsKey(path)) {
      return;
    }

    PerliAudioPlayer player = PerliAudioPlayer();
    await player.load(path);
    _audioPlayers[path] = player;
  }

  Future<void> loadMultiple(List<String> paths) async {
    await Future.wait(paths.map((path) => load(path)));
  }

  List<String> _getOverlap(List<String> a, List<String> b) {
    List<String> overlap = [];
    for (String path in a) {
      if (b.contains(path)) {
        overlap.add(path);
      }
    }
    return overlap;
  }

  List<String> getLoaded() {
    return _audioPlayers.keys.toList();
  }

  Future<void> playRandom(
    List<String> paths, {
    bool isMusic = false,
    bool loop = false,
  }) async {
    List<String> overlap =
        _getOverlap(paths.map(_getFullPath).toList(), getLoaded());
    if (overlap.isNotEmpty) {
      await play(
        overlap[Random().nextInt(overlap.length)],
        isMusic: isMusic,
        loop: loop,
      );
    }
  }

  Future<void> play(
    String path, {
    bool isMusic = false,
    bool loop = false,
  }) async {
    path = _getFullPath(path);

    if (!_audioPlayers.containsKey(path)) {
      return;
    }

    print("playing $path");

    await _audioPlayers[path]!.play(
      isMusic: isMusic,
      loop: loop,
    );
  }

  void pause(String path) {
    path = _getFullPath(path);

    if (!_audioPlayers.containsKey(path)) {
      return;
    }

    _audioPlayers[path]!.pause();
  }

  void stop(String path) {
    path = _getFullPath(path);

    if (!_audioPlayers.containsKey(path)) {
      return;
    }

    _audioPlayers[path]!.stop();
  }

  void stopAll() {
    print("stopall");
    for (PerliAudioPlayer player in _audioPlayers.values) {
      player.stop();
    }
  }

  void dispose() {
    for (PerliAudioPlayer player in _audioPlayers.values) {
      player.dispose();
    }
  }
}
