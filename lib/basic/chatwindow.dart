import 'dart:convert';

import 'package:agentshuka/basic/messagebubble.dart';
import 'package:agentshuka/basic/textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final List<Map<String, dynamic>> messages = [
    {"text": "Ask me anything!", "isMe" : false}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Messagebubble(text: msg["text"], isMe: msg["isMe"]);
              },
            ),
          ),
          TextInput(
            processInput: (str) async {
              setState(() {
                messages.add({"text":str, "isMe":true});
              });

              final queryParams = {
                "chat" : str
              };
              final uri = Uri.http("100.72.140.76:8000","/query", queryParams);
              try {
                final request = await http.Request('GET', uri);
                request.headers.addAll({
                  'Connection': 'Keep-Alive',
                  'Keep-Alive': 'timeout=1000, max=1000'
                });
                final response = await http.Client().send(request);

                if(response.statusCode == 200)
                {
                  var message = "";

                  response.stream.listen((value) {
                    final chunk = String.fromCharCodes(value);
                    print("Recieved : $chunk");
                    message+=chunk;
                  }).onDone(() {
                    setState(() {
                      messages.add({"text": message, "isMe":false});
                    });
                  });

                } else {
                  print("Request Failed");
                  setState(() {
                    messages.add({"text": "Some error occurred on server : ${response.statusCode}", "isMe":false});
                  });
                }
              } catch (e) {
                print("Error : $e");
                setState(() {
                  messages.add({"text": "Some error occurred : ${e}", "isMe":false});
                });
              }
            },
          )
        ],
      ),
    );
  }
}