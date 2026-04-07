import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hacker_news/auth/login_page.dart';
import 'package:hacker_news/home/story_details.dart';
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
  List<dynamic> storyIds = [];
  int loadOffset = 20;
  bool hasMore = true;
  bool isLoadingMore = false;
  String username = '';

  final _baseUrl = "https://news.ycombinator.com";
  // List<dynamic> storyIds = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _loadStories(apiLoaded: false);
    // _checkLoginAndLoadStories();
  }

  Future<String> _checkLoginAndLoadStories() async {
    var prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool("is_logged_in") ?? false;
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    if (isLoggedIn) {
      var rawCookie = prefs.getString('hn_session');
      if (rawCookie != null) {
        return rawCookie.split(';').first;
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
    return '';
  }

  Future<void> _loadStories44() async {
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
        storyIds = json.decode(res.body);
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

  Future<void> _getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('username') ?? '';

    if (username.isNotEmpty) {
      setState(() {
        username = user;
      });
    }
  }

  Future<void> _loadStories({
    bool loadMore = false,
    bool apiLoaded = true,
  }) async {
    try {
      _getUsername();
      if (loadMore) {
        setState(() => isLoadingMore = true);
      } else {
        setState(() => isLoading = true);
      }

      // API CALL ONLY ON FIRST LOAD (not loadMore)
      if (!apiLoaded) {
        print("search in api");
        final url = Uri.parse(
          'https://hacker-news.firebaseio.com/v0/newstories.json',
        );
        var res = await http.get(url);

        if (res.statusCode == 200) {
          storyIds = json.decode(res.body); // Load ONCE
          hasMore = true;
          isLoadingMore = false;
        }
      }

      // Take next 20 from cached storyIds
      final batchSize = 20;
      final startIndex = loadMore ? (stories.length) : 0;
      final endIndex = (startIndex + batchSize) > storyIds.length
          ? storyIds.length
          : startIndex + batchSize;

      List<Future<Story>> storyFutures = storyIds
          .sublist(startIndex, endIndex)
          .map((id) async => await _getStorie(id as int))
          .toList();

      final newStories = await Future.wait(storyFutures);

      setState(() {
        if (loadMore) {
          stories.addAll(newStories);
        } else {
          stories = newStories;
        }
        hasMore = endIndex < storyIds.length;
        isLoading = false;
        isLoadingMore = false;
      });

      print(
        "Loaded ${newStories.length}, total ${stories.length}/${storyIds.length}",
      );
    } catch (e) {
      print(e.toString());
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<Story> _getStorie(int id) async {
    var def = Story.def(id);
    print("get st");
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

  Future<String?> _getCsrfToken(
    int storyId,
    String action,
    String session,
  ) async {
    try {
      final url = Uri.parse('https://news.ycombinator.com/item?id=$storyId');
      final res = await http.get(url, headers: {'Cookie': session});

      if (res.statusCode == 200) {
        final body = res.body;
        final regExp = RegExp('id=$storyId[^>]*auth=([a-z0-9]+)');
        final match = regExp.firstMatch(res.body);

        return match?.group(1);
      }
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future<void> _vote(Story story, String action) async {
    final session = await _checkLoginAndLoadStories();
    print(isLoggedIn);
    if (!isLoggedIn || session.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required to vote')));
      return;
    }

    // 1. Get fresh CSRF token
    final token = await _getCsrfToken(story.id, action, session);
    if (token == null) {
      print('Failed to get CSRF token');
      return;
    }

    try {
      final url = Uri.parse(
        "$_baseUrl/vote?id=${story.id}&how=$action&auth=$token&goto=news",
      );

      final res = await http.get(url, headers: {'Cookie': session});

      if (res.statusCode == 302 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.toUpperCase()}d ${story.title}')),
        );
      }
    } catch (e) {
      print('Vote error: $e');
    }
  }

  Future<void> _showSubmitDialog() async {
    final session = await _checkLoginAndLoadStories();
    if (!isLoggedIn || session.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required to submit')));
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final urlController = TextEditingController();
        final textController = TextEditingController();

        return AlertDialog(
          title: const Text('Submit to HN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  hintText: 'https://example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Text'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'title': titleController.text,
                'url': urlController.text,
                'text': textController.text,
              }),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _submitPost(
        result['title']!,
        result['url']!,
        result['text']!,
        session,
      );
    }
  }

  Future<void> _submitPost(
    String title,
    String? url,
    String text,
    String session,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('https://news.ycombinator.com/submit'),
        headers: {'Cookie': session},
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to load submit page');
      }

      final regExp = RegExp(r'name="fnid" value="([^"]+)"');
      final match = regExp.firstMatch(res.body);

      if (match == null) return;
      final String fnid = match.group(1)!;

      print('CSRF Token: $fnid');

      // POST to submit
      final formData = {
        'title': title,
        'url': url ?? '',
        'fnid': fnid,
        'text': text,
      };

      final postRes = await http.post(
        Uri.parse('https://news.ycombinator.com/r'),
        headers: {
          'Cookie': session,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      print('Submit status: ${postRes.statusCode}');
      print('Location: ${postRes.headers['location']}');

      if (postRes.statusCode == 302 || postRes.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted! Check HN for approval.'),
            backgroundColor: Colors.green,
          ),
        );
        // NeW
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username') ?? '';

        if (username.isNotEmpty) {
          await _fetchAndInsertRecentPost(username, session);
        } else {
          _loadStories(apiLoaded: false);
        }

        // _loadStories(apiLoaded: false);
      }
    } catch (e) {
      print('Submit error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    }
  }

  Future<void> _fetchAndInsertRecentPost(
    String username,
    String session,
  ) async {
    print("_fetchAndInsertRecentPost");
    final url = Uri.parse(
      'https://news.ycombinator.com/submitted?id=$username',
    );
    final res = await http.get(url, headers: {'Cookie': session});
    if (res.statusCode == 200) {
      // item?id=47672610

      final regExp = RegExp(r'item\?id=(\d+)');
      final match = regExp.firstMatch(res.body);
      print("match");
      if (match != null) {
        final String newIdStr = match.group(1)!;
        print("idddddddddddddddddddd =>");
        print(newIdStr);
        final int newId = int.parse(newIdStr);

        // Fetch the full story details from the API
        final newStory = await _getStorie(newId);

        setState(() {
          // Add to the ID list and the actual Story list at the very top
          storyIds.insert(0, newId);
          stories.insert(0, newStory);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('New post synced!')));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear session data
    await prefs.remove('hn_session');
    await prefs.setBool('is_logged_in', false);

    setState(() {
      isLoggedIn = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );

    print('👋 Logged out');
  }

  Future<void> _confirmDelete(Story story) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: Text("Are you sure you want to delete '${story.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deletePost(story);
    }
  }

  Future<void> _deletePost(Story story) async {
    final session = await _checkLoginAndLoadStories();
    if (session.isEmpty) return;

    try {
      // 1. Visit the item page to find the delete link/token
      final itemUrl = Uri.parse(
        "https://news.ycombinator.com/item?id=${story.id}",
      );
      final res = await http.get(itemUrl, headers: {'Cookie': session});

      // 2. Look for the delete link pattern: x?id=ID&auth=TOKEN&how=del
      // Regex looking for the 'auth' token specifically for the 'del' action
      final regExp = RegExp(r'how=del&amp;auth=([a-z0-9]+)');
      final match = regExp.firstMatch(res.body);

      if (match == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Too late to delete or no permission.")),
        );
        return;
      }

      final String token = match.group(1)!;

      // 3. Execute the deletion
      final delUrl = Uri.parse(
        "https://news.ycombinator.com/x?id=${story.id}&how=del&auth=$token&goto=news",
      );

      final delRes = await http.get(delUrl, headers: {'Cookie': session});

      if (delRes.statusCode == 302 || delRes.statusCode == 200) {
        setState(() {
          stories.removeWhere((s) => s.id == story.id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Post deleted")));
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }

  Future<void> _loadMoreStories() async => _loadStories(loadMore: true);

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
          onPressed: isLoading
              ? null
              : () => _loadStories(loadMore: false, apiLoaded: false),
        ),
        IconButton(
          icon: const Icon(Icons.post_add),
          onPressed: _showSubmitDialog,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: _logout,
        ),
      ],
    ),
    body: Column(
      children: [
        // ListView (Expanded)
        Expanded(
          child: isLoading && stories.isEmpty
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
                        onPressed: () => _loadStories(apiLoaded: false),
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
                  onRefresh: () =>
                      _loadStories(loadMore: false, apiLoaded: false),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.keyboard_arrow_up,
                                            size: 35,
                                            color: Colors.orange[400],
                                          ),
                                          onPressed: () => _vote(story, 'up'),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Text(
                                          '${story.score}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 35,
                                            color: Colors.orange[400],
                                          ),
                                          onPressed: () => _vote(story, 'un'),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (story.by ==
                                              username) // Only show for own posts
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _confirmDelete(story),
                                            ),
                                          InkWell(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StoryDetailsScreen(
                                                      story: story,
                                                    ),
                                              ),
                                            ),
                                            child: Text(
                                              story.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(height: 20),
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
                                              child: Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black12,
                                                ),
                                                child: Text(
                                                  "(${story.url})",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
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
                                        story.by.isNotEmpty
                                            ? story.by
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                            : '?',
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
        ),

        // 🔥 LOAD MORE BUTTON
        if (hasMore)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[850],
            child: Center(
              child: ElevatedButton.icon(
                onPressed: isLoadingMore
                    ? null
                    : () => _loadStories(loadMore: true),
                icon: isLoadingMore
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(isLoadingMore ? 'Loading...' : 'Load More'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
