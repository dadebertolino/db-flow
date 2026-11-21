import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../layout/layout_engine.dart';
import '../model/slot.dart';
import 'block_widget.dart';
import 'edge_painter.dart';
import 'theme.dart';

/// Trasformazione che mostra il diagramma centrato in orizzontale e, se serve,
/// rimpicciolito per stare nella larghezza disponibile.
Matrix4 fitTransform(Size viewport, DiagramLayout layout) {
  final scale = math.min(1.0, viewport.width / layout.width).clamp(0.3, 1.0);
  final dx = math.max(0.0, (viewport.width - layout.width * scale) / 2);
  return Matrix4.translationValues(dx, 0, 0)..multiply(Matrix4.diagonal3Values(scale, scale, 1));
}

/// Area di disegno con zoom (0.3–3×) e spostamento libero.
class FlowCanvas extends StatefulWidget {
  const FlowCanvas({
    super.key,
    required this.layout,
    required this.controller,
    this.selectedId,
    this.activeId,
    this.errorIds = const {},
    this.showInserts = true,
    this.onTapBlock,
    this.onDoubleTapBlock,
    this.onLongPressBlock,
    this.onInsert,
    this.onTapEmpty,
  });

  final DiagramLayout layout;
  final TransformationController controller;
  final String? selectedId;

  /// Blocco in esecuzione (evidenziato in verde).
  final String? activeId;
  final Set<String> errorIds;
  final bool showInserts;
  final ValueChanged<String>? onTapBlock;
  final ValueChanged<String>? onDoubleTapBlock;
  final ValueChanged<String>? onLongPressBlock;
  final ValueChanged<Slot>? onInsert;
  final VoidCallback? onTapEmpty;

  @override
  State<FlowCanvas> createState() => _FlowCanvasState();
}

class _FlowCanvasState extends State<FlowCanvas> {
  bool _fitted = false;

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final colors = DiagramColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_fitted && constraints.maxWidth.isFinite) {
          _fitted = true;
          widget.controller.value = fitTransform(constraints.biggest, layout);
        }
        return InteractiveViewer(
          transformationController: widget.controller,
          constrained: false,
          minScale: 0.3,
          maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(600),
          child: SizedBox(
            width: layout.width,
            height: layout.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTapEmpty,
                    child: RepaintBoundary(
                      child: CustomPaint(painter: EdgePainter(layout, colors: colors)),
                    ),
                  ),
                ),
                for (final b in layout.boxes)
                  Positioned(
                    key: ValueKey(b.id),
                    left: b.x,
                    top: b.y,
                    width: b.w,
                    height: b.h,
                    child: BlockWidget(
                      box: b,
                      selected: b.id == widget.selectedId,
                      active: b.id == widget.activeId,
                      hasError: widget.errorIds.contains(b.id),
                      onTap: widget.onTapBlock == null ? null : () => widget.onTapBlock!(b.id),
                      onDoubleTap: widget.onDoubleTapBlock == null
                          ? null
                          : () => widget.onDoubleTapBlock!(b.id),
                      onLongPress: widget.onLongPressBlock == null
                          ? null
                          : () => widget.onLongPressBlock!(b.id),
                    ),
                  ),
                if (widget.showInserts && widget.onInsert != null)
                  for (final ins in layout.inserts)
                    Positioned(
                      left: ins.at.x - 18,
                      top: ins.at.y - 18,
                      width: 36,
                      height: 36,
                      child: _InsertButton(onTap: () => widget.onInsert!(ins.slot)),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InsertButton extends StatelessWidget {
  const _InsertButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = DiagramColors.of(context);
    return Semantics(
      button: true,
      label: tr.insertBlock,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: dc.insertFill,
              shape: BoxShape.circle,
              border: Border.all(color: dc.selection.withValues(alpha: 0.7), width: 1.4),
            ),
            child: Icon(Icons.add, size: 16, color: dc.selection),
          ),
        ),
      ),
    );
  }
}
