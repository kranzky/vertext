import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../models/column_model.dart';
import '../models/tab_model.dart';
import 'tab_bar_widget.dart';
import 'status_bar_widget.dart';
import 'link_detector.dart';

/// A widget that displays a full browser column, including tabs and content.
class BrowserColumn extends StatefulWidget {
  /// The column model containing tabs to display
  final ColumnModel columnModel;
  
  /// Callback when a new tab should be created
  final VoidCallback onNewTab;
  
  /// Callback when a tab is selected
  final void Function(int index) onSelectTab;
  
  /// Callback when a tab is closed
  final void Function(int index) onCloseTab;
  
  /// Callback when the most recently closed tab should be reopened
  final VoidCallback onReopenTab;
  
  /// Callback when a tab is dragged to a new position
  final void Function(int oldIndex, int newIndex) onReorderTab;
  
  /// Callback when a tab is dragged to the other column
  final void Function(TabModel tab) onMoveToOtherColumn;
  
  /// Callback when a link is clicked in the content
  final void Function(String url, String title) onLinkTap;
  
  /// Callback when a link is hovered over
  final void Function(String? url, bool isLeft)? onLinkHover;
  
  /// Key for the status bar widget
  final Key? statusBarKey;
  
  /// Whether this is the left column
  final bool isLeft;

  const BrowserColumn({
    super.key,
    required this.columnModel,
    required this.onNewTab,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onReopenTab,
    required this.onReorderTab,
    required this.onMoveToOtherColumn,
    required this.onLinkTap,
    this.onLinkHover,
    this.statusBarKey,
    this.isLeft = true,
  });

  @override
  State<BrowserColumn> createState() => _BrowserColumnState();
}

class _BrowserColumnState extends State<BrowserColumn> {
  // Track the URL currently being hovered
  String? _hoveredUrl;
  
  // Map to store individual scroll controllers for each tab
  final Map<String, ScrollController> _scrollControllers = {};
  
  // Map to store heading element positions for anchor links
  final Map<String, Map<String, double>> _headingPositions = {};
  
  // Set to store invalid anchor links that don't match any headings
  final Map<String, Set<String>> _invalidAnchors = {};

  @override
  void dispose() {
    // Dispose of all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    super.dispose();
  }

  // Get or create scroll controller for a specific tab
  ScrollController _getScrollController(TabModel tab) {
    if (!_scrollControllers.containsKey(tab.id)) {
      // Create a new controller with the saved position
      _scrollControllers[tab.id] = ScrollController(
        initialScrollOffset: tab.scrollPosition,
      );
      
      // Add listener to track scroll changes
      _scrollControllers[tab.id]!.addListener(() {
        // Save position when scrolling
        if (_scrollControllers[tab.id]!.hasClients) {
          final position = _scrollControllers[tab.id]!.position.pixels;
          tab.scrollPosition = position;
          debugPrint('Saved position $position for tab ${tab.id}');
        }
      });
      
      debugPrint('Created scroll controller for tab ${tab.id} with initial position ${tab.scrollPosition}');
    }
    
    return _scrollControllers[tab.id]!;
  }
  
  // Extract headings and their positions from the markdown content
  void _extractHeadingPositions(TabModel tab) {
    if (!_headingPositions.containsKey(tab.id)) {
      _headingPositions[tab.id] = {};
    }
    
    // Clear existing positions to avoid duplicates
    _headingPositions[tab.id]!.clear();
    
    // Use a regular expression to find all headings in the content
    final headingRegex = RegExp(r'^(#{1,6})\s+(.+?)(?:\s+\{#([a-zA-Z0-9_-]+)\})?$', multiLine: true);
    final matches = headingRegex.allMatches(tab.content);
    
    // Store the heading positions
    for (final match in matches) {
      final headingText = match.group(2)!.trim();
      
      // Check if the heading has an explicit ID like {#custom-id}
      String? explicitId = match.group(3);
      
      // Generate standard ID from heading text
      final standardId = _generateAnchorId(headingText);
      
      // Generate short ID by taking the first word only
      final shortId = headingText.split(' ').first.toLowerCase();
      
      // Calculate position
      final position = tab.content.substring(0, match.start).split('\n').length * 20.0;
      
      // Store with standard generated ID
      _headingPositions[tab.id]![standardId] = position;
      debugPrint('Added standard heading ID #$standardId for "$headingText"');
      
      // If there's an explicit ID, add that too
      if (explicitId != null) {
        _headingPositions[tab.id]![explicitId] = position;
        debugPrint('Added explicit heading ID #$explicitId for "$headingText"');
      }
      
      // Add short one-word ID
      _headingPositions[tab.id]![shortId] = position;
      debugPrint('Added short heading ID #$shortId for "$headingText"');
      
      // Also try adding ID without plural (for cases like "Headers" -> "header")
      if (shortId.endsWith('s')) {
        final singularId = shortId.substring(0, shortId.length - 1);
        _headingPositions[tab.id]![singularId] = position;
        debugPrint('Added singular heading ID #$singularId for "$headingText"');
      }
    }
    
    // Add support for special case mappings in the document you provided
    _addSpecialCaseMappings(tab.id);
  }
  
  // Add special case mappings for common markdown documentation
  void _addSpecialCaseMappings(String tabId) {
    // Map of special case IDs to their likely heading text
    final specialCases = {
      'p': 'paragraphs',
      'html': 'inline html',
      'autoescape': 'automatic escaping',
      'blockquote': 'blockquotes',
      'list': 'lists',
      'precode': 'code blocks',
      'hr': 'horizontal rules',
      'link': 'links',
      'em': 'emphasis',
      'img': 'images',
      'backslash': 'backslash escapes',
      'autolink': 'automatic links',
    };
    
    // For each special case, try to find a matching heading position
    for (final entry in specialCases.entries) {
      final specialId = entry.key;
      final possibleHeadings = [
        entry.value,
        entry.value.replaceAll(' ', '-'),
        entry.value.split(' ').first,
      ];
      
      // Try to find a match
      for (final possibleHeading in possibleHeadings) {
        if (_headingPositions[tabId]!.containsKey(possibleHeading)) {
          final position = _headingPositions[tabId]![possibleHeading]!;
          _headingPositions[tabId]![specialId] = position;
          debugPrint('Added special case mapping #$specialId -> #$possibleHeading');
          break;
        }
      }
    }
  }
  
  // Convert a heading text to an anchor ID
  String _generateAnchorId(String headingText) {
    // Convert to lowercase
    var id = headingText.toLowerCase();
    // Replace spaces with dashes
    id = id.replaceAll(RegExp(r'\s+'), '-');
    // Remove special characters
    id = id.replaceAll(RegExp(r'[^\w\-]'), '');
    return id;
  }
  
  // Handle anchor link navigation
  bool _scrollToAnchor(TabModel tab, String anchor) {
    // Remove the # from the anchor
    final anchorId = anchor.substring(1);
    final controller = _getScrollController(tab);
    
    // Ensure we have extracted heading positions
    if (!_headingPositions.containsKey(tab.id)) {
      _extractHeadingPositions(tab);
    }
    
    // Initialize invalid anchors set if needed
    if (!_invalidAnchors.containsKey(tab.id)) {
      _invalidAnchors[tab.id] = {};
    }
    
    // Find the position for this anchor
    final position = _headingPositions[tab.id]?[anchorId];
    
    if (position != null && controller.hasClients) {
      // Animate scroll to the position
      controller.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      debugPrint('Scrolling to anchor #$anchorId at position $position');
      
      // This is a valid anchor
      _invalidAnchors[tab.id]!.remove(anchor);
      return true;
    } else {
      // This is an invalid anchor that doesn't correspond to any heading
      _invalidAnchors[tab.id]!.add(anchor);
      debugPrint('Could not find anchor #$anchorId');
      return false;
    }
  }
  
  // Check if an anchor link is valid (has a corresponding heading)
  bool isValidAnchorLink(String anchor) {
    final activeTab = widget.columnModel.activeTab;
    if (activeTab == null) return false;
    
    // Initialize tracking structures if needed
    if (!_headingPositions.containsKey(activeTab.id)) {
      _extractHeadingPositions(activeTab);
    }
    
    if (!_invalidAnchors.containsKey(activeTab.id)) {
      _invalidAnchors[activeTab.id] = {};
    }
    
    // If we've already identified this as invalid, return false
    if (_invalidAnchors[activeTab.id]!.contains(anchor)) {
      return false;
    }
    
    // Check if the anchor exists in the heading positions map
    final anchorId = anchor.substring(1);
    return _headingPositions[activeTab.id]?.containsKey(anchorId) ?? false;
  }
  
  // Handle link clicks including anchor links
  void _handleLinkTap(String url, String title) {
    // Check if this is an anchor link
    if (url.startsWith('#')) {
      final activeTab = widget.columnModel.activeTab;
      if (activeTab != null) {
        _scrollToAnchor(activeTab, url);
      }
      return;
    }
    
    // Otherwise pass to the parent for normal link handling
    widget.onLinkTap(url, title);
  }

  // Handle hover over links in markdown content
  void _handleLinkHover(String? url) {
    setState(() {
      _hoveredUrl = url;
    });
    
    if (widget.onLinkHover != null) {
      widget.onLinkHover!(url, widget.isLeft);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Determine current active tab
    final activeTab = widget.columnModel.activeTab;
    
    return Column(
      children: [
        // Tab bar
        TabBarWidget(
          columnModel: widget.columnModel,
          onNewTab: widget.onNewTab,
          onSelectTab: widget.onSelectTab,
          onCloseTab: widget.onCloseTab,
          onReopenTab: widget.onReopenTab,
          onReorderTab: widget.onReorderTab,
          onMoveToOtherColumn: widget.onMoveToOtherColumn,
        ),
        
        // Content area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: activeTab == null
                ? Center(
                    child: Text(
                      'No tab selected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : activeTab.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          key: ValueKey('scroll_${activeTab.id}'),
                          controller: _getScrollController(activeTab),
                          child: SelectionArea(
                            child: LinkDetector(
                              key: ValueKey(activeTab.id),
                              markdown: activeTab.content,
                              onLinkTap: _handleLinkTap, // Use our local handler first
                              onHover: _handleLinkHover,
                              isValidAnchorLink: isValidAnchorLink, // Validate anchor links
                            ),
                          ),
                        ),
                      ),
          ),
        ),
        
        // Status bar showing URL
        StatusBarWidget(
          key: widget.statusBarKey,
          currentUrl: widget.columnModel.activeTab?.url ?? '',
          hoveredUrl: _hoveredUrl,
          isVisible: widget.columnModel.activeTab != null,
        ),
      ],
    );
  }
}