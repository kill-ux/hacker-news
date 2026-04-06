// lib/screens/story_details.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hacker_news/models/story.dart';
import 'package:hacker_news/home/webview.dart';

import 'package:http/http.dart' as http;

class StoryDetailsScreen extends StatelessWidget {
  final Story story;
  const StoryDetailsScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      title: const Text('Story Details'),
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            story.title,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.white
            ),
          ),
          const SizedBox(height: 12),
          
          // Metadata row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${story.score} points',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(story.by, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${story.descendants ?? 0} comments', 
                style: TextStyle(color: Colors.grey[400])),
            ],
          ),
          
          // URL link (if exists)
          if (story.url.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WebViewPage(story.url)),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        story.url,
                        style: TextStyle(
                          color: Colors.blue, 
                          decoration: TextDecoration.underline,
                          fontSize: 14
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Comments button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (story.descendants ?? 0) == 0
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(storyId: story.id)
                    ),
                  ),
              icon: const Icon(Icons.comment_outlined),
              label: Text('${story.descendants ?? 0} comments'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}






// Recursive comment tree
class CommentsScreen extends StatelessWidget {
  final int storyId;
  const CommentsScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(title: const Text('Comments')),
    body: FutureBuilder<CommentTree?>(
      future: _fetchComments(storyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.comments.length,
          itemBuilder: (context, index) => CommentWidget(comment: snapshot.data!.comments[index]),
        );
      },
    ),
  );

  Future<CommentTree?> _fetchComments(int id) async {
    final url = Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json');
    final res = await http.get(url);
    if (res.statusCode != 200) return null;
    
    final data = json.decode(res.body);
    final kids = data['kids'] as List<dynamic>? ?? [];
    final subComments = await Future.wait(kids.map((kidId) => _fetchComments(kidId as int)));
    
    return CommentTree(
      id: data['id'] as int,
      by: data['by'] as String,
      text: data['text'] as String?,
      comments: subComments.whereType<CommentTree>().toList(),
    );
  }
}

// Models (add to story.dart)
