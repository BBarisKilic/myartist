import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../classes/classes.dart';
import '../extensions.dart';
import '../playback/bloc/bloc.dart';
import '../providers/providers.dart';
import 'image_clipper.dart';

class BottomBar extends StatelessWidget implements PreferredSizeWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<PlaybackBloc>(context);
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      bloc: bloc,
      builder: (context, state) => _BottomBar(
        artist: state.songWithProgress?.song.artist,
        isMuted: state.isMuted,
        isPlaying: state.isPlaying,
        preferredSize: preferredSize,
        progress: state.songWithProgress?.progress,
        song: state.songWithProgress?.song,
        togglePlayPause: () => bloc.add(const PlaybackEvent.togglePlayPause()),
        volume: state.volume,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    Key? key,
    required this.artist,
    required this.isMuted,
    required this.isPlaying,
    required this.preferredSize,
    required this.progress,
    required this.song,
    required this.togglePlayPause,
    required this.volume,
  }) : super(key: key);

  final Artist? artist;
  final bool isMuted;
  final bool isPlaying;
  final Size preferredSize;
  final Duration? progress;
  final Song? song;
  final VoidCallback togglePlayPause;
  final double volume;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => constraints.isTablet
            ? _buildDesktopBar(context, constraints)
            : _buildMobileBar(context, constraints),
      );

  Widget _buildDesktopBar(BuildContext context, BoxConstraints constraints) {
    return ColoredBox(
      child: SizedBox.fromSize(
        size: preferredSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                _AlbumArt(song: song),
                _SongDetails(
                  artist: artist,
                  song: song,
                ),
              ],
            ),
            Flexible(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _PlaybackControls(
                    isPlaying: isPlaying,
                    togglePlayPause: togglePlayPause,
                  ),
                  Center(
                    child: _ProgressBar(
                      progress: progress,
                      song: song,
                    ),
                  ),
                ],
              ),
            ),
            if (constraints.isDesktop) ...[
              _VolumeBar(volume: volume, isMuted: isMuted),
            ],
            if (song != null)
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  final overlay = Overlay.of(context);
                  OverlayEntry? entry;
                  entry = OverlayEntry(
                    builder: (context) => Stack(
                      children: [
                        Positioned(
                          child: _FullScreenPlayer(
                            onClose: () {
                              entry?.remove();
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                  overlay!.insert(entry);
                },
              ),
          ],
        ),
      ),
      color: Theme.of(context).colorScheme.tertiaryContainer,
    );
  }

  double get songProgress => progress != null && song != null
      ? progress!.inMilliseconds / song!.length.inMilliseconds
      : 0;

  Widget _buildMobileBar(BuildContext context, BoxConstraints constraints) {
    return ColoredBox(
      child: SizedBox(
        height: kToolbarHeight,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            final overlay = Overlay.of(context);
            OverlayEntry? entry;
            entry = OverlayEntry(
              builder: (context) => Stack(
                children: [
                  Positioned(
                    child: _MobilePlayer(
                      onClose: () {
                        entry?.remove();
                      },
                    ),
                  ),
                ],
              ),
            );
            overlay!.insert(entry);
          },
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 4,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: songProgress.clamp(0, 1),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              Positioned(
                left: 4,
                bottom: 4,
                top: 4,
                right: 4,
                child: Row(
                  children: [
                    _AlbumArt(song: song),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song?.title ?? '',
                          style: context.labelMedium,
                        ),
                        Text(
                          song?.artist.name ?? '',
                          style: context.labelSmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: togglePlayPause,
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      color: Theme.of(context).colorScheme.tertiaryContainer,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    Key? key,
    required this.progress,
    required this.song,
  }) : super(key: key);

  final Duration? progress;

  final Song? song;

  double get songProgress => progress != null && song != null
      ? progress!.inMilliseconds / song!.length.inMilliseconds
      : 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        late EdgeInsets padding = EdgeInsets.zero;
        if (constraints.maxWidth > 500) {
          padding = const EdgeInsets.symmetric(horizontal: 50);
        } else if (constraints.maxWidth < 350) {
          padding = const EdgeInsets.symmetric(horizontal: 25);
        } else {
          padding = const EdgeInsets.symmetric(horizontal: 20);
        }
        return Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              SizedBox(
                child: progress != null
                    ? Text(progress!.toHumanizedString(),
                        style: Theme.of(context).textTheme.bodySmall)
                    : const Text('-'),
              ),
              Expanded(
                child: Slider(
                  value: songProgress.clamp(0, 1),
                  divisions: 1000,
                  onChanged: (percent) {
                    BlocProvider.of<PlaybackBloc>(context).add(
                      PlaybackEvent.moveToInSong(percent),
                    );
                  },
                  onChangeEnd: (percent) {
                    BlocProvider.of<PlaybackBloc>(context).add(
                      PlaybackEvent.moveToInSong(percent),
                    );

                    BlocProvider.of<PlaybackBloc>(context).add(
                      const PlaybackEvent.togglePlayPause(),
                    );
                  },
                  activeColor:
                      Theme.of(context).colorScheme.onTertiaryContainer,
                  inactiveColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(
                child: song != null
                    ? Text(song!.length.toHumanizedString(),
                        style: Theme.of(context).textTheme.bodySmall)
                    : const Text('-'),
              ),
              const SizedBox(width: 10)
            ],
          ),
        );
      },
    );
  }
}

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({
    Key? key,
    required this.volume,
    required this.isMuted,
  }) : super(key: key);

  final double volume;

  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 200,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => BlocProvider.of<PlaybackBloc>(context).add(
                const PlaybackEvent.toggleMute(),
              ),
              child: Icon(!isMuted ? Icons.volume_mute : Icons.volume_off),
            ),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 100,
                onChanged: (newValue) => BlocProvider.of<PlaybackBloc>(context)
                    .add(PlaybackEvent.setVolume(newValue)),
                activeColor: Theme.of(context).colorScheme.onTertiaryContainer,
                inactiveColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    Key? key,
    required this.isPlaying,
    required this.togglePlayPause,
  }) : super(key: key);

  final bool isPlaying;
  final VoidCallback togglePlayPause;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double iconSize = 24;
      double playIconSize = 32;
      double innerPadding = 16;
      double playPadding = 20;
      if (constraints.maxWidth < 500) {
        iconSize = 21;
        playIconSize = 28;
        innerPadding = 14;
        playPadding = 17;
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: EdgeInsets.fromLTRB(0, 0, innerPadding, 0),
              child: Icon(Icons.shuffle, size: iconSize)),
          Icon(Icons.skip_previous, size: iconSize),
          Padding(
            padding: EdgeInsets.fromLTRB(playPadding, 0, innerPadding, 0),
            child: GestureDetector(
              onTap: togglePlayPause,
              child: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: playIconSize,
              ),
            ),
          ),
          Icon(Icons.skip_next, size: iconSize),
          Padding(
            padding: EdgeInsets.fromLTRB(innerPadding, 0, 0, 0),
            child: Icon(Icons.repeat, size: iconSize),
          ),
        ],
      );
    });
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({
    Key? key,
    required this.song,
  }) : super(key: key);

  final Song? song;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 70,
        height: 70,
        child: song != null
            ? Image.asset(song!.image.image)
            : Container(
                color: Colors.pink[100],
              ),
      ),
    );
  }
}

class _SongDetails extends StatelessWidget {
  const _SongDetails({
    Key? key,
    required this.artist,
    required this.song,
  }) : super(key: key);

  final Artist? artist;
  final Song? song;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song != null ? song!.title : '-',
              style: context.labelLarge!.copyWith(fontSize: 12),
              overflow: TextOverflow.clip,
              maxLines: 1,
            ),
            Text(
              artist != null ? artist!.name : '-',
              style: context.labelSmall!.copyWith(fontSize: 8),
              overflow: TextOverflow.clip,
            ),
          ],
        );
      },
    );
  }
}

class _FullScreenPlayer extends StatefulWidget {
  const _FullScreenPlayer({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  final VoidCallback onClose;

  @override
  State<_FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<_FullScreenPlayer> {
  bool _showControls = true;
  Timer? _controlsTimer;

  void hideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    hideControls();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<PlaybackBloc>(context);
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      bloc: bloc,
      builder: (context, state) => Theme(
        data: ThemeProvider.of(context).dark(),
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, dimens) {
              return MouseRegion(
                onHover: (_) {
                  setState(() {
                    _showControls = true;
                  });
                  hideControls();
                },
                child: buildPlayer(context, state, dimens),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildPlayer(
      BuildContext context, PlaybackState state, BoxConstraints dimens) {
    final bloc = BlocProvider.of<PlaybackBloc>(context);
    final current = state.songWithProgress;
    final song = current?.song;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: current == null
              ? const Center(child: Text('No song selected'))
              : Container(
                  color: context.colors.shadow,
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      song!.image.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            color: song != null
                ? context.colors.onSurface
                : context.colors.onBackground,
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: widget.onClose,
          ),
        ),
        if (song != null) ...[
          Positioned(
            left: 60,
            bottom: dimens.biggest.height * 0.28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: dimens.biggest.height * 0.2,
                  child: ClippedImage(song.image.image),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: context.labelLarge!.copyWith(fontSize: 42),
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                    ),
                    Text(
                      song.artist.name,
                      style: context.labelSmall!.copyWith(
                          fontSize: 20,
                          color: context.colors.onSurface.withOpacity(0.8)),
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            left: 20,
            bottom: dimens.biggest.height * 0.2,
            child: _ProgressBar(
              progress: current?.progress,
              song: song,
            ),
          ),
          Positioned(
            right: 20,
            left: 20,
            bottom: dimens.biggest.height * 0.1,
            child: AnimatedOpacity(
              duration: kThemeAnimationDuration,
              opacity: _showControls ? 1 : 0,
              child: Transform.scale(
                scale: 1.5,
                child: _PlaybackControls(
                  isPlaying: state.isPlaying,
                  togglePlayPause: () =>
                      bloc.add(const PlaybackEvent.togglePlayPause()),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MobilePlayer extends StatelessWidget {
  const _MobilePlayer({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<PlaybackBloc>(context);
    return BlocBuilder<PlaybackBloc, PlaybackState>(
      bloc: bloc,
      builder: (context, state) => Theme(
        data: ThemeProvider.of(context).dark(),
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, dimens) {
              return buildPlayer(context, state, dimens);
            },
          ),
        ),
      ),
    );
  }

  Widget buildPlayer(
      BuildContext context, PlaybackState state, BoxConstraints dimens) {
    final bloc = BlocProvider.of<PlaybackBloc>(context);
    final current = state.songWithProgress;
    return Stack(
      children: [
        Positioned.fill(
          child: current == null
              ? const Center(child: Text('No song selected'))
              : Container(
                  color: context.colors.shadow,
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      current.song.image.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: IconButton(
            color: current?.song != null
                ? context.colors.onSurface
                : context.colors.onBackground,
            icon: const RotatedBox(
              child: Icon(Icons.chevron_right),
              quarterTurns: 1,
            ),
            onPressed: onClose,
          ),
        ),
        if (current != null) ...[
          if (dimens.biggest.height > 500)
            Positioned(
              top: kToolbarHeight,
              left: 0,
              right: 0,
              height: dimens.biggest.height * 0.5,
              child: Image.asset(
                current.song.image.image,
                fit: BoxFit.contain,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: dimens.biggest.height * 0.1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        current.song.title,
                        style: context.labelLarge!.copyWith(fontSize: 22),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                      Text(
                        current.song.artist.name,
                        style: context.labelSmall!.copyWith(
                            fontSize: 12,
                            color: context.colors.onSurface.withOpacity(0.8)),
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Transform.scale(
                    scale: 1.5,
                    child: _PlaybackControls(
                      isPlaying: state.isPlaying,
                      togglePlayPause: () =>
                          bloc.add(const PlaybackEvent.togglePlayPause()),
                    ),
                  ),
                ),
                _ProgressBar(
                  progress: current.progress,
                  song: current.song,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
