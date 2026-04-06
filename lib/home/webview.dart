import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage(this.url, {super.key});

  @override
  State<WebViewPage> createState() => _WebViewState();
}

class _WebViewState extends State<WebViewPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    controller = WebViewController()
      ..loadRequest(
        Uri.parse(
          widget.url.startsWith('http') ? widget.url : 'https://${widget.url}',
        ),
      );
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
          onPressed: () => controller.reload(),
        ),
      ],
    ),
    body: Stack(
      children: [
        WebViewWidget(controller: controller),
      ],
    ),
  );
}
