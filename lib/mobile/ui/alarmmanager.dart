import 'dart:convert';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/colors/colors.dart';
import '../utility/AlarmSupport.dart';

class Alarmmanager extends StatefulWidget {
  const Alarmmanager({super.key});

  @override
  State<Alarmmanager> createState() => _AlarmmanagerState();
}

class _AlarmmanagerState extends State<Alarmmanager> {
  List<AlarmCall> alarmCalls = [];

  late SharedPreferencesAsync preferencesAsync = SharedPreferencesAsync();

  @override
  void initState() {
    getAlarms();
    // TODO: implement initState
    super.initState();
  }

  Future<void> getAlarms() async {
    setState(() {
      alarmCalls=[];
    });

    List<AlarmCall> calls = [];

    List<String>? alarmIds = await preferencesAsync.getStringList("AlarmIdList");

    alarmIds ??= [];

    for(String alarmId in alarmIds)
      {
        String? alarm = await preferencesAsync.getString(alarmId);

        if(alarm==null)
          {
            return;
          }

        AlarmCall alarmCall = AlarmCall.fromJson(alarm);

        calls.add(alarmCall);
      }

    final dateNow = DateTime.now();
    final dateTom = DateTime.now().add(Duration(days: 1));

    calls.forEach((call) {

      if(call.isPeriodic)
        {
          final todayAlarm = DateTime(dateNow.year, dateNow.month, dateNow.day, call.time.hour, call.time.minute);
          final tomAlarm = DateTime(dateTom.year, dateTom.month, dateTom.day, call.time.hour, call.time.minute);
          if(todayAlarm.millisecondsSinceEpoch<dateNow.millisecondsSinceEpoch)
            {
              call.time = tomAlarm;
            }
          else {
            call.time = todayAlarm;
          }
        }
    });

    calls.sort((a, b) {
      return a.time.millisecondsSinceEpoch-b.time.millisecondsSinceEpoch;
    },);

    setState(() {
      alarmCalls = calls;
    });
  }

  Future<String?> displayTextInputDialog(BuildContext context, String title, String preText) async {
    return await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController textFieldController = TextEditingController();
        return AlertDialog(
          title: Text(title), // Pop-up Title
          content: TextField(
            controller: textFieldController,
            autofocus: true, // Automatically opens keyboard
            decoration: (preText=="")?InputDecoration(hintText: "Type something here"):null,
          ),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context, null); // Close the pop-up
              },
            ),
            // Save/OK Button
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.pop(context, textFieldController.text); // Close the pop-up
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> displayBooleanInputDialog(BuildContext context, String title) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.pop(context, false); // Close the pop-up
              },
            ),
            // Save/OK Button
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true); // Close the pop-up
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool isPeriodic = await displayBooleanInputDialog(context, "Is Periodic?");

          DateTime? pickedDate = DateTime.now();

          if(!isPeriodic)
            {
              pickedDate = await showDatePicker(
                context: context,
                helpText: "Alarm Date",
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if(pickedDate==null)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cancelled creating Alarm'),
                    behavior: SnackBarBehavior.floating, // Lifts it up
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(20), // Adds space around it
                  ),
                );
                return;
              }
            }

          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            helpText: "Alarm Time",
            initialTime: TimeOfDay.now(),
          );

          if(pickedTime==null)
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cancelled creating Alarm'),
                behavior: SnackBarBehavior.floating, // Lifts it up
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(20), // Adds space around it
              ),
            );
            return;
          }

          String? title = await displayTextInputDialog(context, "Title", "");

          if(title==null || title=="")
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cancelled creating Alarm'),
                behavior: SnackBarBehavior.floating, // Lifts it up
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(20), // Adds space around it
              ),
            );
            return;
          }

          String? description = await displayTextInputDialog(context, "Description", "");

          if(description==null || description=="")
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cancelled creating Alarm'),
                behavior: SnackBarBehavior.floating, // Lifts it up
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(20), // Adds space around it
              ),
            );
            return;
          }

          String? callSpeech = await displayTextInputDialog(context, "Question", "This is an alarm!");

          if(callSpeech==null || callSpeech=="")
          {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cancelled creating Alarm'),
                behavior: SnackBarBehavior.floating, // Lifts it up
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(20), // Adds space around it
              ),
            );
            return;
          }

          String? repetitions = await displayTextInputDialog(context, "Repeat?", "1");

          int rep = 1;

          if(repetitions==null || repetitions=="")
          {
            try {
              rep = int.parse(repetitions!);
            } catch (exp) {
              print("Exp : ${exp}");
            }
          }

          int? id = await preferencesAsync.getInt("AlarmIdTop");
          List<String>? ids = await preferencesAsync.getStringList("AlarmIdList");

          ids ??= [];

          id ??= 1000;

          id++;

          if(pickedDate!=null && pickedTime!=null && title != null && description !=null && callSpeech!=null)
            {
              DateTime alarmTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);

              AlarmCall alarmCall = AlarmCall(id: id, uuid: Uuid().v4(), title: title, description: description, callSpeech: callSpeech, time: alarmTime, isPeriodic: isPeriodic, repetitions: rep);

              final alarmidName = "ShukaAlarm_$id";

              preferencesAsync.setString(alarmidName, alarmCall.toJson());

              bool setOrNot = false;

              if(isPeriodic)
                {
                  setOrNot = await AndroidAlarmManager.periodic(
                      Duration(hours: 24),
                      alarmCall.id,
                      triggerCallUI,
                      startAt: alarmCall.time,
                      exact: true,
                      rescheduleOnReboot: true,
                      wakeup: true,
                      allowWhileIdle: true
                  );
                }
              else {
                setOrNot = await AndroidAlarmManager.oneShotAt(
                    alarmCall.time,
                    alarmCall.id,
                    triggerCallUI,
                    alarmClock: true,
                    exact: true,
                    rescheduleOnReboot: true,
                    wakeup: true,
                    allowWhileIdle: true
                );
              }

              ids.add(alarmidName);

              preferencesAsync.setInt("AlarmIdTop", id);

              preferencesAsync.setStringList("AlarmIdList", ids);

              setState(() {
                alarmCalls.add(alarmCall);
              });
            }
        },
        child: Icon(Icons.alarm_add, color: colorThemeCurrent.colors.primaryContrastColor,),
        backgroundColor: colorThemeCurrent.colors.primaryColor,
      ),
      body: SafeArea(
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.all(10),
          itemCount: alarmCalls.length,
          itemBuilder: (context, index) {
            final note = alarmCalls[index];
            return InkWell(
                child: AlarmCard(alarmCall: note),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Long Press To Delete'),
                      behavior: SnackBarBehavior.floating, // Lifts it up
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(20), // Adds space around it
                    ),
                  );
                  },
                onLongPress: () async {
                  bool deleted = await AndroidAlarmManager.cancel(note.id);

                  if(deleted) {
                    await preferencesAsync.remove("ShukaAlarm_${note.id}");

                    List<String>? alarms = await preferencesAsync.getStringList("AlarmIdList");

                    if(alarms!=null)
                      {
                        alarms.removeWhere((idName) => (idName =="ShukaAlarm_${note.id}"));
                        await preferencesAsync.setStringList("AlarmIdList", alarms);
                      }

                    setState(() {
                      alarmCalls.removeAt(index);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Alarm Deleted'),
                        behavior: SnackBarBehavior.floating, // Lifts it up
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(20), // Adds space around it
                      ),
                    );
                  }
                },
            );
          },
        ),
      ),
    );
  }
}

class AlarmCard extends StatefulWidget {
  const AlarmCard({super.key, required this.alarmCall});

  final AlarmCall alarmCall;

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the color doesn't bleed over the rounded corners
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 100,
            color: colorThemeCurrent.colors.secondaryColor,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  child: CircleAvatar(
                    child: Icon(Icons.person, color: colorThemeCurrent.colors.secondaryColor,),
                    backgroundColor: colorThemeCurrent.colors.baseColor,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${widget.alarmCall.title}(${widget.alarmCall.repetitions.toString()})${(widget.alarmCall.isPeriodic?"*":"")}", style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 20),),
                      Text(widget.alarmCall.isPeriodic?"${((DateTime.now().hour*60+DateTime.now().minute)>(widget.alarmCall.time.hour*60+widget.alarmCall.time.minute))?"Tomorrow":"Today"} ${widget.alarmCall.time.hour>12?widget.alarmCall.time.hour-12:widget.alarmCall.time.hour}:${widget.alarmCall.time.minute} ${widget.alarmCall.time.hour>12?"PM":"AM"}":"${widget.alarmCall.time.day}/${widget.alarmCall.time.month}/${widget.alarmCall.time.year} ${widget.alarmCall.time.hour>12?widget.alarmCall.time.hour-12:widget.alarmCall.time.hour}:${widget.alarmCall.time.minute} ${widget.alarmCall.time.hour>12?"PM":"AM"}", style: TextStyle(color: colorThemeCurrent.colors.primaryContrastColor, fontSize: 14),)
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(widget.alarmCall.description, style: TextStyle(color: colorThemeCurrent.colors.secondaryColor),),
          ),
        ],
      ),
    );
  }
}



class AlarmCall {
  int id;
  String uuid;
  String title, description, callSpeech;
  DateTime time;
  int repetitions;
  bool isPeriodic;
  int? timeString;

  AlarmCall({required this.id, required this.uuid, required this.title, required this.description, required this.callSpeech, required this.time, required this.isPeriodic, required this.repetitions, this.timeString});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "uuid": uuid,
      "title": title,
      "description": description,
      "callSpeech": callSpeech,
      "repetitions": repetitions,
      "timeString": time.millisecondsSinceEpoch,
      "isPeriodic": isPeriodic
    };
  }

  static AlarmCall fromMap(Map<String, dynamic> map) {
    return AlarmCall(id: map["id"], uuid: map["uuid"], title: map["title"], description: map["description"], callSpeech: map["callSpeech"], time: DateTime.fromMillisecondsSinceEpoch(map["timeString"]), isPeriodic: map["isPeriodic"], repetitions: map["repetitions"]);
  }

  static AlarmCall fromJson(String string) {
    Map<String, dynamic> map = json.decode(string);
    return fromMap(map);
  }

  String toJson() {
    return json.encode(toMap());
  }
}

