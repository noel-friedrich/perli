// ignore_for_file: constant_identifier_names

enum CellType {
  EMPTY,
  VISITED,
  BOMB,
  GOAL,
  TRANSPARENT,
}

enum GamePhase {
  SEE_BOMBS,
  DRAWING_PATH,
  LEVEL_COMPLETE,
  LEVEL_FAILED,
  GENERATING_LEVEL,
}
