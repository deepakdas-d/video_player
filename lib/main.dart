import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'videoplayer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AudioService once here
  final audioHandler = await AudioService.init(
    builder: () => VideoAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.demo.video_channel',
      androidNotificationChannelName: 'Video Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final VideoAudioHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AudioServiceWidget(
        child: MyHomePage(
          title: 'Flutter Demo Home Page',
          audioHandler: audioHandler,
        ),
      ),
    );
  }
}
