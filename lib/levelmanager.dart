// ignore_for_file: constant_identifier_names

import 'dart:ui';

import 'colors.dart';

enum LevelDifficulty {
  EASY,
  MEDIUM,
  HARD,
}

class LevelManager {
  static String nameFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 'Easy';
      case LevelDifficulty.MEDIUM:
        return 'Medium';
      case LevelDifficulty.HARD:
        return 'Hard';
    }
  }

  static Color colorFromDifficulty(
      LevelDifficulty difficulty, bool isPlayable) {
    if (!isPlayable) {
      return levelLockedColor;
    }

    switch (difficulty) {
      case LevelDifficulty.EASY:
        return levelEasyColor;
      case LevelDifficulty.MEDIUM:
        return levelMediumColor;
      case LevelDifficulty.HARD:
        return levelHardColor;
    }
  }

  static int viewSecondsFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 2;
      case LevelDifficulty.MEDIUM:
        return 2;
      case LevelDifficulty.HARD:
        return 1;
    }
  }

  static int numLevelsPerDifficulty = 33;

  static int numTotalLevels() {
    return numLevelsPerDifficulty * LevelDifficulty.values.length;
  }

  static LevelDifficulty getLevelDifficulty(int level) {
    return LevelDifficulty.values[level ~/ numLevelsPerDifficulty];
  }

  static int bombPercentageFromLevel(int level) {
    int remainder = level % numLevelsPerDifficulty;
    int minPercentage = 30;
    int maxPercentage = 60;
    int percentageRange = maxPercentage - minPercentage;
    return minPercentage +
        (remainder * percentageRange) ~/ numLevelsPerDifficulty;
  }

  static int stagesFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 8;
      case LevelDifficulty.MEDIUM:
        return 12;
      case LevelDifficulty.HARD:
        return 15;
    }
  }

  static int secondsPerStageFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 6;
      case LevelDifficulty.MEDIUM:
        return 6;
      case LevelDifficulty.HARD:
        return 4;
    }
  }

  static int startSecondsFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 20;
      case LevelDifficulty.MEDIUM:
        return 10;
      case LevelDifficulty.HARD:
        return 10;
    }
  }

  static int sizeFromDifficulty(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.EASY:
        return 5;
      case LevelDifficulty.MEDIUM:
        return 6;
      case LevelDifficulty.HARD:
        return 7;
    }
  }
}
