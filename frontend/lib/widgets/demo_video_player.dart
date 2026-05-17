import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DemoVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const DemoVideoPlayer({super.key, required this.videoUrl});

  @override
  State<DemoVideoPlayer> createState() => _DemoVideoPlayerState();
}

class _DemoVideoPlayerState extends State<DemoVideoPlayer> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (!widget.videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
      setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Vídeo Indisponível",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF00A84E))),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                _ControlsOverlay(controller: _controller),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF00A84E),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateOverlay);
  }

  @override
  void didUpdateWidget(_ControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateOverlay);
      widget.controller.addListener(_updateOverlay);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateOverlay);
    super.dispose();
  }

  void _updateOverlay() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = widget.controller.value.isInitialized &&
        widget.controller.value.position >= widget.controller.value.duration;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isFinished) {
          widget.controller.seekTo(Duration.zero);
          widget.controller.play();
        } else {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        }
      },
      child: Stack(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 50),
            reverseDuration: const Duration(milliseconds: 200),
            child: widget.controller.value.isPlaying
                ? const SizedBox.shrink()
                : Container(
                    color: Colors.black26,
                    child: Center(
                      child: Icon(
                        isFinished ? Icons.replay : Icons.play_arrow,
                        color: Colors.white,
                        size: 100.0,
                        semanticLabel: isFinished ? 'Replay' : 'Play',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
