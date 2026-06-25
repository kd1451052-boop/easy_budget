import 'package:flutter/material.dart';

IconData getIcon(int codePoint) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}
