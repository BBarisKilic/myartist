part of 'playback_bloc.dart';

@Freezed()
class PlaybackEvent with _$PlaybackEvent {
  const factory PlaybackEvent.togglePlayPause() = TogglePlayPause;
  const factory PlaybackEvent.changeSong(Song song) = ChangeSong;
  const factory PlaybackEvent.setVolume(double value) = SetVolume;
  const factory PlaybackEvent.toggleMute() = ToggleMute;

  const factory PlaybackEvent.moveToInSong(double percent) = MoveToInSong;

  const factory PlaybackEvent.songProgress(Duration duration) = SongProgress;
}
