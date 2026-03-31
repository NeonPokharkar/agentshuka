import 'package:flutter/material.dart';

const ColorSchema daySchema = ColorSchema(baseColor: Colors.white, baseContrastColor: Colors.black, primaryColor: Colors.deepPurple, primaryContrastColor: Colors.white, secondaryColor: Colors.deepPurpleAccent, icon: AssetImage("assets/icon/icon_day.png"), iconBare: AssetImage("assets/icon/icon_bare_day.png"));

const ColorSchema nightSchema = ColorSchema(baseColor: Colors.black, baseContrastColor: Colors.white, primaryColor: Colors.deepPurpleAccent, primaryContrastColor: Colors.white, secondaryColor: Colors.deepPurple, icon: AssetImage("assets/icon/icon_night.png"), iconBare: AssetImage("assets/icon/icon_bare_night.png"));

class ColorSchema {
  final Color baseColor;
  final Color baseContrastColor;
  final ColorSwatch<int> primaryColor;
  final ColorSwatch<int> secondaryColor;
  final Color primaryContrastColor;
  final AssetImage icon;
  final AssetImage iconBare;

  const ColorSchema({required this.baseColor,required this.baseContrastColor,required this.primaryColor,required this.primaryContrastColor,required this.secondaryColor, required this.icon, required this.iconBare});
}

enum ColorSchemaType {
  day(colors: daySchema), night(colors: nightSchema);

  final ColorSchema colors;

  const ColorSchemaType({required this.colors});
}

ColorSchema getColorSchema(ColorSchemaType type) {
  if(type == ColorSchemaType.day)
    {
      return daySchema;
    }
  else {
    return nightSchema;
  }
}

final colorThemeCurrent = ColorSchemaType.day;