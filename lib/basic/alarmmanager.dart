import 'dart:convert';
import 'dart:isolate';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:agentshuka/extensions/basic.dart';

class Alarmmanager extends StatefulWidget {
  const Alarmmanager({super.key});

  @override
  State<Alarmmanager> createState() => _AlarmmanagerState();
}

class _AlarmmanagerState extends State<Alarmmanager> {
  List<AlarmCall> alarmCalls = [
    AlarmCall(id: 3,uuid: const Uuid().v4(),title: "Hello", description: "World", callSpeech: "Hello World", time: DateTime.now().add(Duration(minutes: 1)))
  ];

  static final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @pragma('vm:entry-point')
  static Future<void> triggerCallUI(int id, Map<String, dynamic> alarmParams) async {
    print("Checking whether I can use calls");
    if(!await FlutterCallkitIncoming.canUseFullScreenIntent()) {
      print("cant use calls");
      await FlutterCallkitIncoming.requestFullIntentPermission();
    }

    print("can use calls, starting : ${json.encode(alarmParams)}");

    final params = CallKitParams(
      id: alarmParams["uuid"],
      nameCaller: alarmParams["title"],
      appName: 'Shuka',
      avatar: "assets/icon/icon.png",
      handle: alarmParams["description"],
      type: 0,
      textAccept: 'Complete',
      textDecline: 'Cancel',
      missedCallNotification: NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed task',
        callbackText: 'Retry',
      ),
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Reminder...',
        callbackText: 'Retry',
      ),
      duration: 30000,
      android: AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          logoUrl: "assets/icon/icon.png",
          ringtonePath: 'system_ringtone_default',
          backgroundColor: Colors.white.toHex(),
          actionColor: Colors.deepPurple.toHex(),
          textColor: Colors.deepPurple.toHex(),
          incomingCallNotificationChannelName: "Incoming Call",
          missedCallNotificationChannelName: "Missed Call",
          isShowCallID: true,
          isShowFullLockedScreen: true,
          isImportant: true,
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    print("Setting onEvent");

    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      switch (event!.event) {
        case Event.actionCallIncoming:
          print("actionCallIncoming");
          break;
        case Event.actionCallAccept:
          print("actionCallAccept");
          await startSpeaking(alarmParams["callSpeech"]);
          await FlutterCallkitIncoming.endCall(alarmParams["uuid"]);
          break;
        case Event.actionCallDecline:
          print("actionCallDecline");
          break;
        case Event.actionCallStart:
          print("actionCallStart");
          break;
        case Event.actionCallConnected:
          print("actionCallConnected");
          break;
        case Event.actionCallTimeout:
          print("actionCallTimeout");
          break;
        case Event.actionCallEnded:
          print("actionCallEnded");
          break;
        case Event.actionCallCallback:
          print("actionCallCallback");
          break;
        default:
          print("default");
          break;
      }
    }, onError: (error) {
      print("Error in calling occured = ${error}");
    });

    print("Actual call");

    await FlutterCallkitIncoming.showCallkitIncoming(params);

    print("Call complete");
  }

  static Future<void> startSpeaking(String speech) async {
    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(speech);
  }


  @override
  Widget build(BuildContext context) {
    return Column(
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
            itemCount: alarmCalls.length,
            itemBuilder: (context, index) {
              final note = alarmCalls[index];
              return ListTile(
                title: Text(note.title),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(note.title),
                      behavior: SnackBarBehavior.floating, // Lifts it up
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20), // Adds space around it
                    ),
                  );

                  note.time=DateTime.now().add(Duration(seconds: 20));
                  note.id+=1;

                  print("Setting alarm at : ${note.time}");

                  final setOrNot = await AndroidAlarmManager.oneShotAt(
                      note.time,
                      note.id,
                      triggerCallUI,
                      alarmClock: true,
                      params: note.toMap(),
                      exact: true,
                      rescheduleOnReboot: true,
                      wakeup: true,
                      allowWhileIdle: true
                  );

                  print("Alarm Set ${setOrNot}");
                },
                onLongPress: () {
                  print("Triggering call");
                  triggerCallUI(note.id, note.toMap());
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class AlarmCall {
  int id;
  String uuid;
  String title, description, callSpeech;
  DateTime time;

  AlarmCall({required this.id, required this.uuid, required this.title, required this.description, required this.callSpeech, required this.time});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "uuid": uuid,
      "title": title,
      "description": description,
      "callSpeech": callSpeech
    };
  }
}

