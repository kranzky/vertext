import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'services/markdown_service.dart';
import 'models/browser_state.dart';
import 'models/tab_model.dart';
import 'widgets/browser_column.dart';
import 'widgets/status_bar_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window manager if on desktop platform
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    // Load window preferences
    final prefs = await SharedPreferences.getInstance();
    bool wasMaximized = prefs.getBool('window_maximized') ?? true;
    double width = prefs.getDouble('window_width') ?? 1200;
    double height = prefs.getDouble('window_height') ?? 800;
    double? left = prefs.getDouble('window_left');
    double? top = prefs.getDouble('window_top');
    
    // Configure window options
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: left == null || top == null, // Center if no position is saved
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    // Apply window options first
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (left != null && top != null) {
        await windowManager.setPosition(Offset(left, top));
      }
      await windowManager.show();
      
      // Maximize if it was maximized before
      if (wasMaximized) {
        await windowManager.maximize();
      }
    });
  }
  
  runApp(const VertextApp());
}

class VertextApp extends StatefulWidget {
  const VertextApp({super.key});

  @override
  State<VertextApp> createState() => _VertextAppState();
}

class _VertextAppState extends State<VertextApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    // Add window listener to save window state on desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    // Remove window listener when app is disposed
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // Save window state when window is being closed
  @override
  void onWindowClose() async {
    await _saveWindowState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.destroy();
    }
  }

  // Save window position, size, and state when moved or resized
  @override
  void onWindowMoved() async {
    await _saveWindowState();
  }

  @override
  void onWindowResized() async {
    await _saveWindowState();
  }

  @override
  void onWindowMaximize() async {
    await _saveWindowState();
  }

  @override
  void onWindowUnmaximize() async {
    await _saveWindowState();
  }

  // Helper method to save window state
  Future<void> _saveWindowState() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Save window maximized state
        bool isMaximized = await windowManager.isMaximized();
        await prefs.setBool('window_maximized', isMaximized);
        
        // Only save size and position if not maximized
        if (!isMaximized) {
          Size size = await windowManager.getSize();
          await prefs.setDouble('window_width', size.width);
          await prefs.setDouble('window_height', size.height);
          
          Offset position = await windowManager.getPosition();
          await prefs.setDouble('window_left', position.dx);
          await prefs.setDouble('window_top', position.dy);
        }
        
        debugPrint('Window state saved: maximized=$isMaximized');
      } catch (e) {
        debugPrint('Error saving window state: $e');
      }
    }
  }

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
  
  // Default homepage URL is now a local asset
  static const String _homeUrl = 'asset://assets/markdown/welcome.md';
  
  // Storage key for saving browser state
  static const String _storageKey = 'vertext_browser_state';
  
  // Browser state for tab management
  late BrowserState _browserState;
  
  // Loading state for initial load
  bool _isInitializing = true;
  
  // User preferences
  bool _autoOpenNonMarkdownLinks = false;
  
  // UUID generator for tab IDs
  final Uuid _uuid = const Uuid();
  
  // Track hovered URLs for status bar (not used currently)
  String? _hoveredLinkUrl;
  
  // Status bar references to update hovered link state
  final leftStatusBarKey = GlobalKey();
  final rightStatusBarKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    
    // Create a default browser state (will be replaced if we can restore)
    final initialTab = TabModel(
      id: _uuid.v4(),
      url: _homeUrl,
      title: 'Home',
      content: _getWelcomeText(),
      isLoading: true,
    );
    
    _browserState = BrowserState(
      homeUrl: _homeUrl,
      initialLeftTab: initialTab,
    );
    
    // Attempt to restore state, then load any necessary content
    _restoreBrowserState().then((_) {
      // After restoring (or using default), load content for active tabs
      if (_browserState.leftColumn.activeTab != null) {
        _loadTabContent(
          _browserState.leftColumn.activeTab!,
          _browserState.leftColumn.activeTab!.url,
          null
        );
      }
      
      if (_browserState.rightColumn.activeTab != null) {
        _loadTabContent(
          _browserState.rightColumn.activeTab!,
          _browserState.rightColumn.activeTab!.url,
          null
        );
      }
    });
  }
  
  /// Attempts to restore browser state from storage.
  /// Returns true if successful, false otherwise.
  Future<bool> _restoreBrowserState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);
      
      if (stateJson != null) {
        // Attempt to decode and restore state
        final Map<String, dynamic> stateMap = jsonDecode(stateJson);
        final restoredState = BrowserState.fromJson(stateMap);
        
        setState(() {
          _browserState = restoredState;
          _isInitializing = false;
        });
        
        debugPrint('Restored browser state with ${_browserState.leftColumn.tabs.length} tabs in left column, '
            '${_browserState.rightColumn.tabs.length} tabs in right column');
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring browser state: $e');
    }
    
    return false;
  }
  
  /// Saves the current browser state to storage.
  Future<void> _saveBrowserState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateMap = _browserState.toJson();
      final stateJson = jsonEncode(stateMap);
      
      await prefs.setString(_storageKey, stateJson);
      debugPrint('Saved browser state');
    } catch (e) {
      debugPrint('Error saving browser state: $e');
    }
  }
  
  // Load content for a tab
  Future<void> _loadTabContent(TabModel tab, String url, String? baseUrl) async {
    // CRITICAL LOGGING FOR DEBUGGING
    debugPrint('↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓');
    debugPrint('LOADING TAB CONTENT:');
    debugPrint('URL: $url');
    debugPrint('baseUrl: $baseUrl');
    debugPrint('tab.url: ${tab.url}');
    
    // Handle simple markdown filenames with http base URLs
    if (baseUrl != null && 
        baseUrl.startsWith('http') && 
        !url.contains('://') && 
        url.contains('.') &&
        !url.contains('/')) {
      
      try {
        final baseUri = Uri.parse(baseUrl);
        final newUrl = '${baseUri.scheme}://${baseUri.host}/$url';
        debugPrint('Converting simple filename to absolute URL:');
        debugPrint('Original URL: $url');
        debugPrint('New URL: $newUrl');
        
        url = newUrl;
        tab.url = newUrl;
        baseUrl = null; // Don't need baseUrl for absolute URLs
      } catch (e) {
        debugPrint('Error converting to absolute URL: $e');
      }
    }
    debugPrint('↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑');
    
    // Set a timeout for loading
    bool timeoutOccurred = false;
    Future.delayed(const Duration(seconds: 8), () {
      if (tab.isLoading) {
        timeoutOccurred = true;
        setState(() {
          // Find which column the tab is in
          final inLeftColumn = _browserState.leftColumn.tabs.any((t) => t.id == tab.id);
          final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
          
          // Find the tab index
          final tabIndex = column.tabs.indexWhere((t) => t.id == tab.id);
          if (tabIndex != -1) {
            tab.isLoading = false;
            tab.content = _getErrorMarkdown(
              'Loading Timed Out',
              'The request to $url took too long to complete.'
            );
            tab.title = 'Error';
          }
        });
      }
    });
    
    try {
      setState(() {
        // Loading state update
      });
      
      final result = await _markdownService.fetchContent(url, baseUrl);
      
      debugPrint('Content loaded! URL: ${result.url}, isMarkdown: ${result.isMarkdown}');
      
      // Only update if a timeout didn't occur
      if (!timeoutOccurred) {
        // If content is not markdown, offer to open in system browser
        if (!result.isMarkdown) {
          await _showNonMarkdownDialog(result.url, result.contentType);
          
          // Update tab with a message indicating external opening
          setState(() {
            tab.isLoading = false;
            tab.content = '''# External Content

This content was opened in your default browser because it's not markdown.

**URL**: ${result.url}
**Content Type**: ${result.contentType}

_Click on another markdown link to load content in this pane._
''';
            tab.title = 'External Content';
            tab.url = result.url; // Update to the resolved URL
            
            _isInitializing = false;
          });
          
          // Save state after updating tab content
          _saveBrowserState();
        } else {
          setState(() {
            // Update the tab with the fetched markdown content
            tab.isLoading = false;
            tab.content = result.content;
            tab.title = _markdownService.extractTitle(result.content, 'Page');
            tab.url = result.url; // Update to the resolved URL
            
            _isInitializing = false;
          });
          
          // Save state after updating tab content
          _saveBrowserState();
        }
      }
    } catch (e) {
      if (!timeoutOccurred) {
        setState(() {
          tab.isLoading = false;
          tab.content = _getErrorMarkdown(
            'Error Loading Content',
            'Error details: ${e.toString()}'
          );
          tab.title = 'Error';
          
          _isInitializing = false;
        });
      }
      debugPrint('Error loading content: $e');
    }
  }
  
  // Get static welcome text as fallback
  String _getWelcomeText() {
    return '''# Welcome to Vertext!

This is a browser for the indie web and local markdown files, written in Flutter.

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
* Supports local files with file:// URLs
* Loads files from application assets
* Remembers scroll position per tab

## Try clicking these links:

* [Visit mmm.kranzky.com](https://mmm.kranzky.com)
* [About Markdown](about:markdown)
* [Local Sample](sample.md)
* [Learn More](https://www.markdownguide.org)
''';
  }
  
  // Helper to create error markdown
  String _getErrorMarkdown(String title, String details) {
    return '''# $title

Unable to load the requested content.

## Error Details
```
$details
```

Please check the URL and try again.
''';
  }

  // Method to handle hover over links - update status bar
  void _handleLinkHover(String? url, bool isLeft) {
    // BrowserColumn now handles hover state internally
  }
  
  // Method to handle link taps
  void _handleLinkTap(String url, String title, TabModel? sourceTab) {
    debugPrint('Link tapped: $url, title: $title');
    
    // Only process if URL is valid
    if (url.isEmpty) {
      return;
    }
    
    // Handle anchor links (e.g., #installation-instructions)
    // Note: These are now handled directly in BrowserColumn._handleLinkTap
    if (url.startsWith('#')) {
      return;
    }
    
    // Determine which column the link was clicked from
    final clickedFromActiveLeftTab = sourceTab != null && 
        _browserState.leftColumn.tabs.any((tab) => tab.id == sourceTab.id);
    
    final sourceColumn = clickedFromActiveLeftTab 
        ? _browserState.leftColumn 
        : _browserState.rightColumn;
    
    final targetColumn = clickedFromActiveLeftTab 
        ? _browserState.rightColumn 
        : _browserState.leftColumn;
    
    // CRITICAL FIX: Use the source tab's URL as the base URL, not just the active tab
    // This ensures relative links on mmm.kranzky.com use mmm.kranzky.com as their base
    String? baseUrl;
    if (sourceTab != null) {
      baseUrl = sourceTab.url;
      
      // Debug the source tab info for verification
      debugPrint('SOURCE TAB (from which link was clicked):');
      debugPrint('ID: ${sourceTab.id}');
      debugPrint('URL: ${sourceTab.url}');
      debugPrint('Title: ${sourceTab.title}');
    }
    
    // Store original URL for logging
    final originalUrl = url;
    
    // SPECIAL HANDLING FOR mmm.kranzky.com AND OTHER WEB DOMAINS
    // If the base URL is from a web domain and this is a relative link, we need to
    // ensure it becomes a full URL to that domain
    if (baseUrl != null && baseUrl.startsWith('http')) {
      debugPrint('WEB DOMAIN DETECTED IN BASE URL: $baseUrl');
      
      // If this is a simple filename or other relative path without protocol
      if (!url.contains('://') && !url.startsWith('http://') && !url.startsWith('https://')) {
        try {
          final baseUri = Uri.parse(baseUrl);
          String newUrl;
          
          if (url.startsWith('/')) {
            // Absolute path relative to domain (e.g., /path/file.md)
            newUrl = '${baseUri.scheme}://${baseUri.host}$url';
          } else {
            // Simple filename or relative path (e.g., file.md or dir/file.md)
            newUrl = '${baseUri.scheme}://${baseUri.host}/${url.startsWith('./') ? url.substring(2) : url}';
          }
          
          debugPrint('🔴 CONVERTING WEB RELATIVE LINK 🔴');
          debugPrint('Original URL: $url');
          debugPrint('Base URL: $baseUrl');
          debugPrint('New URL: $newUrl');
          
          // Use the absolute URL and clear the base URL since it's now an absolute URL
          url = newUrl;
          baseUrl = null;
        } catch (e) {
          debugPrint('Error converting to absolute URL: $e');
        }
      }
    }
    
    // Create a new tab for the link
    final newTab = TabModel(
      id: _uuid.v4(),
      url: url, // Use the potentially modified URL here
      title: title.isNotEmpty ? title : 'Loading...',
      isLoading: true,
    );
    
    // Debug log for URL transformation
    if (url != originalUrl) {
      debugPrint('URL was transformed from $originalUrl to $url');
    }
    
    setState(() {
      // Add tab to target column and make it active
      targetColumn.tabs.add(newTab);
      targetColumn.activeTabIndex = targetColumn.tabs.length - 1;
    });
    
    // Log the final URL and base URL for debugging
    debugPrint('Creating tab with URL: ${newTab.url}, baseUrl: $baseUrl');
    
    // Load content for the new tab, passing the baseUrl for proper resolution
    _loadTabContent(newTab, url, baseUrl);
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
      debugPrint('Error opening URL in system browser: $e');
      
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

  // Handle creating a new tab with URL prompt
  void _handleNewTab(bool inLeftColumn) {
    _showUrlPromptDialog(context, inLeftColumn);
  }
  
  // Show dialog to prompt for URL
  Future<void> _showUrlPromptDialog(BuildContext context, bool inLeftColumn) async {
    final textController = TextEditingController(text: 'https://');
    
    if (!mounted) return;
    
    final String? url = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter a URL to load',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Or choose a local file:'),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse...'),
                    onPressed: () async {
                      final result = await _pickFile();
                      if (result != null) {
                        Navigator.of(context).pop(result);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Load'),
              onPressed: () => Navigator.of(context).pop(textController.text),
            ),
          ],
        );
      },
    );
    
    if (url != null && url.isNotEmpty) {
      final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
      final newTab = column.createTab(
        url: url,
        title: 'Loading...',
      );
      
      setState(() {
        column.activeTabIndex = column.tabs.length - 1;
      });
      
      _loadTabContent(newTab, url, null);
      
      // Save state after adding a new tab
      _saveBrowserState();
    }
  }
  
  // Pick a file using system dialog
  Future<String?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          // Convert to file:// URL format
          return 'file://${file.path}';
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
  
  // Handle selecting a tab
  void _handleSelectTab(bool inLeftColumn, int index) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    // Only process if it's actually a different tab
    if (column.activeTabIndex != index) {
      setState(() {
        column.activeTabIndex = index;
      });
      
      // Save state after changing active tab
      _saveBrowserState();
      
      debugPrint('Selected tab at index $index with scroll position: ${column.tabs[index].scrollPosition}');
    }
  }
  
  // Handle closing a tab
  void _handleCloseTab(bool inLeftColumn, int index) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    setState(() {
      // Add to closed tabs
      if (index >= 0 && index < column.tabs.length) {
        column.closeTab(index);
      }
      
      // Create a new home tab if the left column is now empty
      if (inLeftColumn && column.tabs.isEmpty) {
        final newTab = _browserState.ensureLeftColumnHasTab();
        if (newTab != null) {
          _loadTabContent(newTab, _homeUrl, null);
        }
      }
    });
    
    // Save state after closing a tab
    _saveBrowserState();
  }
  
  // Handle reopening a closed tab
  void _handleReopenTab(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    final reopenedTab = column.reopenClosedTab();
    
    if (reopenedTab != null) {
      setState(() {
        // Update UI
      });
      
      // Save state after reopening a tab
      _saveBrowserState();
      
      // Refresh content if needed
      if (reopenedTab.content.isEmpty || reopenedTab.isLoading) {
        _loadTabContent(reopenedTab, reopenedTab.url, null);
      }
    }
  }
  
  // Handle reordering tabs within a column
  void _handleReorderTab(bool inLeftColumn, int oldIndex, int newIndex) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    setState(() {
      if (oldIndex < column.tabs.length && newIndex < column.tabs.length) {
        final tab = column.tabs.removeAt(oldIndex);
        column.tabs.insert(newIndex, tab);
        
        // Adjust active tab index if needed
        if (column.activeTabIndex == oldIndex) {
          column.activeTabIndex = newIndex;
        } else if (oldIndex < column.activeTabIndex && newIndex >= column.activeTabIndex) {
          column.activeTabIndex--;
        } else if (oldIndex > column.activeTabIndex && newIndex <= column.activeTabIndex) {
          column.activeTabIndex++;
        }
      }
    });
    
    // Save state after reordering tabs
    _saveBrowserState();
  }
  
  // Handle moving a tab to the other column
  void _handleMoveToOtherColumn(bool fromLeft, TabModel tab) {
    setState(() {
      final tabIndex = fromLeft 
          ? _browserState.leftColumn.tabs.indexWhere((t) => t.id == tab.id)
          : _browserState.rightColumn.tabs.indexWhere((t) => t.id == tab.id);
      
      if (tabIndex != -1) {
        _browserState.moveTabBetweenColumns(fromLeft, tabIndex);
      }
    });
    
    // Save state after moving a tab
    _saveBrowserState();
  }


  // Open a local file in the specified column
  void _openLocalFile(bool inLeftColumn) async {
    final fileUrl = await _pickFile();
    if (fileUrl != null) {
      final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
      final newTab = column.createTab(
        url: fileUrl,
        title: 'Loading...',
      );
      
      setState(() {
        column.activeTabIndex = column.tabs.length - 1;
      });
      
      _loadTabContent(newTab, fileUrl, null);
      
      // Save state after adding a new tab
      _saveBrowserState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar - to move tabs to the very top
      body: Column(
        children: [
          // Loading indicator (only visible when initializing)
          if (_isInitializing)
            LinearProgressIndicator(
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Left column (50% width)
                Expanded(
                  child: BrowserColumn(
                    columnModel: _browserState.leftColumn,
                    onNewTab: () => _handleNewTab(true),
                    onSelectTab: (index) => _handleSelectTab(true, index),
                    onCloseTab: (index) => _handleCloseTab(true, index),
                    onReopenTab: () => _handleReopenTab(true),
                    onReorderTab: (oldIndex, newIndex) => 
                        _handleReorderTab(true, oldIndex, newIndex),
                    onMoveToOtherColumn: (tab) => _handleMoveToOtherColumn(true, tab),
                    onLinkTap: (url, title, tab) => _handleLinkTap(url, title, tab),
                    onLinkHover: _handleLinkHover,
                    statusBarKey: leftStatusBarKey,
                    isLeft: true,
                  ),
                ),
                
                // Right column (50% width)
                Expanded(
                  child: BrowserColumn(
                    columnModel: _browserState.rightColumn,
                    onNewTab: () => _handleNewTab(false),
                    onSelectTab: (index) => _handleSelectTab(false, index),
                    onCloseTab: (index) => _handleCloseTab(false, index),
                    onReopenTab: () => _handleReopenTab(false),
                    onReorderTab: (oldIndex, newIndex) => 
                        _handleReorderTab(false, oldIndex, newIndex),
                    onMoveToOtherColumn: (tab) => _handleMoveToOtherColumn(false, tab),
                    onLinkTap: (url, title, tab) => _handleLinkTap(url, title, tab),
                    onLinkHover: _handleLinkHover,
                    statusBarKey: rightStatusBarKey,
                    isLeft: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}