import 'package:uuid/uuid.dart';
import 'tab_model.dart';

/// A model representing a column of tabs in the Vertext browser.
/// 
/// This manages a collection of tabs and keeps track of which tab is active.
class ColumnModel {
  /// List of tabs in this column
  final List<TabModel> tabs;
  
  /// Index of the currently active tab
  int activeTabIndex;
  
  /// Stack of recently closed tabs for reopening
  final List<TabModel> _closedTabs;
  
  /// Maximum number of closed tabs to remember
  static const int maxClosedTabs = 10;
  
  /// UUID generator for tab IDs
  final Uuid _uuid = const Uuid();
  
  /// Creates a new column with an optional initial tab.
  ColumnModel({TabModel? initialTab})
      : tabs = initialTab != null ? [initialTab] : [],
        activeTabIndex = initialTab != null ? 0 : -1,
        _closedTabs = [];
  
  /// Creates a new tab and adds it to this column.
  TabModel createTab({
    required String url,
    String title = 'Loading...',
    String content = '',
    bool isLoading = true,
    bool setActive = true,
  }) {
    final tab = TabModel(
      id: _uuid.v4(),
      url: url,
      title: title,
      content: content,
      isLoading: isLoading,
    );
    
    tabs.add(tab);
    
    if (setActive || activeTabIndex == -1) {
      activeTabIndex = tabs.length - 1;
    }
    
    return tab;
  }
  
  /// Returns the currently active tab, or null if there are no tabs.
  TabModel? get activeTab {
    if (activeTabIndex >= 0 && activeTabIndex < tabs.length) {
      return tabs[activeTabIndex];
    }
    return null;
  }
  
  /// Sets the active tab by index.
  void setActiveTab(int index) {
    if (index >= 0 && index < tabs.length) {
      activeTabIndex = index;
    }
  }
  
  /// Sets the active tab by ID.
  void setActiveTabById(String id) {
    final index = tabs.indexWhere((tab) => tab.id == id);
    if (index != -1) {
      activeTabIndex = index;
    }
  }
  
  /// Closes a tab by index.
  TabModel? closeTab(int index) {
    if (index >= 0 && index < tabs.length) {
      final closedTab = tabs.removeAt(index);
      
      // Add to closed tabs stack
      _closedTabs.add(closedTab);
      if (_closedTabs.length > maxClosedTabs) {
        _closedTabs.removeAt(0);
      }
      
      // Update active tab index if needed
      if (tabs.isEmpty) {
        activeTabIndex = -1;
      } else if (index <= activeTabIndex) {
        activeTabIndex = (activeTabIndex > 0) ? activeTabIndex - 1 : 0;
      }
      
      return closedTab;
    }
    return null;
  }
  
  /// Closes the active tab.
  TabModel? closeActiveTab() {
    if (activeTabIndex >= 0) {
      return closeTab(activeTabIndex);
    }
    return null;
  }
  
  /// Reopens the most recently closed tab.
  TabModel? reopenClosedTab() {
    if (_closedTabs.isNotEmpty) {
      final tab = _closedTabs.removeLast();
      tabs.add(tab);
      activeTabIndex = tabs.length - 1;
      return tab;
    }
    return null;
  }
  
  /// Moves a tab from one index to another.
  void moveTab(int fromIndex, int toIndex) {
    if (fromIndex >= 0 && fromIndex < tabs.length &&
        toIndex >= 0 && toIndex < tabs.length && fromIndex != toIndex) {
      final tab = tabs.removeAt(fromIndex);
      tabs.insert(toIndex, tab);
      
      // Update active tab index if necessary
      if (activeTabIndex == fromIndex) {
        activeTabIndex = toIndex;
      } else if (activeTabIndex > fromIndex && activeTabIndex <= toIndex) {
        activeTabIndex--;
      } else if (activeTabIndex < fromIndex && activeTabIndex >= toIndex) {
        activeTabIndex++;
      }
    }
  }
  
  /// Returns true if there is at least one tab that can be closed.
  bool get canCloseTab => tabs.isNotEmpty;
  
  /// Returns true if there is at least one closed tab that can be reopened.
  bool get canReopenTab => _closedTabs.isNotEmpty;
}