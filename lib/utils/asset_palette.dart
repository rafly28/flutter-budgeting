import 'package:flutter/material.dart';

class AssetPalette {
  const AssetPalette._();

  static List<Color> forType(String assetType, BuildContext context) {
    switch (assetType) {
      case 'gold':
        return const [Color(0xFF8A6D1F), Color(0xFFE6C34D)];
      case 'crypto':
        return const [Color(0xFF5B21B6), Color(0xFF8B5CF6)];
      case 'stock':
        return const [Color(0xFF065F46), Color(0xFF10B981)];
      case 'cash':
      default:
        final primary = Theme.of(context).colorScheme.primary;
        return [darken(primary, 0.18), primary];
    }
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
