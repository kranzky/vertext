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
  }) : 
    history = [url],
    historyIndex = 0;
  
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
}