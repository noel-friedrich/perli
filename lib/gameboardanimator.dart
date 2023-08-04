import 'package:perli/gameconstants.dart';

import 'gameboard.dart';

class GameBoardAnimator {
  GameBoard a;
  GameBoard b;
  int frameIndex = 0;
  int interpolationOffset = 3;
  int animationTotalMs = 1000;

  GameBoardAnimator(this.a, this.b, {this.interpolationOffset = 3}) {
    if (a.size != b.size) {
      a = a.changeSizeTo(b.size);
    }
    interpolationOffset = a.size - 1;
  }

  int totalLength() {
    return a.size * 2 + interpolationOffset - 1;
  }

  int waitMs() {
    return animationTotalMs ~/ totalLength();
  }

  GameBoard getFrame() {
    if (frameIndex == 0) {
      return a;
    } else if (isDone()) {
      return b;
    } else {
      GameBoard interpolation = a.copy();

      int tempFrameIndex = frameIndex;

      for (int i = 0; i < tempFrameIndex; i++) {
        for (int j = tempFrameIndex - i - 1; j >= 0; j--) {
          if (i < a.size && j < a.size) {
            interpolation.setValue(i, j, CellType.TRANSPARENT);
          }
        }
      }

      tempFrameIndex -= interpolationOffset;

      for (int i = 0; i < tempFrameIndex; i++) {
        for (int j = tempFrameIndex - i - 1; j >= 0; j--) {
          if (i < a.size && j < a.size) {
            interpolation.setValue(i, j, b.getVisibleValue(i, j));
          }
        }
      }

      return interpolation;
    }
  }

  void nextFrame() {
    frameIndex++;
  }

  bool isDone() {
    return frameIndex > totalLength();
  }
}
