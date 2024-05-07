import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:radiotalk/style.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const App(),
      color: yellow,
      theme: ThemeData.dark(),
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
  final storage = FirebaseStorage.instance.ref();
  TextEditingController controller = TextEditingController();
  bool webActivation = false;

  @override
  void initState() {
    super.initState();

    socket = IO.io("https://rt.vld-group.com", <String, dynamic>{
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

    socket.on('audioCast', (data) async {
      if (data["channel"] == channel && data['url'] != null) {
        if (kIsWeb) {
          if (webActivation) {
            final player = AudioPlayer();
            await player.setUrl(data['url']);
            player.play();
          }
        } else {
          final player = AudioPlayer();
          await player.setUrl(data['url']);
          player.play();
        }
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    record.dispose();
    super.dispose();
  }

  void sendAudio(String downloadURL) {
    socket.emit('audioCast', {
      "channel": channel,
      "url": downloadURL,
    });
  }

  void startRecording() async {
    if (await record.hasPermission()) {
      await record.start(const RecordConfig(encoder: AudioEncoder.wav),
          path: './lib/myFile.wav');
    }
  }

  void stopRecording() async {
    final path = await record.stop();

    if (kIsWeb) {
      final blobFilePath = path;
      if (blobFilePath != null) {
        final uri = Uri.parse(blobFilePath);
        final client = http.Client();
        final request = await client.get(uri);
        final bytes = request.bodyBytes;
        final newref =
            'audios/$channel/${DateTime.now().toIso8601String()}.wav';
        try {
          await storage.child(newref).putData(bytes);
        } catch (e) {
          status.insert(0, e.toString());
        }
        final url = await storage.child(newref).getDownloadURL();
        sendAudio(url);
      }
    } else {
      if (path != null) {
        final newref =
            'audios/$channel/${DateTime.now().toIso8601String()}.wav';
        try {
          await storage.child(newref).putFile(File(path));
        } catch (e) {
          status.insert(0, e.toString());
        }
        final url = await storage.child(newref).getDownloadURL();
        sendAudio(url);
      }
    }

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
                  webActivation = true;
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
          if (kIsWeb && !webActivation)
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    webActivation = true;
                  });
                },
                child: Text(
                  "Activer le son",
                  style: TextStyle(color: yellow),
                )),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Wrap(
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          controller.text = channel;
                        });
                        showModalBottomSheet(
                            backgroundColor: background,
                            context: context,
                            builder: (context) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 25),
                                    const Text(
                                      "Changer de canal",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Expanded(child: Container()),
                                    SizedBox(
                                      width: 90,
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 25, color: Colors.white),
                                        controller: controller,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            controller.text = "général";
                                          });
                                        },
                                        child: const Text(
                                          "général",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                    Expanded(child: Container()),
                                    ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            webActivation = true;
                                            if (controller.text != "") {
                                              channel = controller.text;
                                              status.insert(0,
                                                  'Connecté au canal $channel');
                                            }
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text(
                                            "Changer de canal",
                                            style: TextStyle(color: yellow),
                                          ),
                                        )),
                                    const SizedBox(height: 25)
                                  ],
                                ),
                              );
                            });
                      },
                      icon: Icon(
                        Icons.numbers,
                        color: yellow,
                      )),
                  IconButton(
                      onPressed: () => showAboutDialog(
                          context: context,
                          applicationName: "RadioTalk",
                          applicationVersion: "1.0",
                          applicationLegalese:
                              "Merci d'avoir installé cette appliation.\nCode source sur le profil github de Vrock691"),
                      icon: Icon(
                        Icons.info,
                        color: yellow,
                      ))
                ],
              )
            ],
          ))
        ],
      ),
    );
  }
}
