import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? localPath;
  final String? publicUrl;

  const VideoPlayerWidget({
    super.key,
    this.localPath,
    this.publicUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.localPath != null && await File(widget.localPath!).exists()) {
        _controller = VideoPlayerController.file(File(widget.localPath!));
      } else if (widget.publicUrl != null && widget.publicUrl!.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.publicUrl!));
      } else {
        setState(() {
          _hasError = true;
        });
        return;
      }

      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller!.play();
    } catch (e) {
      debugPrint("VideoPlayerWidget Error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        color: Colors.black26,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text("Video evidence unavailable", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller!),
          VideoProgressIndicator(_controller!, allowScrubbing: true),
          Center(
            child: IconButton(
              iconSize: 50,
              color: Colors.white70,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
              ),
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
