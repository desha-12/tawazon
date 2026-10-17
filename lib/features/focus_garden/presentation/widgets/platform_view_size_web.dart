import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

void setPlatformViewSize(Object? element, Size size, double pixelRatio) {
  if (element == null) return;
  final canvas = element as web.HTMLCanvasElement;
  canvas
    ..width = (size.width * pixelRatio).round()
    ..height = (size.height * pixelRatio).round();
  canvas.style
    ..width = '${size.width}px'
    ..height = '${size.height}px'
    ..display = 'block';
}