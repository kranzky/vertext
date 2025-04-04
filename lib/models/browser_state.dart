import 'column_model.dart';
import 'tab_model.dart';

/// The state model for the entire browser.
/// 
/// This manages the two columns of tabs and provides methods for navigating
/// between them.
class BrowserState {
  /// The left column of tabs
  final ColumnModel leftColumn;
  
  /// The right column of tabs
  final ColumnModel rightColumn;
  
  /// Default homepage URL
  final String homeUrl;
  
  /// Creates a new browser state.
  BrowserState({
    required this.homeUrl,
    TabModel? initialLeftTab,
  }) : 
    leftColumn = ColumnModel(initialTab: initialLeftTab),
    rightColumn = ColumnModel();
  
  /// Creates a BrowserState from JSON data.
  factory BrowserState.fromJson(Map<String, dynamic> json) {
    return BrowserState(
      homeUrl: json['homeUrl'] as String,
    )
    // Replace the default columns with the ones from JSON
    ..leftColumn.tabs.clear()
    ..rightColumn.tabs.clear()
    ..leftColumn.activeTabIndex = -1
    ..rightColumn.activeTabIndex = -1
    // Then reconstruct from JSON
    .._reconstructLeftColumn(json['leftColumn'] as Map<String, dynamic>)
    .._reconstructRightColumn(json['rightColumn'] as Map<String, dynamic>);
  }
  
  /// Helper method to reconstruct the left column from JSON.
  BrowserState _reconstructLeftColumn(Map<String, dynamic> json) {
    // Replace the left column with the one from JSON
    if (json.containsKey('tabs') && (json['tabs'] as List).isNotEmpty) {
      final columnJson = ColumnModel.fromJson(json);
      leftColumn.tabs.addAll(columnJson.tabs);
      leftColumn.activeTabIndex = columnJson.activeTabIndex;
    }
    return this;
  }
  
  /// Helper method to reconstruct the right column from JSON.
  BrowserState _reconstructRightColumn(Map<String, dynamic> json) {
    // Replace the right column with the one from JSON
    if (json.containsKey('tabs') && (json['tabs'] as List).isNotEmpty) {
      final columnJson = ColumnModel.fromJson(json);
      rightColumn.tabs.addAll(columnJson.tabs);
      rightColumn.activeTabIndex = columnJson.activeTabIndex;
    }
    return this;
  }
  
  /// Converts this browser state to JSON.
  Map<String, dynamic> toJson() {
    return {
      'homeUrl': homeUrl,
      'leftColumn': leftColumn.toJson(),
      'rightColumn': rightColumn.toJson(),
    };
  }
  
  /// Opens a new tab in the right column.
  TabModel openInRightColumn({
    required String url,
    required String title,
  }) {
    return rightColumn.createTab(
      url: url,
      title: title,
    );
  }
  
  /// Opens a new tab in the left column.
  TabModel openInLeftColumn({
    required String url,
    required String title,
  }) {
    return leftColumn.createTab(
      url: url,
      title: title,
    );
  }
  
  /// Opens a home tab in the left column if it has no tabs.
  TabModel? ensureLeftColumnHasTab() {
    if (leftColumn.tabs.isEmpty) {
      return leftColumn.createTab(
        url: homeUrl,
        title: 'Home',
      );
    }
    return null;
  }
  
  /// Moves a tab from one column to the other.
  void moveTabBetweenColumns(
    bool fromLeft, // true if moving from left to right
    int tabIndex,
  ) {
    final sourceColumn = fromLeft ? leftColumn : rightColumn;
    final targetColumn = fromLeft ? rightColumn : leftColumn;
    
    if (tabIndex >= 0 && tabIndex < sourceColumn.tabs.length) {
      final tab = sourceColumn.tabs[tabIndex];
      
      // Remove from source column
      sourceColumn.tabs.removeAt(tabIndex);
      if (sourceColumn.activeTabIndex >= tabIndex) {
        if (sourceColumn.activeTabIndex > 0) {
          sourceColumn.activeTabIndex--;
        } else if (sourceColumn.tabs.isEmpty) {
          sourceColumn.activeTabIndex = -1;
        }
      }
      
      // Add to target column
      targetColumn.tabs.add(tab);
      targetColumn.activeTabIndex = targetColumn.tabs.length - 1;
      
      // If left column is now empty, create a new home tab
      if (leftColumn.tabs.isEmpty) {
        ensureLeftColumnHasTab();
      }
    }
  }
}