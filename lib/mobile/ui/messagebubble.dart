import 'package:agentshuka/mobile/utility/ShukaEngine.dart';
import 'package:agentshuka/mobile/utility/LatexSupport.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../shared/colors/colors.dart';

class Messagebubble extends StatelessWidget {
  Messagebubble({required this.message, required this.onTap, required this.onDoubleTap, required this.onLongPress});

  final ShukaMessage message;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  Color? getBubbleColor(int intensity) {
    return message.errorMessage!=null?Colors.red[intensity]:(message.isUser ? colorThemeCurrent.colors.primaryColor[intensity] : Colors.grey[intensity]);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Material(
          color: getBubbleColor(300),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: message.isUser?Radius.circular(20):Radius.zero, bottomRight: !message.isUser?Radius.circular(20):Radius.zero),
          child: InkWell(
            splashColor: getBubbleColor(300),
            highlightColor: Colors.transparent,
            onTap: onTap,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: message.isUser?Radius.circular(20):Radius.zero, bottomRight: !message.isUser?Radius.circular(20):Radius.zero),
            child: Container(
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: 250),
              child: message.isUser?Text(message.message, style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 16),):(message.errorMessage!=null?Text(message.message, style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 16),):MarkdownBody(data: message.message, styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 16)), builders: {'latex': LatexElementBuilder()},)),
            ),
          ),
        ),
      ),
    );
  }
}


