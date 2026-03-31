import 'package:agentshuka/mobile/ui/chatwindow.dart';
import 'package:agentshuka/shared/colors/colors.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AndroidAlarmManager.initialize();

  runApp(MainApp());

  await appPermissions.request();
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
      home: ChatWindow()
    );
  }
}

List<Permission> appPermissions = [Permission.microphone, Permission.notification, Permission.scheduleExactAlarm, Permission.ignoreBatteryOptimizations];