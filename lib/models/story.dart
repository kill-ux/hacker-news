class Story {
  String by;
  int descendants;
  int id;
  List<dynamic> kids;
  int score;
  int time;
  String title;
  String type;
  String url;

  Story._internal(
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
