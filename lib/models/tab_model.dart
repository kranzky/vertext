import 'dart:convert';

/// A model representing a browser tab in the Vertext application.
/// 
/// This stores all the data needed for a tab, including its content,
/// URL, title, and loading state.
class TabModel {
  /// Unique identifier for the tab
  final String id;
  
  /// The URL being displayed in this tab
  String url;
  
  /// The title of the tab (extracted from content or provided)
  String title;
  
  /// The markdown content of the tab
  String content;
  
  /// Whether this tab is currently loading content
  bool isLoading;
  
  /// Current scroll position in the document
  double scrollPosition;
  
  /// History of URLs visited in this tab
  final List<String> history;
  
  /// Current position in the history
  int historyIndex;
  
  /// Creates a new tab model.
  TabModel({
    required this.id,
    required this.url,
    this.title = 'Loading...',
    this.content = '',
    this.isLoading = true,
    this.scrollPosition = 0.0,
  }) : 
    history = [url],
    historyIndex = 0;
  
  /// Creates a TabModel from a JSON map.
  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      isLoading: false, // Always start non-loading when restoring
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
    )
    // Set history and historyIndex after constructor
    ..history.clear()
    ..history.addAll((json['history'] as List).cast<String>())
    ..historyIndex = json['historyIndex'] as int;
  }
  
  /// Converts this tab model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'content': content,
      'scrollPosition': scrollPosition,
      'history': history,
      'historyIndex': historyIndex,
    };
  }
  
  /// Navigates to a new URL, updating history.
  void navigateTo(String newUrl) {
    // Add to history and remove any forward history
    if (historyIndex < history.length - 1) {
      history.removeRange(historyIndex + 1, history.length);
    }
    
    // Add the new URL to history if it's different from the current one
    if (url != newUrl) {
      history.add(newUrl);
      historyIndex = history.length - 1;
    }
    
    url = newUrl;
    isLoading = true;
  }
  
  /// Updates tab content and metadata after loading.
  void updateContent({
    required String newContent,
    required String newTitle,
  }) {
    content = newContent;
    title = newTitle;
    isLoading = false;
  }
  
  /// Checks if this tab can navigate back in history.
  bool canGoBack() => historyIndex > 0;
  
  /// Checks if this tab can navigate forward in history.
  bool canGoForward() => historyIndex < history.length - 1;
  
  /// Navigate back in history.
  String goBack() {
    if (canGoBack()) {
      historyIndex--;
      url = history[historyIndex];
      isLoading = true;
      return url;
    }
    return url;
  }
  
  /// Navigate forward in history.
  String goForward() {
    if (canGoForward()) {
      historyIndex++;
      url = history[historyIndex];
      isLoading = true;
      return url;
    }
    return url;
  }
  
  @override
  String toString() {
    return 'TabModel{id: $id, url: $url, title: $title, historyIndex: $historyIndex, historyLength: ${history.length}}';
  }
}