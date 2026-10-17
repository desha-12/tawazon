import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

import '../../domain/plant_phase.dart';
import 'plant_canvas.dart';
import 'platform_view_size_stub.dart'
    if (dart.library.js_interop) 'platform_view_size_web.dart' as platform_view_size;

/// Interactive 3D garden.
///
/// The widget sizes itself from its parent constraints instead of a fixed
/// [Size], which keeps the platform view exactly as large as its slot and
/// removes the right-side cropping a mismatched canvas produced.
///
/// The renderer is created with `alpha: true` and a fully transparent clear
/// colour, and the scene has no background plane, so the canvas composites
/// straight onto the app's dark gradient.
class Garden3DWidget extends StatefulWidget {
  const Garden3DWidget({
    super.key,
    required this.growth,
    required this.phase,
    required this.streak,
    required this.isActive,
    required this.semanticLabel,
    this.celebrate = false,
  });

  final double growth;
  final PlantPhase phase;
  final int streak;
  final bool isActive;
  final String semanticLabel;
  final bool celebrate;

  @override
  State<Garden3DWidget> createState() => _Garden3DWidgetState();
}

class _Garden3DWidgetState extends State<Garden3DWidget> {
  three.ThreeJS? _threeJs;
  Size _size = Size.zero;
  Timer? _fallbackTimer;
  bool _ready = false;
  bool _failed = false;
  double _elapsed = 0;

  three.Group? _garden;
  three.Group? _crown;
  three.Mesh? _trunk;
  final List<three.Mesh> _leaves = [];
  final List<three.Mesh> _blossoms = [];

  late final three.MeshLambertMaterial _leafMaterial;
  late final three.MeshLambertMaterial _witheredMaterial;
  late final three.MeshLambertMaterial _blossomMaterial;

  @override
  void didUpdateWidget(covariant Garden3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _threeJs?.pause = !widget.isActive;
    if (oldWidget.growth != widget.growth ||
        oldWidget.phase != widget.phase ||
        oldWidget.streak != widget.streak) {
      _applyGrowth();
    }
  }

  /// Creates the engine once the first real layout size is known.
  void _ensureEngine(Size size) {
    if (_threeJs != null || size.isEmpty) return;
    _size = size;
    _threeJs = three.ThreeJS(
      settings: three.Settings(
        // Transparent canvas so the Flutter gradient shows through.
        alpha: true,
        clearAlpha: 0.0,
        enableShadowMap: false,
        antialias: true,
        screenResolution: 1,
      ),
      onSetupComplete: _onSetupComplete,
      setup: _setupScene,
      size: size,
    )..pause = !widget.isActive;
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_ready) {
        _threeJs?.pause = true;
        setState(() => _failed = true);
      }
    });
  }

  /// Keeps the platform view, renderer and camera in sync with the slot.
  void _resize(Size size) {
    final engine = _threeJs;
    if (engine == null || size == _size || size.isEmpty) return;
    _size = size;
    platform_view_size.setPlatformViewSize(
      engine.texture?.surfaceId,
      size,
      engine.dpr,
    );
    engine.renderer?.setSize(size.width, size.height);
    if (_ready) {
      engine.camera.aspect = size.width / size.height;
      engine.camera.updateProjectionMatrix();
    }
  }

  Future<void> _setupScene() async {
    final engine = _threeJs;
    if (engine == null) return;
    try {
      engine.camera = three.PerspectiveCamera(
        50,
        _size.width / _size.height,
        0.1,
        40,
      );
      engine.camera.position.setValues(0, 2.5, 6.1);
      engine.camera.lookAt(three.Vector3(0, 1.25, 0));

      engine.scene = three.Scene();
      // No background plane: the canvas stays transparent.
      engine.scene.add(three.AmbientLight(0xFFFFFF, 0.72));

      final keyLight = three.DirectionalLight(0xFFF1D5, 1.05)
        ..position.setValues(-3, 6, 4);
      engine.scene.add(keyLight);

      final rimLight = three.DirectionalLight(0x34D399, 0.45)
        ..position.setValues(3.5, 2.5, -3.5);
      engine.scene.add(rimLight);

      _leafMaterial = three.MeshLambertMaterial({
        three.MaterialProperty.color: 0x12865D,
      });
      _witheredMaterial = three.MeshLambertMaterial({
        three.MaterialProperty.color: 0x9B8053,
      });
      _blossomMaterial = three.MeshLambertMaterial({
        three.MaterialProperty.color: 0xF7C873,
      });

      _garden = three.Group();
      engine.scene.add(_garden!);
      _addGround();
      _addTree();
      _addStones();
      _applyGrowth();

      engine.addAnimationEvent(_animate);
    } catch (error) {
      debugPrint('3D garden initialization failed: $error');
      _failed = true;
      engine.pause = true;
    }
  }

  void _addGround() {
    final soil = three.Mesh(
      three.CylinderGeometry(1.85, 1.85, 0.22, 16),
      three.MeshLambertMaterial({three.MaterialProperty.color: 0x42372D}),
    )..position.y = -0.12;
    final grass = three.Mesh(
      three.CylinderGeometry(1.72, 1.72, 0.08, 16),
      three.MeshLambertMaterial({three.MaterialProperty.color: 0x05180F}),
    )..position.y = 0.01;
    _garden!.addAll([soil, grass]);
  }

  void _addTree() {
    _crown = three.Group()..position.y = 1.48;
    _trunk = three.Mesh(
      three.CylinderGeometry(0.09, 0.16, 1.45, 8),
      three.MeshLambertMaterial({three.MaterialProperty.color: 0x80614A}),
    )..position.y = 0.73;

    final leafGeometry = three.SphereGeometry(1, 12, 8);
    final leafPositions = <(double, double, double, double)>[
      (0, 0.18, 0, 0.62),
      (-0.47, -0.02, 0, 0.48),
      (0.48, 0.02, 0.02, 0.5),
      (0, -0.02, 0.46, 0.48),
      (0.04, 0, -0.47, 0.49),
      (-0.24, 0.55, 0.12, 0.43),
      (0.25, 0.52, -0.1, 0.42),
    ];
    for (final (x, y, z, size) in leafPositions) {
      final leaf = three.Mesh(leafGeometry, _leafMaterial)
        ..position.setValues(x, y, z)
        ..scale.setValues(size, size, size);
      _leaves.add(leaf);
      _crown!.add(leaf);
    }

    final blossomGeometry = three.SphereGeometry(0.13, 8, 6);
    final blossomPositions = <(double, double, double)>[
      (-0.42, 0.35, 0.25),
      (0.4, 0.44, 0.18),
      (0.04, 0.68, -0.32),
      (-0.2, -0.05, -0.44),
      (0.38, -0.08, -0.22),
    ];
    for (final (x, y, z) in blossomPositions) {
      final blossom = three.Mesh(blossomGeometry, _blossomMaterial)
        ..position.setValues(x, y, z)
        ..visible = false;
      _blossoms.add(blossom);
      _crown!.add(blossom);
    }

    _garden!.addAll([_trunk!, _crown!]);
  }

  void _addStones() {
    final geometry = three.SphereGeometry(0.16, 7, 5);
    final material = three.MeshLambertMaterial({
      three.MaterialProperty.color: 0x8D9B92,
    });
    final stones = [
      three.Mesh(geometry, material)
        ..position.setValues(-1.0, 0.13, 0.45)
        ..scale.setValues(1.2, 0.7, 0.8),
      three.Mesh(geometry, material)
        ..position.setValues(0.92, 0.12, 0.66)
        ..scale.setValues(0.85, 0.6, 0.7),
      three.Mesh(geometry, material)
        ..position.setValues(0.6, 0.13, -0.92)
        ..scale.setValues(1.0, 0.65, 0.8),
    ];
    _garden!.addAll(stones);
  }

  void _applyGrowth() {
    final crown = _crown;
    if (crown == null) return;

    final growth = widget.growth.clamp(0.0, 1.0);
    final streakScale = math.min(widget.streak, 12) * 0.018;
    final scale = (0.48 + growth * 0.58 + streakScale).clamp(0.45, 1.32);
    crown.scale.setValues(scale, scale, scale);

    final withered = widget.phase == PlantPhase.withered;
    for (final leaf in _leaves) {
      leaf.material = withered ? _witheredMaterial : _leafMaterial;
    }

    final flowersVisible = widget.phase == PlantPhase.bloomed || growth >= 0.9;
    final flowerCount = flowersVisible
        ? (1 + (widget.streak ~/ 3)).clamp(1, _blossoms.length)
        : 0;
    for (var index = 0; index < _blossoms.length; index++) {
      _blossoms[index].visible = index < flowerCount;
    }
    if (_trunk != null && withered) _trunk!.scale.y = 0.9;
    if (_trunk != null && !withered) _trunk!.scale.y = 1;
  }

  void _animate(double delta) {
    if (!widget.isActive || _garden == null) return;
    _elapsed += delta;
    _garden!.rotation.y += delta * 0.075;
    _crown!.rotation.z = math.sin(_elapsed * 0.75) * 0.018;
    for (var index = 0; index < _leaves.length; index++) {
      _leaves[index].rotation.z =
          math.sin(_elapsed * 3 + index) * (widget.celebrate ? 0.14 : 0.012);
    }
  }

  void _onSetupComplete() {
    if (!mounted || _failed) return;
    _fallbackTimer?.cancel();
    platform_view_size.setPlatformViewSize(
      _threeJs?.texture?.surfaceId,
      _size,
      _threeJs?.dpr ?? 1,
    );
    _applyGrowth();
    setState(() => _ready = true);
  }

  void _onPan(DragUpdateDetails details) {
    final garden = _garden;
    if (garden == null) return;
    garden.rotation.y += details.delta.dx * 0.008;
    garden.rotation.x =
        (garden.rotation.x + details.delta.dy * 0.004).clamp(-0.16, 0.16);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _threeJs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size.width > 0 && size.height > 0 && size != _size) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final created = _threeJs == null;
              _ensureEngine(size);
              _resize(size);
              // The engine is created outside the build phase, so trigger a
              // rebuild to swap the fallback canvas for the live platform view.
              if (created && _threeJs != null) setState(() {});
            });
          }
          final engine = _threeJs;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (engine != null)
                GestureDetector(
                  // Horizontal only, so vertical drags still scroll the page.
                  onHorizontalDragUpdate: _onPan,
                  child: engine.build(),
                ),
              if (engine == null || !_ready || _failed)
                IgnorePointer(
                  child: PlantCanvas(
                    growth: widget.growth,
                    phase: widget.phase,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
