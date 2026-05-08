import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs  = 8;
  static const double sm  = 12;
  static const double md  = 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
  static const double screenPadding = 16;
  static const double cardPadding   = 16;
}

class AppRadius {
  AppRadius._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double pill = 999;

  static const BorderRadius radiusSm  = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg  = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl  = BorderRadius.all(Radius.circular(xl));
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0C0D2B4E), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x080D2B4E), blurRadius: 1, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x140D2B4E), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

class AppSizing {
  AppSizing._();
  static const double minTouchTarget = 48;
  static const double buttonHeight   = 52;
  static const double inputHeight    = 52;
  static const double appBarHeight   = 56;
}
