import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

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
  String premise = "Shuka is here to help!";

  final ValueNotifier<IconData> stepIcon = ValueNotifier(Icons.question_mark_outlined);
  final ValueNotifier<String> stepText = ValueNotifier("");

  bool dialogEnabled = false;

  final List<Map<String, dynamic>> messages = [
    {"text": "Ask me anything...", "isMe" : false, "isJson" : false, "extra": null}
  ];

  final List<Map<String, dynamic>> notes = [
    {"name": "Coming", "text": "Whatever"},
    {"name": "Soon", "text": "Whatever"},
    {"name": "...", "text": "Whatever"}
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

  void popLoadingDialog(BuildContext ctx) {
    setState(() {
      stepText.value="Some Error Occurred";
      stepIcon.value=Icons.question_mark_outlined;
    });

    if(!dialogEnabled)
      {
        return;
      }

    Navigator.pop(context);

    dialogEnabled = false;
  }

  void showLoadingDialog(BuildContext ctx, String text, IconData icon) {
    if(text.trim().isEmpty)
      {
        return;
      }

    setState(() {
      stepText.value=text;
      stepIcon.value=icon;
    });

    if(dialogEnabled)
      {
        return;
      }

    dialogEnabled = true;
    showDialog(
      context: ctx,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevents closing with the hardware back button
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min, // Constrains the dialog size
              children: [
                ValueListenableBuilder(valueListenable: stepIcon, builder: (context, value, child) {
                  return Icon(
                    value, // Your choice of icon
                    size: 50,
                    color: Colors.deepPurple,
                  );
                }),
                SizedBox(height: 20),
                ValueListenableBuilder(valueListenable: stepText, builder: (context, value, child) {
                  return Text(
                    value,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurpleAccent
                    ),
                    textAlign: TextAlign.center,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData iconsForAction(String action) {
    if(action=="thought")
      {
        return Icons.psychology;
      }
    else if (action=="start")
      {
        return Icons.lightbulb;
      }
    else if (action=="action")
      {
        return Icons.settings;
      }
    else if (action=="action_input")
      {
        return Icons.text_format;
      }
    else if (action=="observation")
      {
        return Icons.remove_red_eye_outlined;
      }
    else if (action=="status")
      {
        return Icons.search;
      }
    else if (action=="source_found")
      {
        return Icons.done_all;
      }
    else if (action=="final_answer")
      {
        return Icons.check_circle_outline;
      }
    else if (action=="summary")
      {
        return Icons.list_alt;
      }
    return Icons.error;
  }

  String summarizePastTenDialogs() {
    int length = max(0, messages.length - 10);

    List<Map<String, dynamic>> relevantConversation = messages.sublist(length);

    String summary = "";

    for (int i = 0; i < length; i++) {
      if(relevantConversation[i]["isMe"]) {
        summary += "\n\n User:  ${relevantConversation[i]["text"]}";
      } else {
        if (relevantConversation[i]["isJson"])
          {
            var jsonMess = json.decode(relevantConversation[i]["text"]);
            summary += "\n\n Agent-Thought: ${jsonMess["thought_summary"]} \n\n Agent: ${jsonMess["answer"]}";
          }
          else {
            summary += "\n\n Agent: ${relevantConversation[i]["text"]}";
        }
      }
    }

    return summary;
  }

  void showThoughtSequenceDialog(BuildContext ctx, List<dynamic> steps, String question) {
    steps.removeWhere((element) {
      return element["content"].toString().trim().isEmpty;
    });

    steps.sort((element1, element2) {
      return element1["sequence"]-element2["sequence"];
    });

    showDialog(
      context: ctx,
      barrierDismissible: true, // Allows tapping outside to close
      builder: (BuildContext context) {
        return PopScope(
          canPop: true, // Allows closing with the hardware back button
          child: AlertDialog(
            title: Text("Thought Process", style: TextStyle(color: Colors.deepPurple),),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true, // Important: tells ListView to only take needed space
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      title: Tooltip(message: steps[index]["content"] ,child: Text(steps[index]["content"], style: TextStyle(color: Colors.deepPurpleAccent), maxLines: 3, overflow: TextOverflow.ellipsis,),),
                      leading: Icon(iconsForAction(steps[index]["type"]), color: Colors.deepPurple,),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void showErrorDialog(BuildContext ctx, String message) {
    showDialog(
      context: ctx,
      barrierDismissible: true, // Allows tapping outside to close
      builder: (BuildContext context) {
        return PopScope(
          canPop: true, // Allows closing with the hardware back button
          child: AlertDialog(
            title: Text("Error Details", style: TextStyle(color: Colors.deepPurple),),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  InkWell(
                    onTap: () {},
                    child: ListTile(
                      title: Tooltip(message: message, child: Text(message, style: TextStyle(color: Colors.deepPurpleAccent), maxLines: 3, overflow: TextOverflow.ellipsis,)),
                      leading: Icon(Icons.error, color: Colors.deepPurple,),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
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
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(top: 40, bottom: 20, left: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(
                "Shuka",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.all(10),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ListTile(
                    title: Text(note["name"]),
                    onTap: () {
                      print(note["name"]);
                    },
                  );
                },
              ),
            ),
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
                  return Messagebubble(
                    text: msg["text"],
                    isMe: msg["isMe"],
                    isJson: msg["isJson"],
                    isError: msg["extra"]!=null,
                    onTap: () {
                      if(msg["isJson"] && !msg["isMe"])
                      {
                        final jsmn = json.decode(msg["text"]);
                        showThoughtSequenceDialog(context, jsmn["steps"], jsmn["question"]);
                      }
                      if(msg["extra"]!=null)
                        {
                          showErrorDialog(context, msg["extra"]);
                        }
                      if(!msg["isJson"] && !msg["isMe"])
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Answered without thinking!'),
                              behavior: SnackBarBehavior.floating, // Lifts it up
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(20), // Adds space around it
                            ),
                          );
                        }
                      if(msg["isMe"])
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Screech Screech!'),
                              behavior: SnackBarBehavior.floating, // Lifts it up
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(20), // Adds space around it
                            ),
                          );
                        }
                    },
                    onLongPress: () {
                      if(msg["isJson"])
                      {
                        Clipboard.setData(ClipboardData(text: json.decode(msg["text"])["answer"]));
                      }
                      else {
                        Clipboard.setData(ClipboardData(text: msg["text"]));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Text copied to clipboard!'),
                          behavior: SnackBarBehavior.floating, // Lifts it up
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(20), // Adds space around it
                        ),
                      );
                    },
                    onDoubleTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Screech Screech!'),
                          behavior: SnackBarBehavior.floating, // Lifts it up
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(20), // Adds space around it
                        ),
                      );
                    },
                  );
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
                var relevantConversation = summarizePastTenDialogs();

                setState(() {
                  messages.add({"text":str, "isMe":true, "isJson": false, "extra": null});
                  status = "Thinking";
                });

                showLoadingDialog(context, "Contacting Shuka...", Icons.network_check);

                final queryParams = {
                  "query" : str,
                  "conversation_summary" : premise,
                  "last_relevant_conversation" : relevantConversation
                };
                final uri = Uri.http("100.72.140.76:8000","/intelli-chat");
                try {
                  final request = await http.Request('POST', uri);
                  request.headers.addAll({
                    'Connection': 'Keep-Alive',
                    'Keep-Alive': 'timeout=1000, max=1000',
                    'Content-Type': 'application/json; charset=UTF-8',
                  });
                  request.body = json.encode(queryParams);
                  final response = await http.Client().send(request);

                  if(response.statusCode == 200)
                  {
                    var process = [];
                    var isError = false;
                    var finl = "";
                    var thoughtsSummary = "";

                    response.stream.listen((value) {
                      final str = String.fromCharCodes(value);
                      final jsn = json.decode(str);
                      process.add(jsn);
                      showLoadingDialog(context, jsn["content"], iconsForAction(jsn["type"]));
                      if(jsn["type"]=="final_answer")
                        {
                          finl = jsn["content"];
                        }
                      else if(jsn["type"]=="start")
                        {
                          premise = jsn["content"];
                        }
                      else if(jsn["type"]=="summary")
                        {
                          thoughtsSummary = jsn["content"];
                        }
                    }, onError: (e) {
                      isError = true;
                      popLoadingDialog(context);
                      setState(() {
                        messages.add({"text": "We could not contact Shuka!", "isMe":false, "isJson":false, "extra": "Status Code: ${response.statusCode}, with error : ${e.toString()}"});
                        status = "Available";
                      });
                    }, onDone: () {
                      if(response.statusCode==200 && !isError) {
                        popLoadingDialog(context);
                        setState(() {
                          messages.add({"text": json.encode({"answer":finl, "steps":process, "question" : str, "thoughts_summary": thoughtsSummary}), "isMe":false, "isJson":true, "extra": null});
                          status = "Available";
                        });
                      }
                    });

                  } else {
                    popLoadingDialog(context);
                    print("Request Failed");
                    setState(() {
                      messages.add({"text": "We could not contact Shuka!", "isMe":false, "isJson":false, "extra" : "Request failed with Status Code : ${response.statusCode}"});
                      status = "Available";
                    });
                  }
                } catch (e) {
                  popLoadingDialog(context);
                  print("Error : $e");
                  setState(() {
                    messages.add({"text": "We could not contact Shuka!", "isMe":false, "isJson":false, "extra" : "Request failed with error : ${e.toString()}"});
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