import 'package:agentshuka/mobile/utility/LatexSupport.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../shared/colors/colors.dart';

class Messagebubble extends StatelessWidget {
  Messagebubble({required this.text, required this.isMe, required this.isJson, required this.onLongPress, required this.onDoubleTap, required this.onTap, this.isError=false}) {
    if(isJson)
      {
        data = json.decode(text);
      }
  }

  Map<String, dynamic> data= {};

  final String text;
  final bool isMe;
  final bool isJson;
  final bool isError;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  Color? getBubbleColor(int intensity) {
    return isError?Colors.red[intensity]:(isMe ? colorThemeCurrent.colors.primaryColor[intensity] : Colors.grey[intensity]);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Material(
          color: getBubbleColor(300),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: isMe?Radius.circular(20):Radius.zero, bottomRight: !isMe?Radius.circular(20):Radius.zero),
          child: InkWell(
            splashColor: getBubbleColor(300),
            highlightColor: Colors.transparent,
            onTap: onTap,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: isMe?Radius.circular(20):Radius.zero, bottomRight: !isMe?Radius.circular(20):Radius.zero),
            child: Container(
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: 250),
              child: isMe?Text(text, style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 16),):(isError?Text(text, style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 16),):MarkdownBody(data: isJson?data["answer"]:text, styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 16)), builders: {'latex': LatexElementBuilder()},)),
            ),
          ),
        ),
      ),
    );
  }
}


