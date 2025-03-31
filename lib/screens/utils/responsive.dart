import 'package:flutter/material.dart';

class ResponsiveUtil {
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 900;
}
