import 'package:agentshuka/shared/colors/colors.dart';
import 'package:agentshuka/wear/ui/agentscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterWearOsConnectivity _flutterWearOsConnectivity = FlutterWearOsConnectivity();
  _flutterWearOsConnectivity.configureWearableAPI();

  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shuka',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: colorThemeCurrent.colors.primaryColor),
        ),
        home: Agentscreen()
    );
  }
}