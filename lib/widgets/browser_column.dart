import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../models/column_model.dart';
import '../models/tab_model.dart';
import 'tab_bar_widget.dart';

/// A widget that displays a full browser column, including tabs and content.
class BrowserColumn extends StatelessWidget {
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
  
  /// Callback when the refresh button is clicked
  final VoidCallback? onRefresh;
  
  /// Callback when the home button is clicked
  final VoidCallback? onHome;
  
  /// Callback when the back button is clicked
  final VoidCallback? onBack;
  
  /// Callback when the forward button is clicked
  final VoidCallback? onForward;

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
    this.onRefresh,
    this.onHome,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        TabBarWidget(
          columnModel: columnModel,
          onNewTab: onNewTab,
          onSelectTab: onSelectTab,
          onCloseTab: onCloseTab,
          onReopenTab: onReopenTab,
          onReorderTab: onReorderTab,
          onMoveToOtherColumn: onMoveToOtherColumn,
        ),
        
        // Navigation toolbar
        if (columnModel.activeTab != null)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  tooltip: 'Back',
                  onPressed: columnModel.activeTab?.canGoBack() == true ? onBack : null,
                  visualDensity: VisualDensity.compact,
                ),
                
                // Forward button
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  tooltip: 'Forward',
                  onPressed: columnModel.activeTab?.canGoForward() == true ? onForward : null,
                  visualDensity: VisualDensity.compact,
                ),
                
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  visualDensity: VisualDensity.compact,
                ),
                
                // Home button
                IconButton(
                  icon: const Icon(Icons.home, size: 18),
                  tooltip: 'Home',
                  onPressed: onHome,
                  visualDensity: VisualDensity.compact,
                ),
                
                // URL display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      columnModel.activeTab?.url ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
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
            child: columnModel.activeTab == null
                ? Center(
                    child: Text(
                      'No tab selected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : columnModel.activeTab!.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: GptMarkdown(
                            columnModel.activeTab!.content,
                            onLinkTab: onLinkTap,
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}