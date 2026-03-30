import 'dart:convert';

import 'package:agentshuka/basic/alarmmanager.dart';
import 'package:agentshuka/extensions/basic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> triggerCallUI(int id) async {
  SharedPreferencesAsync preferencesAsync = SharedPreferencesAsync();
  final FlutterTts tts = FlutterTts();
  
  String? alarmString = await preferencesAsync.getString("ShukaAlarm_"+id.toString());
  
  if(alarmString==null)
    {
      return;
    }
  
  AlarmCall alarmCall = AlarmCall.fromJson(alarmString);

  print("Checking whether I can use calls");
  if(!await FlutterCallkitIncoming.canUseFullScreenIntent()) {
    print("cant use calls");
    await FlutterCallkitIncoming.requestFullIntentPermission();
  }

  print("can use calls, starting : ${json.encode(alarmString)}");

  int times = 1;

  callAlarm(alarmCall, tts, 1);

  print("Call complete");
}

Future<void> callAlarm(AlarmCall alarmCall, FlutterTts tts, int times) async {
  final callKitParams = CallKitParams(
    id: alarmCall.uuid,
    nameCaller: alarmCall.title,
    appName: 'Shuka',
    avatar: "assets/icon/icon.png",
    handle: alarmCall.description,
    type: 0,
    textAccept: 'Complete',
    textDecline: times==alarmCall.repetitions?'Avoid':'Snooze',
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
        await tts.stop();
        await tts.setLanguage("en-US");
        await tts.setPitch(1.0);
        await tts.speak(alarmCall.callSpeech);
        break;
      case Event.actionCallAccept:
        print("actionCallAccept");
        await FlutterCallkitIncoming.endCall(alarmCall.uuid);
        break;
      case Event.actionCallDecline:
        print("actionCallDecline");
        if(times!=alarmCall.repetitions)
          {
            await FlutterCallkitIncoming.endCall(alarmCall.uuid);
            await Future.delayed(Duration(seconds: 15));
            times++;
            await callAlarm(alarmCall, tts, times);
          }
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

  await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
}