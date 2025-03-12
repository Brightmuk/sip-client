import 'package:flutter/material.dart';

enum ButtonType{number, icon, iconWithLabel}
class ActionButton2 extends StatelessWidget {
  final Widget child;
  final ButtonType type;
  final Function()? onPressed;
  final Function()? onLongPress;

  const ActionButton2(
      {Key? key, required this.child, this.onPressed, this.onLongPress,  this.type=ButtonType.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(65),
            border:
                Border.all(color: Color.fromRGBO(115, 121, 110, 1), width: 1)),
        child: Center(child: child),
      ),
    );
    ;
  }
}
