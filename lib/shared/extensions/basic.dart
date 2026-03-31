import 'package:flutter/material.dart';

extension ColorToHex on Color {
  /// Converts the color to an #AARRGGBB hex string
  String toHex() => '#${value.toRadixString(16).padLeft(8, '0')}';

  /// Converts the color to a #RRGGBB hex string (ignores alpha)
  String toHexNoAlpha() => '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}