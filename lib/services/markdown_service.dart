import 'package:http/http.dart' as http;
import 'dart:async';

/// Service for fetching markdown content from URLs.
class MarkdownService {
  /// Fetches markdown content from a URL.
  /// 
  /// Returns the markdown content as a string.
  /// Throws an exception if the fetch fails.
  Future<String> fetchMarkdown(String url) async {
    try {
      // Ensure the URL has a valid scheme
      Uri uri = Uri.parse(url);
      if (!uri.hasScheme) {
        // If no scheme, assume https
        uri = Uri.parse('https://$url');
      }

      print('Fetching markdown from: $uri');

      // Timeout after 10 seconds
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      
      if (response.statusCode == 200) {
        print('Successfully fetched content from $uri');
        return response.body;
      } else {
        print('Failed to fetch content: Status code ${response.statusCode}');
        return _getErrorMarkdown('Failed to load content', 
          'Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching content: $e');
      
      // Return a user-friendly error message based on the exception type
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection failed')) {
        return _getErrorMarkdown('Network Error', 
          '''Could not connect to $url
          
Possible causes:
- No internet connection
- The site may be down
- Network permissions may be needed

Technical details: $e''');
      } else if (e.toString().contains('TimeoutException')) {
        return _getErrorMarkdown('Request Timed Out', 
          'The request to $url took too long to complete.\n\nTechnical details: $e');
      } else {
        return _getErrorMarkdown('Error fetching content', e.toString());
      }
    }
  }

  /// Extracts a title from markdown content.
  /// 
  /// Looks for the first heading (# Title) in the markdown
  /// or returns a default title if none is found.
  String extractTitle(String markdown, String defaultTitle) {
    final headingRegex = RegExp(r'^#\s+(.+)$', multiLine: true);
    final match = headingRegex.firstMatch(markdown);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    
    return defaultTitle;
  }

  /// Creates markdown content for error display.
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
}