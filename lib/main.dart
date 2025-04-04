import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/markdown_service.dart';

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
  // Service for fetching markdown content
  final MarkdownService _markdownService = MarkdownService();
  
  // Default homepage URL - using a public GitHub raw content URL for testing
  // Later we'll switch back to the mmm.kranzky.com domain
  static const String _homeUrl = 'https://raw.githubusercontent.com/adam-p/markdown-here/master/README.md';
  
  // State variables for content in both columns
  String _leftColumnContent = '';
  String _rightColumnContent = '';
  bool _hasRightContent = false;
  
  // Loading states
  bool _isLeftLoading = true;
  bool _isRightLoading = false;
  
  // Current URL and title for each column
  String _leftUrl = _homeUrl;
  String _leftTitle = 'Home';
  String _rightUrl = '';
  String _rightTitle = '';
  
  @override
  void initState() {
    super.initState();
    // Load the home page when the app starts
    _loadInitialContent();
  }
  
  // Load the initial content (home page)
  Future<void> _loadInitialContent() async {
    try {
      final content = await _markdownService.fetchMarkdown(_homeUrl);
      setState(() {
        _leftColumnContent = content;
        _leftTitle = _markdownService.extractTitle(content, 'Home');
        _isLeftLoading = false;
      });
    } catch (e) {
      setState(() {
        _leftColumnContent = _getWelcomeText();
        _isLeftLoading = false;
      });
      print('Error loading initial content: $e');
    }
  }
  
  // Get static welcome text as fallback
  String _getWelcomeText() {
    return '''# Welcome to Vertext!

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

## Try clicking these links:

* [Visit mmm.kranzky.com](https://mmm.kranzky.com)
* [Example 1: GitHub](https://github.com)
* [Example 2: Flutter Documentation](https://flutter.dev/docs)
* [Example 3: Markdown Guide](https://www.markdownguide.org)
''';
  }
  
  // Method to handle link taps
  void _handleLinkTap(String url, String title) {
    print('Link tapped: $url, title: $title');
    
    setState(() {
      _isRightLoading = true;
      _hasRightContent = true;
      _rightUrl = url;
      _rightTitle = title;
    });
    
    _fetchMarkdownContent(url).then((content) {
      setState(() {
        _rightColumnContent = content;
        _rightTitle = _markdownService.extractTitle(content, title);
        _isRightLoading = false;
      });
    });
  }
  
  // Fetch markdown content from a URL
  Future<String> _fetchMarkdownContent(String url) async {
    try {
      return await _markdownService.fetchMarkdown(url);
    } catch (e) {
      print('Error fetching content: $e');
      return '''# Error Loading Content

Unable to load content from: $url

Error details: $e
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Text(widget.title),
            const SizedBox(width: 16),
            if (_leftTitle.isNotEmpty)
              Expanded(
                child: Text(
                  '| $_leftTitle',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        actions: [
          // Refresh button for left column
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload current page',
            onPressed: () {
              setState(() {
                _isLeftLoading = true;
              });
              _fetchMarkdownContent(_leftUrl).then((content) {
                setState(() {
                  _leftColumnContent = content;
                  _leftTitle = _markdownService.extractTitle(content, 'Page');
                  _isLeftLoading = false;
                });
              });
            },
          ),
          // Home button
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Go to home page',
            onPressed: () {
              setState(() {
                _isLeftLoading = true;
                _leftUrl = _homeUrl;
              });
              _fetchMarkdownContent(_homeUrl).then((content) {
                setState(() {
                  _leftColumnContent = content;
                  _leftTitle = _markdownService.extractTitle(content, 'Home');
                  _isLeftLoading = false;
                });
              });
            },
          ),
        ],
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
              child: _isLeftLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: GptMarkdown(
                      _leftColumnContent,
                      onLinkTab: _handleLinkTap,
                    ),
                  ),
            ),
          ),
          // Right column (50% width)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _isRightLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasRightContent 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and URL bar for right column
                        if (_rightTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _rightTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Close this content',
                                  onPressed: () {
                                    setState(() {
                                      _hasRightContent = false;
                                      _rightColumnContent = '';
                                      _rightTitle = '';
                                      _rightUrl = '';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: GptMarkdown(
                              _rightColumnContent,
                              onLinkTab: _handleLinkTap,
                            ),
                          ),
                        ),
                      ],
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