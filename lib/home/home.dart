import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hacker_news/auth/login_page.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> stories = [];
  List<dynamic> storyIds = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadStories();
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
      print("isLoggedIn == true");
      await _loadStories();
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
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
        storyIds = json.decode(res.body);
        stories = storyIds.take(20).map(item {

        });
      }
      print("kk");
    } catch (e) {
      print("error");
      print(e.toString());
    }

  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hello World!'),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => LoginPage()),
              );
            },
            child: Text("Login"),
          ),
        ],
      ),
    ),
  );
}
