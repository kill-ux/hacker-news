import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hacker_news/auth/login_page.dart';
import 'package:hacker_news/home/webview.dart';
import 'package:hacker_news/models/story.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Story> stories = [];
  // List<dynamic> storyIds = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadStories();
    // _checkLoginAndLoadStories();
  }

  Future<void> _checkLoginAndLoadStories() async {
    var prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool("is_logged_in") ?? false;
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    if (isLoggedIn) {
      // do actions
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<void> _loadStories() async {
    try {
      setState(() {
        isLoading = true;
      });
      final url = Uri.parse(
        'https://hacker-news.firebaseio.com/v0/newstories.json',
      );
      var res = await http.get(url);
      print(res.statusCode);
      if (res.statusCode == 200) {
        // storyIds = json.decode(res.body);
        List<dynamic> storyIds = json.decode(res.body);
        List<Future<Story>> storyFutures = storyIds
            .take(20)
            .map((id) async => await _getStorie(id))
            .toList();

        stories = await Future.wait(storyFutures);
        print("Loaded ${stories.length} stories");
        isLoading = false;
        setState(() {});
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Story> _getStorie(int id) async {
    var def = Story.def(id);
    try {
      final url = Uri.parse(
        'https://hacker-news.firebaseio.com/v0/item/$id.json',
      );
      var res = await http.get(url);
      if (res.statusCode == 200) {
        return Story.fromJson(json.decode(res.body));
      }
      return def;
    } catch (e) {
      print(e.toString());
      return def;
    }
  }

  void _launchUrl(Story story) {
    // if (story.url.isNotEmpty) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => WebViewPage(story.url)),
    //   );
    // }
    // var url =
  }

  Future<void> _vote(Story story, String action) async {
    _checkLoginAndLoadStories();
    if (!isLoggedIn) return;

    var prefs = await SharedPreferences.getInstance();

    print("hhhhhh");
    try {
      final url = Uri.parse(
        "https://news.ycombinator.com/vote?id=${story.id}&how=$action&js=t",
      );
      String session = prefs.getString('hn_sessio')!;
      print(session);
      var res = await http.get(
        url,
        headers: {'Cookie': session},
      );
      if (res.statusCode == 200) {
        print(res.headers['location']);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      title: const Text(
        'Hacker News',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading ? null : _loadStories,
        ),
      ],
    ),
    body: isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Loading stories...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        : stories.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.newspaper_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  "No stories loaded",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loadStories,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            color: Colors.orange,
            onRefresh: _loadStories,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: story.url.isNotEmpty
                        ? () => _launchUrl(story)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_upward,
                                  size: 20,
                                  color: Colors.orange[400],
                                ),
                                onPressed: () =>
                                    _vote(story, 'up'), // Works 100%
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              const SizedBox(width: 8),
                              Text(
                                '${story.score}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ), // Reduced from 16 to prevent overflow
                              Expanded(
                                // Wrap title in Expanded to prevent overflow
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      story.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.3,
                                      ),
                                      maxLines: 2, // Limit lines
                                      overflow: TextOverflow
                                          .ellipsis, // Add "..." for long titles
                                    ),
                                    if (story.url.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WebViewPage(story.url),
                                          ),
                                        ),
                                        child: Text(
                                          "(${story.url})",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.orange[700],
                                child: Text(
                                  story.by.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${story.by} • ${story.score} points • ${story.descendants} comments',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (story.url.isNotEmpty)
                                Icon(
                                  Icons.launch,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
