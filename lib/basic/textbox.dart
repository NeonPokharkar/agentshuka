import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatInput extends StatefulWidget {
  const ChatInput({super.key, required this.isActive, required this.processInput});

  final bool isActive;

  final Function(String) processInput;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  _ChatInputState();

  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    color: Colors.white,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            enabled: widget.isActive,
            controller: controller,
            decoration: InputDecoration(
              hintText: "Type a message...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            ),
          ),
        ),
        SizedBox(width: 8,),
        CircleAvatar(
          backgroundColor: widget.isActive?Colors.deepPurple:Colors.grey,
          child: IconButton(
            icon: widget.isActive?Icon(Icons.send, color: Colors.white,):Icon(Icons.lock, color: Colors.white,),
            onPressed: widget.isActive?() {
              widget.processInput(controller.text);
              controller.clear();
            } : null,
          ),
        )
      ],
    ),
  );
  }
}
