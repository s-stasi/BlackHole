import 'package:blackhole/Helpers/audio_query.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

class DownedSongsCache {
  DownedSongsCache() {
    getData();
  }
  final List<SongModel>? cachedSongs = null;
  List<SongModel> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  final Map<String, List<SongModel>> albums = {};
  final Map<String, List<SongModel>> artists = {};
  final Map<String, List<SongModel>> genres = {};

  final List<String> sortedAlbumKeysList = [];
  final List<String> sortedArtistKeysList = [];
  final List<String> sortedGenreKeysList = [];
  // final List<String> _videos = [];

  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box('settings').get('orderValue', defaultValue: 1) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths =
      Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  int minDuration =
      Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  bool includeOrExclude =
      Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<PlaylistModel> playlistDetails = [];

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  bool checkIncludedOrExcluded(SongModel _song) {
    for (final path in includedExcludedPaths) {
      if (_song.data.contains(path.toString())) return true;
    }
    return false;
  }

  Future<void> getData() async {
    await offlineAudioQuery.requestPermission();
    tempPath ??= (await getTemporaryDirectory()).path;
    playlistDetails = await offlineAudioQuery.getPlaylists();
    if (cachedSongs == null) {
      _songs = (await offlineAudioQuery.getSongs(
        sortType: songSortTypes[sortValue],
        orderType: songOrderTypes[orderValue],
      ))
          .where(
            (i) =>
                (i.duration ?? 60000) > 1000 * minDuration &&
                (i.isMusic! || i.isPodcast! || i.isAudioBook!) &&
                (includeOrExclude
                    ? checkIncludedOrExcluded(i)
                    : !checkIncludedOrExcluded(i)),
          )
          .toList();
    } else {
      _songs = cachedSongs!;
    }
    added = true;
    for (int i = 0; i < _songs.length; i++) {
      if (albums.containsKey(_songs[i].album)) {
        albums[_songs[i].album]!.add(_songs[i]);
      } else {
        albums.addEntries([
          MapEntry(_songs[i].album!, [_songs[i]])
        ]);
        sortedAlbumKeysList.add(_songs[i].album!);
      }

      if (artists.containsKey(_songs[i].artist)) {
        artists[_songs[i].artist]!.add(_songs[i]);
      } else {
        artists.addEntries([
          MapEntry(_songs[i].artist!, [_songs[i]])
        ]);
        sortedArtistKeysList.add(_songs[i].artist!);
      }

      if (genres.containsKey(_songs[i].genre)) {
        genres[_songs[i].genre]!.add(_songs[i]);
      } else {
        genres.addEntries([
          MapEntry(_songs[i].genre.toString(), [_songs[i]])
        ]);
        sortedGenreKeysList.add(_songs[i].genre.toString());
      }
    }
    debugPrint('$albums');
  }

  Future<void> sortSongs(int sortVal, int order) async {
    switch (sortVal) {
      case 0:
        _songs.sort(
          (a, b) => a.displayName.compareTo(b.displayName),
        );
        break;
      case 1:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
      case 2:
        _songs.sort(
          (a, b) => a.album.toString().compareTo(b.album.toString()),
        );
        break;
      case 3:
        _songs.sort(
          (a, b) => a.artist.toString().compareTo(b.artist.toString()),
        );
        break;
      case 4:
        _songs.sort(
          (a, b) => a.duration.toString().compareTo(b.duration.toString()),
        );
        break;
      case 5:
        _songs.sort(
          (a, b) => a.size.toString().compareTo(b.size.toString()),
        );
        break;
      default:
        _songs.sort(
          (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
        );
        break;
    }

    if (order == 1) {
      _songs = _songs.reversed.toList();
    }
  }
}
