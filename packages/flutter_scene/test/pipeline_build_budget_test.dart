import 'dart:io' show sleep;

import 'package:flutter_scene/src/scene_encoder.dart'
    show
        deferredPipelineBuilds,
        endBudgetedDraw,
        startBudgetedDraw,
        withPipelineBuildBudget;
import 'package:flutter_test/flutter_test.dart';

// A frame of draws, each as long as given: a long one stands for a draw that
// builds a pipeline state the first time it runs.
List<int> _slice(List<Duration> frame, Set<int> slowDraws, Set<int> built) {
  final ran = <int>[];
  withPipelineBuildBudget(const Duration(milliseconds: 1), () {
    for (var i = 0; i < frame.length; i++) {
      if (!startBudgetedDraw()) continue;
      if (built.add(i)) sleep(frame[i]);
      ran.add(i);
      endBudgetedDraw();
    }
  }, slowDraws: slowDraws);
  return ran;
}

void main() {
  const fast = Duration.zero;
  const build = Duration(milliseconds: 5);

  test('a slice runs draws up to the first state build past its budget', () {
    final frame = [fast, build, fast, build, fast];
    final slowDraws = <int>{}, built = <int>{};

    expect(_slice(frame, slowDraws, built), [0, 1]);
    expect(deferredPipelineBuilds, 3);
    expect(_slice(frame, slowDraws, built), [0, 1, 2, 3]);
    expect(deferredPipelineBuilds, 1);
    expect(_slice(frame, slowDraws, built), [0, 1, 2, 3, 4]);
    expect(deferredPipelineBuilds, 0);
  });

  test('a draw that is slow every time spends one budget, not every one', () {
    // Draw 1 never gets faster, as if it reused its state but was costly.
    final frame = [fast, build, fast];
    final slowDraws = <int>{};
    var slices = 0;
    do {
      slices++;
      withPipelineBuildBudget(const Duration(milliseconds: 1), () {
        for (var i = 0; i < frame.length; i++) {
          if (!startBudgetedDraw()) continue;
          sleep(frame[i]);
          endBudgetedDraw();
        }
      }, slowDraws: slowDraws);
    } while (deferredPipelineBuilds > 0 && slices < 10);

    expect(slices, 2);
  });

  test('draws outside a warm-up are never skipped', () {
    expect(startBudgetedDraw(), isTrue);
    endBudgetedDraw();
  });
}
