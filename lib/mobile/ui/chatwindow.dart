import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:agentshuka/mobile/ui/voicebubble.dart';
import 'package:agentshuka/shared/utility/wearcomms.dart';
import 'package:flutter/services.dart';

import 'package:agentshuka/mobile/ui/messagebubble.dart';
import 'package:agentshuka/mobile/ui/textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shake/shake.dart';

import '../../shared/colors/colors.dart';
import '../utility/ShukaEngine.dart';

class ChatWindow extends StatefulWidget {
  const ChatWindow({super.key});

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  WearComms wearComms = WearComms(targetCapability: "shuka_wear");

  String status = "Contacting";
  String premise = "Shuka is here to help!";

  final String error_string = "There is some error";

  final ValueNotifier<IconData> stepIcon = ValueNotifier(Icons.question_mark_outlined);
  final ValueNotifier<String> stepText = ValueNotifier("");

  bool dialogEnabled = false;

  final List<ShukaMessage> messages = [
    ShukaMessage.fromStarter("Ask me anything...")
  ];

  final List<Map<String, dynamic>> notes = [
    {"name": "Coming", "text": "Whatever"},
    {"name": "Soon", "text": "Whatever"},
    {"name": "...", "text": "Whatever"}
  ];

  Timer? _timer;

  late ShakeDetector detector;
  bool isShukaVoiceDialogOpen = false;
  VoicebubbleController controller = VoicebubbleController();

  BuildContext? ctxglobal=null;

  @override
  void initState() {
    checkStatusPeriodic();

    detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) async {
        print("Shake Event");

        if(ctxglobal==null)
        {
          return;
        }

        print("Shake Event 2");

        if(status!="Available") {
          return;
        }

        print("Shake Event 3");

        if(!isShukaVoiceDialogOpen)
        {
          final result = await listenToUser(ctxglobal!);

          setState(() {
            messages.add(ShukaMessage.fromUser(result));
            status = "Thinking";
          });


          sendMessageToShuka(
              query: result,
              pastConversation: summarizePastTenDialogs(),
              premise: premise,
              onThought: (ShukaThought thought, IconData icon) {
                if(thought.type=="start")
                  {
                    premise = thought.content;
                  }
                showLoadingDialog(context, thought.content, icon);
              },
              onResponse: (shukaMessage) {
                popLoadingDialog(context);

                setState(() {
                  messages.add(shukaMessage);
                  status = "Available";
                });

                shukaSpeak(shukaMessage.message);
              }
          );
        }
        else {
          try {
            controller.stopListening!();
          }
          catch (e) {
            isShukaVoiceDialogOpen=false;
          }
        }
      },
      useFilter: true,
      shakeSlopTimeMS: 300,
      shakeCountResetTime: 2000,
      shakeThresholdGravity: 2.7,
      minimumShakeCount: 1,
    );

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    detector.stopListening();
    ctxglobal = null;
    // TODO: implement dispose
    super.dispose();
  }

  Future<void> setWearCommsUp() async {
    bool setUp = await wearComms.init();

    if(setUp) {
      wearComms.receiveMessageFromTarget("/query", (WearCommsMessage mess) async {
        setState(() {
          messages.add(ShukaMessage.fromUser(mess.message));
        });

        sendMessageToShuka(
            query: mess.message,
            pastConversation: summarizePastTenDialogs(),
            premise: premise,
            onThought: (ShukaThought thought, IconData icon) {
              if(thought.type=="start")
              {
                premise = thought.content;
              }
            },
            onResponse: (shukaMessage) {
              setState(() {
                messages.add(shukaMessage);
              });
              wearComms.sendResponseToTarget("/query", WearCommsMessage.fromId(shukaMessage.message, mess.id));
            }
        );
      });
    }
  }

  Future<String> listenToUser(BuildContext ctx, {String extraInfo = ""}) async {
    isShukaVoiceDialogOpen = true;
    String result = await showDialog(
      context: ctx,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevents closing with the hardware back button
          child: AlertDialog(
            content: Voicebubble(controller: controller, userTarget: ShukaVerbalState.Listening, extraInfo: extraInfo,),
          ),
        );
      },
    );
    isShukaVoiceDialogOpen=false;
    return result;
  }

  Future<void> speakToUser(BuildContext ctx, String speech) async {
    isShukaVoiceDialogOpen = true;
    await showDialog(
      context: ctx,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevents closing with the hardware back button
          child: AlertDialog(
            content: Voicebubble(controller: controller, userTarget: ShukaVerbalState.Speaking, extraInfo: speech,),
          ),
        );
      },
    );
    isShukaVoiceDialogOpen=false;
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

    Navigator.pop(ctx);

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

    if(isShukaVoiceDialogOpen)
      {
        controller.pop!();
        isShukaVoiceDialogOpen=false;
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
                    color: colorThemeCurrent.colors.primaryColor,
                  );
                }),
                SizedBox(height: 20),
                ValueListenableBuilder(valueListenable: stepText, builder: (context, value, child) {
                  return Text(
                    value,
                    style: TextStyle(
                        fontSize: 16,
                        color: colorThemeCurrent.colors.secondaryColor
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

    List<ShukaMessage> relevantConversation = messages.sublist(length);

    String summary = "";

    for (int i = 0; i < length; i++) {
      if(relevantConversation[i].isUser) {
        summary += "\n\n User:  ${relevantConversation[i].message}";
      } else {
        if (relevantConversation[i].thoughtDetails!=null)
          {
            var jsonMess = relevantConversation[i].thoughtDetails;
            summary += "\n\n Agent-Thought: ${jsonMess?.thoughtsSummary} \n\n Agent: ${jsonMess?.answer}";
          }
          else {
            summary += "\n\n Agent: ${relevantConversation[i].message}";
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
            title: Text("Thought Process", style: TextStyle(color: colorThemeCurrent.colors.primaryColor),),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true, // Important: tells ListView to only take needed space
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      title: Tooltip(message: steps[index]["content"] ,child: Text(steps[index]["content"], style: TextStyle(color: colorThemeCurrent.colors.secondaryColor), maxLines: 3, overflow: TextOverflow.ellipsis,),),
                      leading: Icon(iconsForAction(steps[index]["type"]), color: colorThemeCurrent.colors.primaryColor,),
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
            title: Text("Error Details", style: TextStyle(color: colorThemeCurrent.colors.primaryColor),),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  InkWell(
                    onTap: () {},
                    child: ListTile(
                      title: Tooltip(message: message, child: Text(message, style: TextStyle(color: colorThemeCurrent.colors.secondaryColor), maxLines: 3, overflow: TextOverflow.ellipsis,)),
                      leading: Icon(Icons.error, color: colorThemeCurrent.colors.primaryColor,),
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

  shukaSpeak(String text) async {
    if(ctxglobal==null)
    {
      return;
    }

    if(!isShukaVoiceDialogOpen)
    {
      await speakToUser(ctxglobal!, text);
    }
    else {
      controller.pop!();
      await speakToUser(ctxglobal!, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ctxglobal = context;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: colorThemeCurrent.colors.iconBare,
              backgroundColor: colorThemeCurrent.colors.baseColor,
            ),
            SizedBox(width: 10,),
            Text("Shuka"),
            SizedBox(width: 10,),
            Text(
              status,
              style: TextStyle(
                color: colorThemeCurrent.colors.secondaryColor,
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
                  return Messagebubble(
                    message: msg,
                    onTap: () {
                      if(msg.thoughtDetails!=null && !msg.isUser)
                      {
                        final jsmn = msg.thoughtDetails;
                        showThoughtSequenceDialog(context, jsmn!.steps, jsmn.question);
                      }
                      if(msg.errorMessage!=null)
                        {
                          showErrorDialog(context, msg.errorMessage!);
                        }
                      if(msg.thoughtDetails==null && !msg.isUser)
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
                      if(msg.isUser)
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
                      Clipboard.setData(ClipboardData(text: msg.message));
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

                setState(() {
                  messages.add(ShukaMessage.fromUser(str));
                  status = "Thinking";
                });

                sendMessageToShuka(
                  query: str,
                  pastConversation: summarizePastTenDialogs(),
                  premise: premise,
                  onThought: (ShukaThought thought, IconData icon) {
                    if(thought.type=="start")
                    {
                      premise = thought.content;
                    }
                    showLoadingDialog(context, thought.content, icon);
                  },
                  onResponse: (shukaMessage) {
                    popLoadingDialog(context);
                    setState(() {
                      messages.add(shukaMessage);
                      status = "Available";
                    });
                  }
                );
              },
            )
          ],
        ),
      ),
    );
  }
}