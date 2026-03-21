import 'dart:async';
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
  String status = "Contacting";

  final List<Map<String, dynamic>> messages = [
    {"text": "Ask me anything!", "isMe" : false}
  ];

  Timer? _timer;

  @override
  void initState() {
    checkStatusPeriodic();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  void checkStatusPeriodic() {
    _timer = Timer.periodic(
      const Duration(seconds: 10), // Interval
          (timer) async {
        if(status != "Thinking")
          {
            String stat = await getIfActive();

            setState(() {
              status = stat;
            });
          }
      },
    );
  }

  Future<String> getIfActive() async {
    print("Checking Availability of Server");

    final uri = Uri.http("100.72.140.76:8000","/status");

    try {
      final response = await http.get(uri);

      if(response.statusCode == 200)
        {
          final data = json.decode(response.body);

          return data["status"]?"Available":"Offline";
        }
      else {
        return "Offline";
      }
    } catch (e) {
      print("Error : $e");
      return "Network Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage("assets/icon/icon.png"),
            ),
            SizedBox(width: 10,),
            Text("Shuka"),
            SizedBox(width: 10,),
            Text(
              status,
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontStyle: FontStyle.italic,
                fontSize: 18
              ),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
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
            ChatInput(
              isActive: status == "Available",
              processInput: (str) async {
                if(status!="Available")
                  {
                    return;
                  }

                setState(() {
                  messages.add({"text":str, "isMe":true});
                  status = "Thinking";
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
                    var isError = false;

                    response.stream.listen((value) {
                      final chunk = String.fromCharCodes(value);
                      message+=chunk;
                    }, onError: (e) {
                      isError = true;
                      setState(() {
                        messages.add({"text": "Some error occurred on client side", "isMe":false});
                        status = "Available";
                      });
                    }, onDone: () {
                      if(response.statusCode==200 && !isError) {
                        setState(() {
                          messages.add({"text": message, "isMe":false});
                          status = "Available";
                        });
                      }
                    });

                  } else {
                    print("Request Failed");
                    setState(() {
                      messages.add({"text": "Some error occurred on server : ${response.statusCode}", "isMe":false});
                      status = "Available";
                    });
                  }
                } catch (e) {
                  print("Error : $e");
                  setState(() {
                    messages.add({"text": "Some error occurred on client side", "isMe":false});
                    status = "Available";
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }
}