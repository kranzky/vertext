import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const VertextApp());
}

class VertextApp extends StatelessWidget {
  const VertextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertext',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BrowserScreen(title: 'Vertext Browser'),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key, required this.title});

  final String title;

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  // Simple placeholder for a "Welcome" message
  // State variables for content in both columns
  final String _welcomeText = 
  '''# Welcome to Vertext!

This is going to be a browser for the indie web, written in Flutter.

The browser is lightweight and fast, with planned versions for:
* iOS
* Android
* Mac
* Windows desktop
* Web

## Features
* Renders Markdown content only
* Side-by-side columns for tabs
* Links open in the opposite column
* Lightweight and fast

The browser should begin with the following home page: https://mmm.kranzky.com

_Note: This is a placeholder. In the future, we'll actually fetch and display Markdown content._
''';

  // Placeholder for the right column content
  String _rightColumnContent = '';
  bool _hasRightContent = false;
  
  // Method to handle link taps
  void _handleLinkTap(String url, String title) {
    setState(() {
      _rightColumnContent = "# $title\n\nLink clicked: $url\n\nIn a future version, this will load actual markdown content from this URL.";
      _hasRightContent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          // Left column (50% width)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: GptMarkdown(
                  _welcomeText,
                  onLinkTab: _handleLinkTap,
                ),
              ),
            ),
          ),
          // Right column (50% width)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _hasRightContent 
                ? SingleChildScrollView(
                    child: GptMarkdown(
                      _rightColumnContent,
                    ),
                  )
                : const Center(
                    child: Text(
                      'Content from clicked links will appear here',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}