import 'package:flutter/material.dart';

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


class CommentTree {
  final int id;
  final String by;
  final String? text;
  final List<CommentTree> comments;
  CommentTree({required this.id, required this.by, this.text, required this.comments});
}

class CommentWidget extends StatelessWidget {
  final CommentTree comment;
  const CommentWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16, top: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.orange[700],
              child: Text(comment.by.substring(0,1).toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(comment.by, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        child: Text(
          comment.text ?? '',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      ...comment.comments.map((sub) => CommentWidget(comment: sub)),
    ],
  );
}