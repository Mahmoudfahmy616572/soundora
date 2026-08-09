class DeezerPlaylistModel {
  final int id;
  final String title;
  final String picture;
  final int trackCount;

  DeezerPlaylistModel({
    required this.id,
    required this.title,
    required this.picture,
    required this.trackCount,
  });

  factory DeezerPlaylistModel.fromJson(Map<String, dynamic> json) {
    return DeezerPlaylistModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      picture:
          (json['picture_xl'] ?? json['picture_big'] ?? json['picture_medium'] ??
              '') as String,
      trackCount: json['nb_tracks'] as int? ?? 0,
    );
  }
}
