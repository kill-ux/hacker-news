import 'package:hacker_news/home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _acct = TextEditingController();
  final _pw = TextEditingController();
  var _obscurePassword = true;
  var _error = "";

  @override
  void dispose() {
    super.dispose();
    _acct.dispose();
    _pw.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final url = Uri.https('news.ycombinator.com', '/login');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'acct=${_acct.text}&pw=${_pw.text}',
      );

      if (res.statusCode == 302) {
        print("save cred");
        var prefs = await SharedPreferences.getInstance();
        prefs.setString("username", _acct.text);
        prefs.setString("hn_session", "${res.headers['set-cookie']}");
        prefs.setBool("is_logged_in", true);
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        print("Faild login");
        _error = 'Login failed:';
      }
    } catch (e) {
      print(e.toString());
      _error = e.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HN Login")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 60),
                  Text(
                    'Hacker News',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  SizedBox(height: 60),
                  Text(
                    'Username',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _acct,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Username required' : null,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Password',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  SizedBox(height: 12),
                  TextFormField(
                    controller: _pw,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: Colors.white),

                    decoration: InputDecoration(
                      hintText: '••••••••',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[400],
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Password required' : null,
                  ),
                  SizedBox(height: 32),

                  //btn
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 73, 18),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
