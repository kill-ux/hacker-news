class Story {
  final String by;
  final int descendants;
  final int id;
  final List<dynamic> kids;
  final int score;
  final int time;
  final String title;
  final String type;
  final String url;

  const Story._internal(
    this.by,
    this.descendants,
    this.id,
    this.kids,
    this.score,
    this.time,
    this.title,
    this.type,
    this.url,
  );

  factory Story.def(int id) {
    return Story._internal(
      '',
      0,
      id,
      [],
      0,
      0,
      'Error loading story',
      'story',
      '',
    );
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story._internal(
      json['by'] ?? '',
      json['descendants'] ?? 0,
      json['id'] ?? 0,
      json['kids'] ?? [],
      json['score'] ?? 0,
      json['time'] ?? 0,
      json['title'] ?? '',
      json['type'] ?? '',
      json['url'] ?? '',
    );
  }
}
