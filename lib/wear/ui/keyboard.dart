import 'package:flutter/cupertino.dart';

class HandKeyboard extends StatefulWidget {
  const HandKeyboard({super.key});

  @override
  State<HandKeyboard> createState() => _HandKeyboardState();
}

class _HandKeyboardState extends State<HandKeyboard> {

  List<List<String>> alphabets = [
    ["1","2","3","4","5","6","7","8","9","0"],
    ["Q","W","E","R","T","Y","U","I","O","P"],
    ["A","S","D","F","G","H","J","K","L","!"],
    ["Z","X","C","V","B","N","M",",",".","?"],
    ["@","\$","&","*","#","(",")",";","\"","'"]
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 1),
      itemBuilder: (context, index) {
        return Text("data");
      },
    );
  }
}
