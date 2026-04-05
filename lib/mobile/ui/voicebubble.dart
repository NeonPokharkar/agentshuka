import 'package:agentshuka/mobile/utility/ShukaEngine.dart';
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
  String? text = null;
  String? spoken = null;

  ShukaVerbalState state = ShukaVerbalState.Processing;
  ShukaVoice shukaVoice = ShukaVoice();

  @override
  void initState() {
    widget.controller?.pop=pleasePop;

    // TODO: implement initState
    super.initState();

    if(widget.userTarget==ShukaVerbalState.Listening)
    {
      widget.controller?.stopListening = stopListening;
      startListening();
    }
    else if(widget.userTarget==ShukaVerbalState.Speaking && widget.extraInfo!=null) {
      startSpeaking(widget.extraInfo!);
    }
  }

  @override
  void dispose() {
    text=null;
    spoken=null;
    shukaVoice.dispose();
    super.dispose();
  }

  void pleasePop() {
    Navigator.pop(context);
  }

  Future<void> startListening() async {
    setState(() {
      state = ShukaVerbalState.Listening;
    });

    shukaVoice.startListening((String? str) {
      setState(() {
        state = ShukaVerbalState.Processing;
      });
      Navigator.pop(context, str);
    });
  }

  Future<void> stopListening() async {
    String? str = await shukaVoice.stopListening();

    setState(() {
      state = ShukaVerbalState.Processing;
    });

    Navigator.pop(context, str);
  }

  Future<void> startSpeaking(String speech) async {
    setState(() {
      text=speech;
      state=ShukaVerbalState.Speaking;
    });

    shukaVoice.speak(speech);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: colorThemeCurrent.colors.iconBare,
          backgroundColor: colorThemeCurrent.colors.baseColor,
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
  late Function()? stopListening;
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