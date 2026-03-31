import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:wear_plus/wear_plus.dart';

import '../../shared/colors/colors.dart';

class Agentscreen extends StatefulWidget {
  const Agentscreen({super.key});

  @override
  State<Agentscreen> createState() => _AgentscreenState();
}

class _AgentscreenState extends State<Agentscreen> {

  List<List<String>> alphabets = [
    ["1","2","3","4","5","6","7","8","9","0"],
    ["Q","W","E","R","T","Y","U","I","O","P"],
    ["A","S","D","F","G","H","J","K","L","!"],
    ["Z","X","C","V","B","N","M",",",".","?"],
    ["@","\$","&","*","#","(",")",";","\"","'"]
  ];

  late ShakeDetector detector;

  @override
  void initState() {
    detector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) async {
        print("Shake detected");
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
