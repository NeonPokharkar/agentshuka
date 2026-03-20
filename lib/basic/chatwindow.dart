import 'package:agentshuka/basic/messagebubble.dart';
import 'package:agentshuka/basic/textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Chatwindow extends StatelessWidget {
  Chatwindow({super.key});

  final List<Map<String, dynamic>> messages = [
    {"text": "Hey!", "isMe": true},
    {"text": "Hello", "isMe": false},
    {"text": "How are you?", "isMe":true},
    {"text": "I'm good, you?", "isMe": false}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(),
            SizedBox(width: 10,),
            Text("Shuka")
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Messagebubble(text: msg["text"], isMe: msg["isMe"]);
              },
            ),
          ),
          TextInput()
        ],
      ),
    );
  }
}
