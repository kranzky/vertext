import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/markdown_service.dart';
import 'dart:io' show Platform;

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
  
  // Default homepage URL as specified in the project requirements
  static const String _homeUrl = 'https://mmm.kranzky.com';
  
  // State variables for content in both columns
  String _leftColumnContent = '';
  String _rightColumnContent = '';
  bool _hasRightContent = false;
  
  // Loading states
  bool _isLeftLoading = true;
  bool _isRightLoading = false;
  
  // Network status for feedback
  String _networkStatus = 'Initializing...';
  bool _showWelcomeWhileLoading = true;
  
  // Current URL and title for each column
  String _leftUrl = _homeUrl;
  String _leftTitle = 'Home';
  String _rightUrl = '';
  String _rightTitle = '';
  
  // User preferences
  bool _autoOpenNonMarkdownLinks = false;
  
  @override
  void initState() {
    super.initState();
    // Show welcome content immediately
    _leftColumnContent = _getWelcomeText();
    
    // Then load the remote content in the background
    _loadInitialContent();
  }
  
  // Load the initial content (home page)
  Future<void> _loadInitialContent() async {
    // Set a timeout to ensure we don't wait too long
    bool timeoutOccurred = false;
    Future.delayed(const Duration(seconds: 8), () {
      if (_isLeftLoading) {
        timeoutOccurred = true;
        setState(() {
          _networkStatus = 'Loading timed out. Using welcome screen.';
          _isLeftLoading = false;
        });
      }
    });
    
    try {
      setState(() {
        _networkStatus = 'Connecting to ${Uri.parse(_homeUrl).host}...';
      });
      
      final result = await _markdownService.fetchContent(_homeUrl);
      
      // Only update if a timeout didn't occur
      if (!timeoutOccurred) {
        setState(() {
          _leftColumnContent = result.content;
          _leftTitle = _markdownService.extractTitle(result.content, 'Home');
          _isLeftLoading = false;
          _showWelcomeWhileLoading = false;
          _networkStatus = 'Connected successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _networkStatus = 'Connection failed: ${e.toString().split('\n').first}';
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
    
    // Only process if URL is valid
    if (url.isEmpty) {
      return;
    }
    
    // Handle anchor links (e.g., #installation-instructions)
    if (url.startsWith('#')) {
      // Currently we don't support scrolling to anchors, so we'll just
      // show a message explaining this
      setState(() {
        _isRightLoading = false;
        _hasRightContent = true;
        _rightUrl = '';
        _rightTitle = 'Anchor Link';
        _rightColumnContent = '''# Anchor Link

The link you clicked ($url) is an anchor link to a section within the current page.

**Note:** Vertext currently doesn't support scrolling to specific sections within a document.

In a future version, we plan to implement this feature.
''';
      });
      return;
    }
    
    setState(() {
      _isRightLoading = true;
      _hasRightContent = true;
      _rightUrl = url;
      _rightTitle = title.isNotEmpty ? title : 'Loading...';
      
      // Show a loading placeholder while waiting
      _rightColumnContent = '# Loading $url\n\nPlease wait...';
    });
    
    // Timeout for right column loading
    bool timeoutOccurred = false;
    Future.delayed(const Duration(seconds: 10), () {
      if (_isRightLoading) {
        timeoutOccurred = true;
        setState(() {
          _isRightLoading = false;
          _rightColumnContent = '''# Request Timed Out
          
Unable to load content from $url within a reasonable time.

Possible reasons:
- The server might be slow or unresponsive
- The content might be very large
- There might be network connectivity issues

You can try clicking the link again.
''';
        });
      }
    });
    
    // Determine base URL for relative links
    String? baseUrl;
    if (_hasRightContent) {
      // If clicking from right column, use right URL as base
      baseUrl = _rightUrl;
    } else {
      // If clicking from left column, use left URL as base
      baseUrl = _leftUrl;
    }
    
    _fetchMarkdownContent(url, baseUrl).then((content) {
      if (!timeoutOccurred) {
        setState(() {
          _rightColumnContent = content;
          _rightTitle = _markdownService.extractTitle(content, title);
          _isRightLoading = false;
        });
      }
    }).catchError((error) {
      if (!timeoutOccurred) {
        setState(() {
          _isRightLoading = false;
          _rightColumnContent = '''# Error Loading Content
          
An error occurred while loading content from $url.

Error details: ${error.toString()}

You can try clicking the link again or try a different link.
''';
        });
      }
    });
  }
  
  // Opens a URL in the system's default browser
  Future<void> _openInSystemBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error opening URL in system browser: $e');
      
      // Show an error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Failed to Open URL'),
              content: Text('Could not open $url in your browser.\n\nError: $e'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      }
    }
  }
  
  // Show dialog to ask user about opening non-markdown content
  Future<void> _showNonMarkdownDialog(String url, String contentType) async {
    if (_autoOpenNonMarkdownLinks) {
      // If auto-open is enabled, open immediately without asking
      _openInSystemBrowser(url);
      return;
    }
    
    // Format content type for display
    String formattedType = contentType.isEmpty 
        ? 'non-markdown' 
        : contentType.split(';').first.trim();
    
    // Determine content type name for friendly display
    String contentTypeName = 'file';
    if (contentType.contains('html')) {
      contentTypeName = 'webpage';
    } else if (contentType.contains('pdf')) {
      contentTypeName = 'PDF document';
    } else if (contentType.contains('image/')) {
      contentTypeName = 'image';
    } else if (contentType.contains('video/')) {
      contentTypeName = 'video';
    } else if (contentType.contains('audio/')) {
      contentTypeName = 'audio file';
    }
    
    if (mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Open $contentTypeName?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This link points to a $contentTypeName that cannot be displayed in Vertext.'),
                const SizedBox(height: 12),
                Text('Would you like to open it in your default browser?'),
                const SizedBox(height: 8),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Technical Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  'Content-Type: $formattedType',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _autoOpenNonMarkdownLinks,
                      onChanged: (bool? value) {
                        setState(() {
                          _autoOpenNonMarkdownLinks = value ?? false;
                        });
                      },
                    ),
                    const Text('Always open in browser (don\'t ask again)'),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Open in Browser'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      
      if (result == true) {
        _openInSystemBrowser(url);
      }
    }
  }

  // Fetch content from a URL
  Future<String> _fetchMarkdownContent(String url, [String? baseUrl]) async {
    try {
      final result = await _markdownService.fetchContent(url, baseUrl);
      
      // Update the URL to the resolved one if it was relative
      if (result.url != url) {
        setState(() {
          _rightUrl = result.url;
        });
      }
      
      // If content is not markdown, offer to open in system browser
      if (!result.isMarkdown) {
        await _showNonMarkdownDialog(result.url, result.contentType);
        
        // Return a message indicating the content was opened externally
        return '''# External Content

This content was opened in your default browser because it's not markdown.

**URL**: ${result.url}
**Content Type**: ${result.contentType}

_Click on another markdown link to load content in this pane._
''';
      }
      
      // Otherwise, return the content as usual
      return result.content;
    } catch (e) {
      print('Error fetching content: $e');
      return '''# Error Loading Content

Unable to load content from: $url${baseUrl != null ? ' (relative to $baseUrl)' : ''}

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
              child: Column(
                children: [
                  // Network status indicator (only when loading)
                  if (_isLeftLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _networkStatus,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Small gap after status indicator
                  if (_isLeftLoading)
                    const SizedBox(height: 16),
                  
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: GptMarkdown(
                        _leftColumnContent,
                        onLinkTab: _handleLinkTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right column (50% width)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: _isRightLoading
                ? Column(
                    children: [
                      // Loading indicator with status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Loading content from ${Uri.parse(_rightUrl).host}...',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Placeholder text
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.downloading, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Loading $_rightTitle...',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _rightUrl,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _rightTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_rightUrl.isNotEmpty)
                                        Text(
                                          Uri.parse(_rightUrl).host,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back, size: 32, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Content from clicked links will appear here',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click on any link in the left column',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}