import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:radiotalk/style.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:record/record.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: App(),
    );
  }
}

class App extends StatefulWidget {
  const App({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  bool speaking = false;
  late IO.Socket socket;
  bool connected = false;
  String channel = "général";
  List<String> status = ["Connexion à la radio"];
  AudioRecorder record = AudioRecorder();

  @override
  void initState() {
    super.initState();

    socket = IO.io("http://localhost:3000", <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      setState(() {
        status.insert(0, 'Connecté au canal $channel');
        connected = true;
        print('Connected to server');
      });
    });

    socket.onDisconnect((_) {
      setState(() {
        status.insert(0, 'Déconnecté');
        connected = false;
        print('Connection Disconnection');
      });
    });

    socket.onConnectError((err) {
      setState(() {
        status.insert(0, 'Erreur de connexion');
        connected = false;
        print('Connection Disconnection, $err');
      });
    });

    socket.onError((err) {
      setState(() {
        status.insert(0, 'Erreur de connexion');
        connected = false;
        print('Connection Disconnection, $err');
      });
    });

    socket.on('audioCast', (data) {
      print(data);
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    record.dispose();
    super.dispose();
  }

  void sendAudio(String message) {
    print("message");
    socket.emit('audioCast', message);
  }

  void startRecording() async {
    if (await record.hasPermission()) {
      await record.start(const RecordConfig(encoder: AudioEncoder.wav),
          path: './lib/myFile.wav');
      print(record);
    }
  }

  void stopRecording() async {
    final path = await record.stop();
    print(path);
    await record.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        titleTextStyle: TextStyle(color: yellow, fontSize: 20.0),
        title: const Text("Radio"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
              child: Center(
            child: Text(
              speaking ? "PARLEZ" : status[0],
              style: TextStyle(color: yellow, fontSize: speaking ? 25 : 15),
            ),
          )),
          Expanded(
            child: Center(
              child: GestureDetector(
                onLongPressStart: (details) {
                  if (connected) {
                    setState(() {
                      speaking = true;
                      startRecording();
                    });
                  }
                },
                onLongPressEnd: (details) {
                  if (connected) {
                    setState(() {
                      speaking = false;
                      sendAudio("message");
                      stopRecording();
                    });
                  }
                },
                child: AnimatedContainer(
                  curve: Curves.bounceInOut,
                  duration: const Duration(milliseconds: 100),
                  width: (speaking && connected) ? 200 : 150,
                  height: (speaking && connected) ? 200 : 150,
                  decoration: BoxDecoration(
                      color: connected ? yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(360)),
                  child: connected
                      ? const Icon(Icons.mic, color: Colors.black)
                      : CircularProgressIndicator(color: yellow),
                ),
              ),
            ),
          ),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Wrap(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.numbers,
                        color: yellow,
                      )),
                ],
              )
            ],
          ))
        ],
      ),
    );
  }
}
