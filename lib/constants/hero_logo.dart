import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HeroLogo extends StatelessWidget {
  final double width;
  final double height;
  final String asset;

  const HeroLogo({
    Key? key,
    required this.width,
    required this.height,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'penny_logo',
      child: Material(
        color: Colors.transparent,
        child: Image.asset(
          asset,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}