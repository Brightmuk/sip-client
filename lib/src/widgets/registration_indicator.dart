import 'package:flutter/material.dart';

class RegistrationIndicator extends StatelessWidget {
  final String state;
  const RegistrationIndicator({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color(){
      switch(state){
        case "REGISTERED":
        return Colors.green;
        case "UNREGISTERED":
        return Colors.orange;
        case "NONE":
        default:
        return Colors.red;
      }
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color(),
        borderRadius: BorderRadius.circular(10)
      ),
    );
  }
}