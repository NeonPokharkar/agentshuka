import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shake/shake.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../shared/colors/colors.dart';

class Voicebubble extends StatefulWidget {
  Voicebubble({super.key, required this.controller, required this.userTarget, this.extraInfo});

  final ShukaVerbalState userTarget;
  VoicebubbleController? controller;
  String? extraInfo;

  @override
  State<Voicebubble> createState() => VoicebubbleState();
}

class VoicebubbleState extends State<Voicebubble> {
  final SpeechToText _speech = SpeechToText();

  ShukaVerbalState? state = ShukaVerbalState.Processing;

  final FlutterTts _tts = FlutterTts();
  TtsState speakingState = TtsState.stopped;

  String? text = null;
  String? spoken = null;

  @override
  void initState() {
    widget.controller?.pop=pleasePop;

    // TODO: implement initState
    super.initState();

    if(widget.userTarget==ShukaVerbalState.Listening)
    {
      widget.controller?.restartListening = restartListening;
      startListening();
    }
    else if(widget.userTarget==ShukaVerbalState.Speaking && widget.extraInfo!=null) {
      setTTSHandlers();
      startSpeaking(widget.extraInfo!);
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _speech.statusListener=null;
    _tts.stop();
    state=null;
    text=null;
    spoken=null;
    resetTTSHandlers();
    super.dispose();
  }

  void pleasePop() {
    Navigator.pop(context);
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
      Navigator.pop(context);
    });
    _tts.setErrorHandler((e) {
      print("Error occured ${e}");
      setState(() {
        speakingState = TtsState.stopped;
        state = ShukaVerbalState.Processing;
      });
      Navigator.pop(context);
    });
    _tts.setCancelHandler(() {
      setState(() {
        speakingState = TtsState.stopped;
        state = ShukaVerbalState.Processing;
      });
      Navigator.pop(context);
    });
    _tts.setPauseHandler(() {
      setState(() {
        speakingState = TtsState.paused;
        state = ShukaVerbalState.Processing;
      });
      Navigator.pop(context);
    });
    _tts.setContinueHandler(() {
      setState(() {
        speakingState = TtsState.playing;
        state = ShukaVerbalState.Speaking;
      });
      Navigator.pop(context);
    });
    _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      //
    });
  }

  Future<void> startListening() async {
    resetTTSHandlers();

    setState(() {
      state = ShukaVerbalState.Listening;
    });

    await _speech.cancel();
    await _tts.stop();

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          setState(() {
            text = null;
          });
        } else if(status == 'listening') {
          setState(() {
            text = null;
          });
        }
      },
    );
    if (available) {
      var k =0;
      _speech.listen(
        pauseFor: Duration(seconds: 3),
        listenFor: Duration(seconds: 30),
        onResult: (result) async {
          if (!mounted) return;

          setState(() {
            text=result.recognizedWords;
          });
          spoken=result.recognizedWords;
          await Future.delayed(Duration(seconds: 3));
          _speech.stop();
          if(spoken!=null)
            {
              k+=1;
              final verdict = spoken;
              spoken=null;
              setState(() {
                state= ShukaVerbalState.Processing;
              });
              Navigator.pop(context, verdict);
            }
        },
      );
    }
  }

  Future<void> restartListening() async {
    resetTTSHandlers();

    spoken=null;
    await _speech.cancel();
    await _tts.stop();

    setState(() {
      text = null;
    });

    startListening();
  }

  Future<void> cancelListening() async {
    spoken=null;
    await _speech.cancel();
    await _tts.stop();

    setState(() {
      text = null;
    });

    await Future.delayed(Duration(seconds: 3));

    setState(() {
      state = ShukaVerbalState.Processing;
    });
  }

  Future<void> startSpeaking(String speech) async {
    await _speech.cancel();

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: colorThemeCurrent.colors.iconBare,
          backgroundColor: colorThemeCurrent.colors.secondaryColor[100],
        ),
        SizedBox(width: 10,),
        Text(
            state!.name.toString(),
            style: TextStyle(
                color: colorThemeCurrent.colors.primaryColor,
                fontStyle: FontStyle.italic,
                fontSize: 18
            )
        ),
        if(text!=null) SizedBox(width: 10,),
        if(text!=null) Text(
          text!,
          style: TextStyle(
              color: colorThemeCurrent.colors.secondaryColor,
              fontStyle: FontStyle.italic,
              fontSize: 16
          ),
        )
      ],
    );
  }
}

class VoicebubbleController {
  late Function()? restartListening;
  late Function()? pop;
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