import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'services/markdown_service.dart';
import 'models/browser_state.dart';
import 'models/tab_model.dart';
import 'widgets/browser_column.dart';

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
  
  // Browser state for tab management
  late BrowserState _browserState;
  
  // Loading state for initial load
  bool _isInitializing = true;
  
  // UUID generator for tab IDs
  final Uuid _uuid = const Uuid();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize browser state with home URL
    _browserState = BrowserState(
      homeUrl: _homeUrl,
    );
    
    // Create initial home tab
    final initialTab = TabModel(
      id: _uuid.v4(),
      url: _homeUrl,
      title: 'Home',
      content: _getWelcomeText(),
      isLoading: true,
    );
    
    // Set the initial tab
    _browserState = BrowserState(
      homeUrl: _homeUrl,
      initialLeftTab: initialTab,
    );
    
    // Load content for the home tab
    _loadTabContent(initialTab, _homeUrl, null);
  }
  
  // Load content for a tab
  Future<void> _loadTabContent(TabModel tab, String url, String? baseUrl) async {
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
      
      // Only update if a timeout didn't occur
      if (!timeoutOccurred) {
        setState(() {
          // Update the tab with the fetched content
          tab.isLoading = false;
          tab.content = result.content;
          tab.title = _markdownService.extractTitle(result.content, 'Page');
          tab.url = result.url; // Update to the resolved URL
          
          _isInitializing = false;
        });
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

This is a browser for the indie web, written in Flutter.

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

  // Method to handle link taps
  void _handleLinkTap(String url, String title) {
    debugPrint('Link tapped: $url, title: $title');
    
    // Only process if URL is valid
    if (url.isEmpty) {
      return;
    }
    
    // Handle anchor links (e.g., #installation-instructions)
    if (url.startsWith('#')) {
      // Currently we don't support scrolling to anchors
      final anchorTab = TabModel(
        id: _uuid.v4(),
        url: '',
        title: 'Anchor Link',
        content: '''# Anchor Link

The link you clicked ($url) is an anchor link to a section within the current page.

**Note:** Vertext currently doesn't support scrolling to specific sections within a document.

In a future version, we plan to implement this feature.
''',
        isLoading: false,
      );
      
      setState(() {
        // Add tab to right column
        _browserState.rightColumn.tabs.add(anchorTab);
        _browserState.rightColumn.activeTabIndex = _browserState.rightColumn.tabs.length - 1;
      });
      return;
    }
    
    // Determine which column the link was clicked from
    final clickedFromActiveLeftTab = _browserState.leftColumn.activeTab != null &&
        _browserState.leftColumn.activeTabIndex != -1;
    final sourceColumn = clickedFromActiveLeftTab 
        ? _browserState.leftColumn 
        : _browserState.rightColumn;
    final targetColumn = clickedFromActiveLeftTab 
        ? _browserState.rightColumn 
        : _browserState.leftColumn;
    
    // Determine base URL for relative links
    String? baseUrl;
    if (sourceColumn.activeTab != null) {
      baseUrl = sourceColumn.activeTab!.url;
    }
    
    // Create a new tab for the link
    final newTab = TabModel(
      id: _uuid.v4(),
      url: url,
      title: title.isNotEmpty ? title : 'Loading...',
      isLoading: true,
    );
    
    setState(() {
      // Add tab to target column and make it active
      targetColumn.tabs.add(newTab);
      targetColumn.activeTabIndex = targetColumn.tabs.length - 1;
    });
    
    // Load content for the new tab
    _loadTabContent(newTab, url, baseUrl);
  }

  // Handle creating a new tab in a column
  void _handleNewTab(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    final newTab = column.createTab(
      url: _homeUrl,
      title: 'Home',
    );
    
    setState(() {
      column.activeTabIndex = column.tabs.length - 1;
    });
    
    _loadTabContent(newTab, _homeUrl, null);
  }
  
  // Handle selecting a tab
  void _handleSelectTab(bool inLeftColumn, int index) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    setState(() {
      column.activeTabIndex = index;
    });
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
  }
  
  // Handle reopening a closed tab
  void _handleReopenTab(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    setState(() {
      column.reopenClosedTab();
    });
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
  }
  
  // Handle refreshing the current tab
  void _handleRefresh(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    if (column.activeTab != null) {
      final tab = column.activeTab!;
      setState(() {
        tab.isLoading = true;
      });
      
      _loadTabContent(tab, tab.url, null);
    }
  }
  
  // Handle going back in tab history
  void _handleBack(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    if (column.activeTab != null && column.activeTab!.canGoBack()) {
      final tab = column.activeTab!;
      final previousUrl = tab.goBack();
      
      setState(() {
        tab.isLoading = true;
      });
      
      _loadTabContent(tab, previousUrl, null);
    }
  }
  
  // Handle going forward in tab history
  void _handleForward(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    if (column.activeTab != null && column.activeTab!.canGoForward()) {
      final tab = column.activeTab!;
      final nextUrl = tab.goForward();
      
      setState(() {
        tab.isLoading = true;
      });
      
      _loadTabContent(tab, nextUrl, null);
    }
  }
  
  // Handle going to the home page
  void _handleHome(bool inLeftColumn) {
    final column = inLeftColumn ? _browserState.leftColumn : _browserState.rightColumn;
    
    if (column.activeTab != null) {
      final tab = column.activeTab!;
      
      setState(() {
        tab.isLoading = true;
      });
      
      _loadTabContent(tab, _homeUrl, null);
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
            if (_browserState.leftColumn.activeTab != null)
              const SizedBox(width: 16),
            if (_browserState.leftColumn.activeTab != null)
              Expanded(
                child: Text(
                  '| ${_browserState.leftColumn.activeTab!.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        // Network status indicator
        bottom: _isInitializing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                ),
              )
            : null,
      ),
      body: Row(
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
              onLinkTap: _handleLinkTap,
              onRefresh: () => _handleRefresh(true),
              onHome: () => _handleHome(true),
              onBack: () => _handleBack(true),
              onForward: () => _handleForward(true),
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
              onLinkTap: _handleLinkTap,
              onRefresh: () => _handleRefresh(false),
              onHome: () => _handleHome(false),
              onBack: () => _handleBack(false),
              onForward: () => _handleForward(false),
            ),
          ),
        ],
      ),
    );
  }
}