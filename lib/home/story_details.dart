// // lib/screens/story_details.dart
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:hacker_news/models/story.dart';
// import 'package:hacker_news/home/webview.dart';

// import 'package:http/http.dart' as http;

// class StoryDetailsScreen extends StatelessWidget {
//   final Story story;
//   const StoryDetailsScreen({super.key, required this.story});

//   Future<CommentTree?> _fetchComments(int id) async {
//     final url = Uri.parse(
//       'https://hacker-news.firebaseio.com/v0/item/$id.json',
//     );
//     final res = await http.get(url);
//     if (res.statusCode != 200) return null;

//     final data = json.decode(res.body);
//     final kids = data['kids'] as List<dynamic>? ?? [];
//     final subComments = await Future.wait(
//       kids.map((kidId) => _fetchComments(kidId as int)),
//     );

//     return CommentTree(
//       id: data['id'] as int,
//       by: data['by'] as String,
//       text: data['text'] as String?,
//       comments: subComments.whereType<CommentTree>().toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.grey[900],
//     appBar: AppBar(
//       title: const Text('Story Details'),
//       backgroundColor: Colors.grey[850],
//       foregroundColor: Colors.white,
//     ),
//     body: SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title
//           Text(
//             story.title,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Metadata row
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   '${story.score} points',
//                   style: TextStyle(
//                     color: Colors.orange,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 story.by,
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '${story.descendants ?? 0} comments',
//                 style: TextStyle(color: Colors.grey[400]),
//               ),
//             ],
//           ),

//           // URL link (if exists)
//           if (story.url.isNotEmpty) ...[
//             const SizedBox(height: 16),
//             GestureDetector(
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => WebViewPage(story.url)),
//               ),
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.open_in_new, color: Colors.blue, size: 20),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         story.url,
//                         style: TextStyle(
//                           color: Colors.blue,
//                           decoration: TextDecoration.underline,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],

//           const SizedBox(height: 24),

//           const SizedBox(height: 20),

//           FutureBuilder<CommentTree?>(
//             future: _fetchComments(story.id),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData)
//                 return const Center(child: CircularProgressIndicator());
//               return ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: snapshot.data!.comments.length,
//                 itemBuilder: (context, index) =>
//                     CommentWidget(comment: snapshot.data!.comments[index]),
//               );
//             },
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // // Recursive comment tree
// // class CommentsScreen extends StatelessWidget {
// //   final int storyId;
// //   const CommentsScreen({super.key, required this.storyId});

// //   @override
// //   Widget build(BuildContext context) => Scaffold(
// //     backgroundColor: Colors.grey[900],
// //     appBar: AppBar(title: const Text('Comments')),
// //     body: FutureBuilder<CommentTree?>(
// //       future: _fetchComments(storyId),
// //       builder: (context, snapshot) {
// //         if (!snapshot.hasData)
// //           return const Center(child: CircularProgressIndicator());
// //         return ListView.builder(
// //           padding: const EdgeInsets.all(16),
// //           itemCount: snapshot.data!.comments.length,
// //           itemBuilder: (context, index) =>
// //               CommentWidget(comment: snapshot.data!.comments[index]),
// //         );
// //       },
// //     ),
// //   );

// //   Future<CommentTree?> _fetchComments(int id) async {
// //     final url = Uri.parse(
// //       'https://hacker-news.firebaseio.com/v0/item/$id.json',
// //     );
// //     final res = await http.get(url);
// //     if (res.statusCode != 200) return null;

// //     final data = json.decode(res.body);
// //     final kids = data['kids'] as List<dynamic>? ?? [];
// //     final subComments = await Future.wait(
// //       kids.map((kidId) => _fetchComments(kidId as int)),
// //     );

// //     return CommentTree(
// //       id: data['id'] as int,
// //       by: data['by'] as String,
// //       text: data['text'] as String?,
// //       comments: subComments.whereType<CommentTree>().toList(),
// //     );
// //   }
// // }

// // // Models (add to story.dart)




import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hacker_news/models/story.dart';
import 'package:hacker_news/home/webview.dart';
import 'package:http/http.dart' as http;

// Simple model for the tree
class CommentTree {
  final int id;
  final String by;
  final String text;
  final List<CommentTree> comments;

  CommentTree({
    required this.id,
    required this.by,
    required this.text,
    required this.comments,
  });
}

class StoryDetailsScreen extends StatefulWidget {
  final Story story;
  const StoryDetailsScreen({super.key, required this.story});

  @override
  State<StoryDetailsScreen> createState() => _StoryDetailsScreenState();
}

class _StoryDetailsScreenState extends State<StoryDetailsScreen> {
  late Future<CommentTree?> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments(widget.story.id);
  }

  Future<CommentTree?> _fetchComments(int id) async {
    try {
      final url = Uri.parse('https://hacker-news.firebaseio.com/v0/item/$id.json');
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body);
      final kids = data['kids'] as List<dynamic>? ?? [];
      
      // Fetch sub-comments in parallel
      final subComments = await Future.wait(
        kids.map((kidId) => _fetchComments(kidId as int)),
      );

      return CommentTree(
        id: data['id'] as int,
        by: data['by'] ?? '[deleted]',
        text: data['text'] ?? '',
        comments: subComments.whereType<CommentTree>().toList(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Story Details'),
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.story.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildMetadataRow(),
                  if (widget.story.url.isNotEmpty) _buildUrlButton(context),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Comments", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            // THE FIX: Use FutureBuilder here
            FutureBuilder<CommentTree?>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orange)));
                }
                if (!snapshot.hasData || snapshot.data!.comments.isEmpty) {
                  return const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)));
                }

                // Use ListView.builder with shrinkWrap inside SingleChildScrollView
                return ListView.builder(
                  shrinkWrap: true, // Crucial!
                  physics: const NeverScrollableScrollPhysics(), // Let SingleChildScrollView handle scroll
                  itemCount: snapshot.data!.comments.length,
                  itemBuilder: (context, index) => CommentWidget(comment: snapshot.data!.comments[index], depth: 0),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Row(
      children: [
        Text('${widget.story.score} pts', style: const TextStyle(color: Colors.orange)),
        const SizedBox(width: 10),
        Text('by ${widget.story.by}', style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildUrlButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(widget.story.url))),
        child: Text(widget.story.url, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
      ),
    );
  }
}

// THE RECURSIVE WIDGET
class CommentWidget extends StatelessWidget {
  final CommentTree comment;
  final int depth;

  const CommentWidget({super.key, required this.comment, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: depth * 12.0, top: 8, bottom: 4, right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.by, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          // Using Text.rich or simple Text for HTML content
          Text(
            comment.text.replaceAll(RegExp(r'<[^>]*>|&quot;'), ''), // Very basic HTML strip
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          // Recursively build children
          if (comment.comments.isNotEmpty)
            ...comment.comments.map((c) => CommentWidget(comment: c, depth: depth + 1)).toList(),
        ],
      ),
    );
  }
}