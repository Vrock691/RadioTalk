import 'package:flutter/material.dart';
import 'package:radiotalk/style.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  String channel = "0";
  List<String> status = ["Démarrage"];

  @override
  void initState() {
    super.initState();

    socket = IO.io("http://localhost:3000", <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      setState(() {
        print('Connected to server');
        status.add('Connecté au canal $channel');
      });
    });

    socket.onDisconnect((_) {
      setState(() {
        status.add('Déconnecté');
        print('Connection Disconnection');
      });
    });

    socket.onConnectError((err) {
      setState(() {
        status.add('Erreur de connexion');
        print('Connection Disconnection, $err');
      });
    });

    socket.onError((err) {
      setState(() {
        status.add('Erreur de connexion');
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
    super.dispose();
  }

  void sendAudio(String message) {
    print("message");
    socket.emit('audioCast', message);
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
              speaking ? "PARLEZ" : "Connecté au canal 800",
              style: TextStyle(color: yellow, fontSize: speaking ? 25 : 15),
            ),
          )),
          Expanded(
            child: Center(
              child: GestureDetector(
                onLongPressStart: (details) {
                  setState(() {
                    speaking = true;
                  });
                },
                onLongPressEnd: (details) {
                  setState(() {
                    speaking = false;
                    sendAudio("message");
                  });
                },
                child: AnimatedContainer(
                  curve: Curves.bounceInOut,
                  duration: const Duration(milliseconds: 100),
                  width: speaking ? 200 : 150,
                  height: speaking ? 200 : 150,
                  decoration: BoxDecoration(
                      color: yellow, borderRadius: BorderRadius.circular(360)),
                  child: const Icon(Icons.mic),
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