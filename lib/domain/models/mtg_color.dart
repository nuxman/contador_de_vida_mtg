import 'package:flutter/material.dart';

enum MtgColor {
  white,
  blue,
  black,
  red,
  green,
  colorless,
}

extension MtgColorX on MtgColor {
  String get label {
    switch (this) {
      case MtgColor.white:
        return 'W';
      case MtgColor.blue:
        return 'U';
      case MtgColor.black:
        return 'B';
      case MtgColor.red:
        return 'R';
      case MtgColor.green:
        return 'G';
      case MtgColor.colorless:
        return 'C';
    }
  }

  Color get swatch {
    switch (this) {
      case MtgColor.white:
        return const Color(0xFFF8F4E6);
      case MtgColor.blue:
        return const Color(0xFF3A78C2);
      case MtgColor.black:
        return const Color(0xFF1A1A1A);
      case MtgColor.red:
        return const Color(0xFFC0392B);
      case MtgColor.green:
        return const Color(0xFF2ECC71);
      case MtgColor.colorless:
        return const Color(0xFF9E9E9E);
    }
  }
}
