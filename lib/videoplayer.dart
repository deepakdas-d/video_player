import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.audioHandler,
  });

  final String title;
  final VideoAudioHandler audioHandler;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _videoPlayerController;
  late VideoAudioHandler _audioHandler;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    // Assign the handler passed from main
    _audioHandler = widget.audioHandler;

    _initializeAudioSession();
    _initializeVideoPlayer();
  }

  Future<void> _initializeAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
      ),
    );
    await session.setActive(true);

    // Listen to playback state to sync video player
    _audioHandler.playbackState.listen((state) {
      if (state.playing && !_videoPlayerController.value.isPlaying) {
        _chewieController?.play();
      } else if (!state.playing && _videoPlayerController.value.isPlaying) {
        _chewieController?.pause();
      }
    });
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.asset('assets/demo.mp4');
    _videoPlayerController.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: false,
          looping: true,
          placeholder: const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            );
          },
        );
        _isVideoInitialized = true;
      });

      // Update media info for notification
      _audioHandler.updateMediaItem(
        const MediaItem(
          id: 'video_asset',
          title: 'Demo Video',
          artist: 'Sample Artist',
        ),
      );
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _audioHandler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _isVideoInitialized
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Chewie(controller: _chewieController!),
                        )
                        : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoAudioHandler extends BaseAudioHandler {
  VideoAudioHandler() {
    // Initial playback state with controls
    playbackState.add(
      PlaybackState(
        controls: [MediaControl.play, MediaControl.pause, MediaControl.stop],
        androidCompactActionIndices: [0, 1, 2],
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.pause, MediaControl.stop],
      ),
    );
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [MediaControl.play, MediaControl.stop],
      ),
    );
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
        controls: [MediaControl.play],
      ),
    );
  }

  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }
}
