part of 'playback_bloc.dart';

@Freezed()
class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    @Default(0.5) double volume,
    double? previousVolume,
    @Default(false) bool isMuted,
    @Default(false) bool isPlaying,
    SongWithProgress? songWithProgress,
  }) = _PlaybackState;

  factory PlaybackState.initial() => const PlaybackState();
}

@Freezed()
class SongWithProgress with _$SongWithProgress {
  const factory SongWithProgress({
    required Duration progress,
    required Song song,
  }) = _SongWithProgress;
}
