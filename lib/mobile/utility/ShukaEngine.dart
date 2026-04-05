import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

Future<String> getIfActive() async {
  print("Checking Availability of Server");

  final uri = Uri.http("100.72.140.76:8000","/status");

  try {
    final response = await http.get(uri);

    if(response.statusCode == 200)
    {
      final data = json.decode(response.body);

      return data["status"]?"Available":"Offline";
    }
    else {
      return "Offline";
    }
  } catch (e) {
    print("Error : $e");
    return "Network Error";
  }
}

Future<void> sendMessageToShuka({required String query, required String pastConversation, required String premise, required Function(ShukaThought, IconData) onThought, required Function(ShukaMessage) onResponse}) async {
  onThought(ShukaThought(content: "Contacting Shuka...", sequence: -1, type: "none", details: "null"), Icons.network_check);

  final queryParams = {
    "query" : query,
    "conversation_summary" : premise,
    "last_relevant_conversation" : pastConversation
  };
  final uri = Uri.http("100.72.140.76:8000","/intelli-chat");
  try {
    final request = await http.Request('POST', uri);
    request.headers.addAll({
      'Connection': 'Keep-Alive',
      'Keep-Alive': 'timeout=1000, max=1000',
      'Content-Type': 'application/json; charset=UTF-8',
    });
    request.body = json.encode(queryParams);
    final response = await http.Client().send(request);

    if(response.statusCode == 200)
    {
      List<ShukaThought> process = [];
      var isError = false;
      var finl = "";
      var thoughtsSummary = "";

      response.stream.listen((value) {
        final str = String.fromCharCodes(value);
        final ShukaThought thought = ShukaThought.fromJson(json.decode(str));
        process.add(thought);
        onThought(thought, iconsForAction(thought.type));
        if(thought.type=="final_answer")
        {
          finl = thought.content;
        }
        else if(thought.type=="summary")
        {
          thoughtsSummary = thought.content;
        }
      }, onError: (e) {
        isError = true;
        onResponse(ShukaMessage.fromError("Status Code: ${response.statusCode}, with error : ${e.toString()}"));
      }, onDone: () {
        if(response.statusCode==200 && !isError) {
          onResponse(ShukaMessage.fromResponse(query, finl, process, thoughtsSummary));
        }
      });
    } else {
      onResponse(ShukaMessage.fromError("Request failed with Status Code : ${response.statusCode}"));
    }
  } catch (e) {
    onResponse(ShukaMessage.fromError("Request failed with error : ${e.toString()}"));
  }
}

Future<String> getFileRecordPath() async {
  String id = Uuid().v4();
  final dir = await getApplicationDocumentsDirectory();
  return "${dir.path}/record_temp_$id.wav";
}

class ShukaVoice {
  final AudioPlayer _player = AudioPlayer();
  final _recorder = AudioRecorder();
  Timer? _silenceTimer;

  Future<String?> _speechToText(String filePath) async {
    final dio = Dio();
    final fileName = filePath.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName)
    });

    try {
      final response = await dio.post(
        'http://100.72.140.76:8000/speech-to-text',
        data: formData,
        onSendProgress: (sent, total) {
          print('Upload Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );
      print('Transcription Response: ${response.data}');
      if(response.statusCode==200)
      {
        return response.data["text"];
      }
      else {
        print("Request failed with error ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  void startListening(Function(String?) onComplete) async {
    String filePath = await getFileRecordPath();

    if (await _recorder.hasPermission()) {
      // Start recording (WAV is best for local conversion)
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);

      // Listen to amplitude every 200ms
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 200)).listen((amp) {
        // -40 dB is a common threshold for silence
        if (amp.current < -40) {
          _startSilenceTimer(onComplete);
        } else {
          _silenceTimer?.cancel(); // Reset timer if user speaks
        }
      });
    }
  }

  void _startSilenceTimer(Function(String?) onComplete) {
    if (_silenceTimer?.isActive ?? false) return;

    _silenceTimer = Timer(const Duration(seconds: 2), () async {
      onComplete(await stopListening());
    });
  }

  Future<String?> stopListening() async {
    final path = await _recorder.stop();
    if(path!=null)
    {
      String? resp = await _speechToText(path);
      return resp;
    }
    return null;
  }

  Future<String?> _textToSpeech(String text) async {
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final savePath = "${dir.path}/speech.mp3";

    try {
      // Sending JSON and receiving a FILE
      await dio.download(
        "http://100.72.140.76:8000/text-to-speech",
        savePath,
        data: {"text": text}, // The JSON body
        options: Options(method: "POST"),
      );

      print("Speech saved to: $savePath");

      return savePath;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> speak(String text) async {
    try {
      String? path = await _textToSpeech(text);

      if(path==null)
        {
          return;
        }
      // 1. Load the local file (e.g., the one downloaded from FastAPI)
      await _player.setFilePath(path);

      // 2. Start playback
      await _player.play();
    } catch (e) {
      print("Playback Error: $e");
    }
  }

  Future<void> stopPlaying() async {
    await _recorder.stop();
    await _player.stop();
    if(_silenceTimer!=null)
    {
      _silenceTimer?.cancel();
    }
  }
  Future<void> dispose() async {
    await _recorder.stop();
    await _recorder.dispose();
    await _player.dispose();
    if(_silenceTimer!=null)
    {
      _silenceTimer?.cancel();
    }
  }
}

class ShukaMessage {
  String? errorMessage;
  String message;
  bool isUser;
  ThoughtDetails? thoughtDetails;

  ShukaMessage({required this.message, required this.isUser, this.errorMessage, this.thoughtDetails});

  factory ShukaMessage.fromError(String errorMessage) {
    return ShukaMessage(message: "We could not contact Shuka!", errorMessage: errorMessage, isUser: false);
  }

  factory ShukaMessage.fromResponse(String question, String answer, List<ShukaThought> steps, String thoughtSummary) {
    return ShukaMessage(message: answer, isUser: false, thoughtDetails: ThoughtDetails(question: question, steps: steps, answer: answer, thoughtsSummary: thoughtSummary));
  }

  factory ShukaMessage.fromStarter(String reply)
  {
    return ShukaMessage(message: reply, isUser: false);
  }

  factory ShukaMessage.fromUser(String message)
  {
    return ShukaMessage(message: message, isUser: true);
  }
}

class ThoughtDetails {
  String answer, question, thoughtsSummary;
  List<ShukaThought> steps;

  ThoughtDetails({required this.question, required this.steps, required this.answer, required this.thoughtsSummary});
}

class ShukaThought {
  String? details;
  String type, content;
  int sequence;

  ShukaThought({required this.type, required this.content, required this.sequence, this.details});

  factory ShukaThought.fromJson(Map<String, dynamic> json) {
    return ShukaThought(
      type: json["type"] as String,
      sequence: json["sequence"] as int,
      content: json["content"] as String,
      details: json["details"] as String?
    );
  }
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