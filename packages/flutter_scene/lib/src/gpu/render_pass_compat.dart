import 'package:flutter_scene/src/gpu/gpu.dart' as gpu;
import 'package:flutter_scene/src/render/draw_recorder.dart';
import 'package:flutter_scene/src/render/render_stats.dart';
import 'package:flutter_scene/src/scene_encoder.dart'
    show endBudgetedDraw, startBudgetedDraw;

void bindVertexBufferCompat(
  gpu.RenderPass pass,
  gpu.BufferView bufferView,
  int vertexCount, {
  int slot = 0,
}) {
  try {
    (pass as dynamic).bindVertexBuffer(bufferView, slot: slot);
  } on NoSuchMethodError {
    (pass as dynamic).bindVertexBuffer(bufferView, vertexCount);
  }
}

void bindIndexBufferCompat(
  gpu.RenderPass pass,
  gpu.BufferView bufferView,
  gpu.IndexType indexType,
  int indexCount,
) {
  try {
    (pass as dynamic).bindIndexBuffer(bufferView, indexType);
  } on NoSuchMethodError {
    (pass as dynamic).bindIndexBuffer(bufferView, indexType, indexCount);
  }
}

// Every engine draw funnels through these two, so the frame counters and a
// sliced warm-up's draw budget are kept here rather than in each encoder.
void _countDraw(int vertexCount, int instanceCount, {required bool indexed}) {
  activeRenderCounters.draws++;
  activeRenderCounters.instances += instanceCount;
  activeRenderCounters.vertices += vertexCount * instanceCount;
  activeDrawRecorder?.onDraw(vertexCount, instanceCount, indexed: indexed);
}

void drawCompat(gpu.RenderPass pass, int vertexCount, {int instanceCount = 1}) {
  if (!startBudgetedDraw()) return;
  _countDraw(vertexCount, instanceCount, indexed: false);
  try {
    if (instanceCount != 1) {
      (pass as dynamic).draw(vertexCount, instanceCount: instanceCount);
      return;
    }
    try {
      (pass as dynamic).draw(vertexCount);
    } on NoSuchMethodError {
      (pass as dynamic).draw();
    }
  } finally {
    endBudgetedDraw();
  }
}

void drawIndexedCompat(
  gpu.RenderPass pass,
  int indexCount, {
  int instanceCount = 1,
}) {
  if (!startBudgetedDraw()) return;
  _countDraw(indexCount, instanceCount, indexed: true);
  try {
    if (instanceCount != 1) {
      (pass as dynamic).drawIndexed(indexCount, instanceCount: instanceCount);
      return;
    }
    try {
      (pass as dynamic).drawIndexed(indexCount);
    } on NoSuchMethodError {
      (pass as dynamic).draw();
    }
  } finally {
    endBudgetedDraw();
  }
}
