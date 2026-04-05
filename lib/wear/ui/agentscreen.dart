import 'dart:convert';
import 'dart:typed_data';

import 'package:agentshuka/shared/utility/wearcomms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wear_plus/wear_plus.dart';

import '../../shared/colors/colors.dart';

class Agentscreen extends StatefulWidget {
  const Agentscreen({super.key});

  @override
  State<Agentscreen> createState() => _AgentscreenState();
}

class _AgentscreenState extends State<Agentscreen> {
  WearComms wearComms = WearComms(targetCapability: "shuka_phone");

  late ShakeDetector detector;

  static const platform = MethodChannel('com.your.app/speech');

  ShukaVerbalState? state = ShukaVerbalState.Processing;

  final FlutterTts _tts = FlutterTts();
  TtsState speakingState = TtsState.stopped;

  String? text;

  WearOsDevice? phone;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setTTSHandlers();

    respond();

    detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) async {
        final verdict = await startListening();
        wearComms.sendMessageToTarget("/query", WearCommsMessage.fromMessage(verdict!), (wMessage) {
          startSpeaking(wMessage.message);
        });
      },
      useFilter: true,
      shakeSlopTimeMS: 300,
      shakeCountResetTime: 2000,
      shakeThresholdGravity: 2.7,
      minimumShakeCount: 1,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    state=null;
    resetTTSHandlers();
    wearComms.dispose();
    super.dispose();
  }

  Future<void> respond() async {
    await wearComms.init();
    final verdict = await startListening();
    wearComms.sendMessageToTarget("/query", WearCommsMessage.fromMessage(verdict!), (wMessage) {
      startSpeaking(wMessage.message);
    });
  }

  static Future<String?> startListening() async {
    try {
      final String? result = await platform.invokeMethod('startListening');
      return result;
    } on PlatformException catch (e) {
      print("Speech Error: ${e.message}");
      return null;
    }
  }

  static Future<void> stopListening() async {
    await platform.invokeMethod('stopListening');
  }

  Future<void> resetTTSHandlers() async {
    _tts.startHandler=null;
    _tts.continueHandler=null;
    _tts.cancelHandler=null;
    _tts.completionHandler=null;
    _tts.pauseHandler=null;
    _tts.progressHandler=null;
    _tts.errorHandler=null;
  }

  Future<void> setTTSHandlers() async {
    _tts.setStartHandler(() {
      setState(() {
        speakingState = TtsState.playing;
        state = ShukaVerbalState.Speaking;
      });
    });
    _tts.setCompletionHandler(() {
      setState(() {
        speakingState = TtsState.stopped;
        state = ShukaVerbalState.Processing;
      });
    });
    _tts.setErrorHandler((e) {
      print("Error occured ${e}");
      setState(() {
        speakingState = TtsState.stopped;
        state = ShukaVerbalState.Processing;
      });
    });
    _tts.setCancelHandler(() {
      setState(() {
        speakingState = TtsState.stopped;
        state = ShukaVerbalState.Processing;
      });
    });
    _tts.setPauseHandler(() {
      setState(() {
        speakingState = TtsState.paused;
        state = ShukaVerbalState.Processing;
      });
    });
    _tts.setContinueHandler(() {
      setState(() {
        speakingState = TtsState.playing;
        state = ShukaVerbalState.Speaking;
      });
    });
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      //
    });
  }

  Future<void> startSpeaking(String speech) async {

    if(speakingState == TtsState.playing)
    {
      return;
    }

    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);

    setState(() {
      text=speech;
      state=ShukaVerbalState.Speaking;
    });

    await _tts.speak(speech);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorThemeCurrent.colors.baseColor,
      body: Center(
        child: WatchShape(
          builder: (BuildContext context, WearShape shape, Widget? child) {
            return CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.2,
              backgroundImage: colorThemeCurrent.colors.iconBare,
              backgroundColor: Colors.transparent,
            );
          },
          child: AmbientMode(
            builder: (BuildContext context, WearMode mode, Widget? child) {
              return Text(
                'Mode: ${mode == WearMode.active ? 'Active' : 'Ambient'}',
              );
            },
          ),
        ),
      ),
    );
  }
}

enum ShukaVerbalState {
  Processing,
  Listening,
  Speaking
}

enum TtsState {
  playing,
  paused,
  stopped
}