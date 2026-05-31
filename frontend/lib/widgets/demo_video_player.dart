// Autor: Pedro Vinícius Romanato - 25004075
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget que exibe um player de vídeo de demonstração a partir de uma URL do Firebase Storage.
/// Inclui controles de play/pause, barra de progresso e tratamento de erros de carregamento.
class DemoVideoPlayer extends StatefulWidget {
  /// URL do vídeo hospedado no Firebase Storage
  final String videoUrl;
  const DemoVideoPlayer({super.key, required this.videoUrl});

  @override
  State<DemoVideoPlayer> createState() => _DemoVideoPlayerState();
}

class _DemoVideoPlayerState extends State<DemoVideoPlayer> {
  late VideoPlayerController _controller;

  // Indica se ocorreu algum erro durante a inicialização ou reprodução
  bool _hasError = false;

  // Indica se o player foi inicializado com sucesso e está pronto para exibição
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Valida o domínio da URL para garantir que apenas vídeos do Firebase Storage sejam carregados
    if (!widget.videoUrl.startsWith(
      'https://firebasestorage.googleapis.com/',
    )) {
      setState(() => _hasError = true);
      return;
    }

    // Inicializa o controller com a URL de rede e registra callbacks de sucesso e falha
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            // Atualiza o estado para exibir o player somente se o widget ainda estiver montado
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          })
          .catchError((error) {
            // Em caso de falha na inicialização, exibe a tela de erro
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

    // Exibe mensagem de erro caso o vídeo não possa ser carregado
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

    // Exibe um indicador de carregamento enquanto o vídeo está sendo inicializado
    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00A84E)),
        ),
      );
    }

    // Renderiza o player de vídeo com bordas arredondadas, overlay de controles e barra de progresso
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            // Mantém a proporção original do vídeo
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Componente principal de renderização do vídeo
                VideoPlayer(_controller),
                // Overlay de controles
                AbsorbPointer(
                  absorbing: !_isInitialized,
                  child: _ControlsOverlay(controller: _controller),
                ),
                // Barra de progresso arrastável com cores personalizadas
                AbsorbPointer(
                  absorbing: !_isInitialized,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF00A84E),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
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

/// Widget interno responsável pelo overlay de controles de reprodução (Play/Pause/Replay).
/// Verifica o estado do controller a todo momento verificando às mudanças de reprodução.
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
    // Registra o listener para reconstruir o overlay sempre que o estado do player mudar
    widget.controller.addListener(_updateOverlay);
  }

  @override
  void didUpdateWidget(_ControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Troca o listener caso o controller seja substituído
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateOverlay);
      widget.controller.addListener(_updateOverlay);
    }
  }

  @override
  void dispose() {
    // Remove o listener ao desmontar para evitar memory leaks
    widget.controller.removeListener(_updateOverlay);
    super.dispose();
  }

  /// Força a reconstrução do widget quando o estado do player muda
  void _updateOverlay() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Determina se o vídeo chegou ao final para exibir o ícone de replay
    final bool isFinished =
        widget.controller.value.isInitialized &&
        widget.controller.value.position >= widget.controller.value.duration;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        //replay se finalizado, play/pause caso contrário
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
          // Exibe o ícone de controle com transição animada; oculto durante reprodução
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 50),
            reverseDuration: const Duration(milliseconds: 200),
            child: widget.controller.value.isPlaying
                ? const SizedBox.shrink() // Nenhum ícone durante reprodução
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
