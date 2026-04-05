import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:uuid/uuid.dart';

class WearComms {
  final String targetCapability;
  final FlutterWearOsConnectivity _flutterWearOsConnectivity =  FlutterWearOsConnectivity();
  WearOsDevice? _targetDevice;
  Map<String, dynamic> _idToCallback = {};
  Map<String, StreamSubscription<WearOSMessage>> _pathSet = {};

  WearComms({required this.targetCapability});

  Future<bool> init() async {
    await _flutterWearOsConnectivity.configureWearableAPI();
    Map<String, CapabilityInfo> capabilities = await _flutterWearOsConnectivity.getAllCapabilities(filterType: CapabilityFilterType.all);

    if(capabilities.containsKey(targetCapability)) {
      CapabilityInfo? shukaCap = capabilities[targetCapability];
      if(shukaCap!=null) {
        _targetDevice = shukaCap.associatedDevices.first;
        return true;
      }
    }

    return false;
  }

  void dispose() {
    _pathSet.forEach((key, sub) => sub.cancel());
  }

  Future<void> sendMessageToTarget(String path, WearCommsMessage message, Function(WearCommsMessage) callback) async {
    Uint8List payload = Uint8List.fromList(json.encode(message.toMap()).codeUnits);

    try {
      _initReceiveMessageFromTarget(path);

      int requestId = await _flutterWearOsConnectivity.sendMessage(
        payload,
        deviceId: _targetDevice!.id,
        path: "/query",
        priority: MessagePriority.high,
      );
      print("Message sent! Request ID: $requestId");
      _idToCallback.addAll({
        message.id : {
          "callback": callback,
          "complete": false
        }
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _initReceiveMessageFromTarget(String path) {
    if(!_pathSet.containsKey(path))
    {
      _pathSet[path] = _flutterWearOsConnectivity.messageReceived(
          pathURI: Uri(scheme: "wear", host: "*", path: path)
      ).listen((WearOSMessage message) {
        final req = utf8.decode(message.data);

        print("Response : $req");

        WearCommsMessage decodedMessage = WearCommsMessage.fromJson(json.decode(req));


        if(_idToCallback.containsKey(decodedMessage.id))
        {
          return;
        }

        print("Received: $decodedMessage");
        print("From Device ID: ${message.sourceNodeId}");

        if(!_idToCallback[decodedMessage.id]["complete"]) {
          if(decodedMessage.complete)
            {
              _idToCallback[decodedMessage.id]["complete"]=true;
            }
          _idToCallback[decodedMessage.id]["callback"](decodedMessage);
        }
      });
    }
  }

  void receiveMessageFromTarget(String path, Function(WearCommsMessage) processor) {
    if(!_pathSet.containsKey(path))
    {
      _pathSet[path] = _flutterWearOsConnectivity.messageReceived(
          pathURI: Uri(scheme: "wear", host: "*", path: path)
      ).listen((WearOSMessage message) async {
        final req = utf8.decode(message.data);

        print("Request : $req");

        WearCommsMessage decodedMessage = WearCommsMessage.fromJson(json.decode(req));

        final id = decodedMessage.id;

        processor(decodedMessage);
      });
    }
  }

  Future<void> sendResponseToTarget(String path, WearCommsMessage message) async {

    final payload = Uint8List.fromList(json.encode(message.toMap()).codeUnits);

    try {
      int requestId = await _flutterWearOsConnectivity.sendMessage(
        payload,
        deviceId: _targetDevice!.id,
        path: "/query",
        priority: MessagePriority.high,
      );
      print("Message sent! Request ID: $requestId");
    } catch (e) {
      print("Error sending message: $e");
    }
  }

}

class WearCommsMessage {
  String message, id;
  bool complete;

  WearCommsMessage({required this.message, required this.id, this.complete = true});

  factory WearCommsMessage.fromMessage(String message) {
    return WearCommsMessage(message: message, id: Uuid().v4());
  }

  factory WearCommsMessage.fromId(String message, String id) {
    return WearCommsMessage(message: message, id: id);
  }

  factory WearCommsMessage.fromJson(Map<String, dynamic> json) {
    return WearCommsMessage(message: json["message"], id: json["id"], complete: json["complete"] ?? true);
  }

  toMap() {
    return {
      "message":message,
      "id":id,
      "complete":complete
    };
  }
}