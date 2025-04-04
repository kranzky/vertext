import 'package:flutter/material.dart';
import '../models/column_model.dart';
import '../models/tab_model.dart';
import 'tab_widget.dart';

/// A widget that displays a horizontal scrollable bar of tabs.
class TabBarWidget extends StatelessWidget {
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

  const TabBarWidget({
    super.key,
    required this.columnModel,
    required this.onNewTab,
    required this.onSelectTab,
    required this.onCloseTab,
    required this.onReopenTab,
    required this.onReorderTab,
    required this.onMoveToOtherColumn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Tabs area (scrollable)
          Expanded(
            child: columnModel.tabs.isEmpty
                ? Center(
                    child: Text(
                      'No tabs open',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: columnModel.tabs.length,
                    itemBuilder: (context, index) {
                      final tab = columnModel.tabs[index];
                      final isActive = index == columnModel.activeTabIndex;
                      
                      return TabWidget(
                        key: ValueKey(tab.id),
                        tab: tab,
                        isActive: isActive,
                        onTap: () => onSelectTab(index),
                        onClose: () => onCloseTab(index),
                        onAcceptDrag: (details) {
                          final draggedTab = details.data;
                          final draggedTabIndex = columnModel.tabs.indexWhere(
                            (t) => t.id == draggedTab.id
                          );
                          
                          if (draggedTabIndex != -1 && draggedTabIndex != index) {
                            onReorderTab(draggedTabIndex, index);
                          }
                        },
                      );
                    },
                  ),
          ),
          
          // Tab actions
          Row(
            children: [
              // New tab button
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'New Tab',
                onPressed: onNewTab,
                visualDensity: VisualDensity.compact,
              ),
              
              // Reopen closed tab button
              IconButton(
                icon: const Icon(Icons.restore, size: 18),
                tooltip: 'Reopen Closed Tab',
                onPressed: columnModel.canReopenTab ? onReopenTab : null,
                visualDensity: VisualDensity.compact,
              ),
              
              // Move selected tab to other column button
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 18),
                tooltip: 'Move Tab to Other Column',
                onPressed: columnModel.activeTab != null
                    ? () => onMoveToOtherColumn(columnModel.activeTab!)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}