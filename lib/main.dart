import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import "package:audioplayers/audioplayers.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterBackgroundService.initialize(onStart);

  runApp(MyApp());
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  final audioPlayer = AudioPlayer();
  String uri = "https://media.graphassets.com/RpXalWHISuyetFYPW9kE";
  int count = 0;
  service.onDataReceived.listen((event) {
    if (event!["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }

    if (event["action"] == "stopService") {
      service.stopBackgroundService();
    }
  });

  audioPlayer.onPlayerStateChanged.listen((event) {
      
    if (event == PlayerState.completed) {
      Map<String, dynamic> dataToSend = {"count": count++};
      service.sendData(dataToSend);
      audioPlayer.play(uri as Source);
    }
  });
  audioPlayer.play(uri as Source);

  // bring to foreground
  service.setForegroundMode(true);
  Timer.periodic(Duration(seconds: 1), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    service.setNotificationInfo(
      title: "My App Service",
      content: "Updated at ${DateTime.now()}",
    );

    service.sendData(
      {"current_date": DateTime.now().toIso8601String()},
    );
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isRunning = true;
  int playCount = 0;
  String text = "Stop Service";

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    FlutterBackgroundService.initialize(onStart);

    FlutterBackgroundService().onDataReceived.listen((event) {
      if (event!.isNotEmpty && event["count"] != null) {
        setState(() {
          playCount = event['count'] as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(isRunning ? Icons.play_arrow : Icons.stop),
        onPressed: () async {
          var isRunning = await FlutterBackgroundService().isServiceRunning();
          if (isRunning) {
            FlutterBackgroundService().sendData({"action": "stopService"});
          } else {
            FlutterBackgroundService.initialize(onStart);
          }
          setState(() {
            this.isRunning = !isRunning;
          });
        },
      ),
      body: Center(
          child: Column(
        children: [Text("$playCount")],
      )),
    );
  }
}
