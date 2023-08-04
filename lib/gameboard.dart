import 'dart:math';

import 'gameconstants.dart';

class GameBoard {
  int size = 0;
  List<List<CellType>> tileMap = [];
  Random random = Random();
  GamePhase phase = GamePhase.GENERATING_LEVEL;
  CellType? lastPlacedCellType;

  CellType defaultValue = CellType.EMPTY;

  static transparent(int size) {
    GameBoard board = GameBoard(size);
    board.defaultValue = CellType.TRANSPARENT;
    board.reset();
    return board;
  }

  initTileMap() {
    for (int i = 0; i < size; i++) {
      tileMap.add(List.filled(size, defaultValue));
    }
  }

  reset() {
    for (int i = 0; i < size; i++) {
      tileMap[i].fillRange(0, size, defaultValue);
    }
  }

  setValue(int x, int y, CellType value) {
    tileMap[x][y] = value;
    lastPlacedCellType = value;
  }

  setValueAtPoint(Point p, CellType value) {
    tileMap[p.x.toInt()][p.y.toInt()] = value;
    lastPlacedCellType = value;
  }

  CellType getValue(int x, int y) {
    return tileMap[x][y];
  }

  CellType getVisibleValue(int x, int y) {
    CellType value = tileMap[x][y];
    if (phase == GamePhase.SEE_BOMBS) {
      if (value == CellType.BOMB) {
        return CellType.BOMB;
      } else {
        return CellType.EMPTY;
      }
    } else if (phase == GamePhase.DRAWING_PATH) {
      if (value == CellType.BOMB) {
        return CellType.EMPTY;
      } else {
        return value;
      }
    } else {
      return value;
    }
  }

  CellType getValueAtPoint(Point p) {
    return tileMap[p.x.toInt()][p.y.toInt()];
  }

  int area() {
    return size * size;
  }

  bool isCompleted() {
    for (int x = 0; x < size; x++) {
      for (int y = 0; y < size; y++) {
        CellType value = getValue(x, y);
        if (value == CellType.VISITED) {
          if (isClosedPath(x, y)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool isNextTo(Point point, CellType type) {
    List<Point> neighbors = [
      Point(point.x + 1, point.y),
      Point(point.x - 1, point.y),
      Point(point.x, point.y + 1),
      Point(point.x, point.y - 1),
    ];

    for (Point neighbor in neighbors) {
      if (neighbor.x < 0 ||
          neighbor.x >= size ||
          neighbor.y < 0 ||
          neighbor.y >= size) {
        continue;
      }

      if (getValueAtPoint(neighbor) == CellType.BOMB) {
        continue;
      }

      if (getValueAtPoint(neighbor) == type) {
        return true;
      }
    }

    return false;
  }

  bool isClosedPath(int x, int y) {
    return isNextTo(Point(x, y), CellType.GOAL);
  }

  bool isValidPath(int x, int y) {
    return getValue(x, y) == CellType.EMPTY &&
        isNextTo(Point(x, y), CellType.VISITED);
  }

  copy() {
    GameBoard copy = GameBoard(size);
    copy.tileMap = [
      for (var sublist in tileMap) [...sublist]
    ];
    return copy;
  }

  GameBoard(this.size) {
    initTileMap();
  }

  // level generation code:

  Point randomPoint() {
    return Point(random.nextInt(size), random.nextInt(size));
  }

  bool isPossible(Point startPos, Point goalPos) {
    List<Point> openList = [];
    List<Point> closedList = [];

    openList.add(startPos);

    while (openList.isNotEmpty) {
      Point current = openList.removeAt(0);
      closedList.add(current);

      if (current == goalPos) {
        return true;
      }

      List<Point> neighbors = [
        Point(current.x + 1, current.y),
        Point(current.x - 1, current.y),
        Point(current.x, current.y + 1),
        Point(current.x, current.y - 1),
      ];

      for (Point neighbor in neighbors) {
        if (neighbor.x < 0 ||
            neighbor.x >= size ||
            neighbor.y < 0 ||
            neighbor.y >= size) {
          continue;
        }

        if (getValueAtPoint(neighbor) == CellType.BOMB) {
          continue;
        }

        if (closedList.contains(neighbor)) {
          continue;
        }

        if (!openList.contains(neighbor)) {
          openList.add(neighbor);
        }
      }
    }

    return false;
  }

  int distanceBetweenPoints(Point a, Point b) {
    int dx = (a.x - b.x).abs().toInt();
    int dy = (a.y - b.y).abs().toInt();
    return dx + dy;
  }

  bool generateLevel({
    int bombsPercentage = 50,
    int minPathLength = -1,
    int maxAttempts = 1000,
    int maxBombs = 100,
    int seed = -1,
  }) {
    if (seed != -1) {
      random = Random(seed);
    }

    int numBombs = (bombsPercentage / 100 * area()).toInt();

    if (minPathLength == -1) {
      minPathLength = size;
    }

    if (minPathLength > size + 2) {
      throw Exception("minPathLength must be less than size + 2");
    }

    for (int i = 0; i < maxAttempts; i++) {
      reset();

      Point startPos = randomPoint();
      Point goalPos = randomPoint();

      while (distanceBetweenPoints(startPos, goalPos) < minPathLength) {
        startPos = randomPoint();
        goalPos = randomPoint();
      }

      setValueAtPoint(startPos, CellType.VISITED);
      setValueAtPoint(goalPos, CellType.GOAL);

      int bombsPlaced = 0;
      while (bombsPlaced < numBombs) {
        Point bombPos = randomPoint();
        if (getValueAtPoint(bombPos) == CellType.EMPTY) {
          setValueAtPoint(bombPos, CellType.BOMB);
          bombsPlaced++;
        }
      }

      if (isPossible(startPos, goalPos)) {
        phase = GamePhase.SEE_BOMBS;
        return true;
      }
    }

    return false;
  }
}
