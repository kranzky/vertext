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
                              onLinkTap: widget.onLinkTap,
                              onHover: _handleLinkHover,
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