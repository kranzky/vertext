import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Result from fetching content, containing the content and metadata
class FetchResult {
  final String content;
  final bool isMarkdown;
  final String contentType;
  final String url;
  
  FetchResult({
    required this.content,
    required this.isMarkdown,
    required this.contentType,
    required this.url,
  });
}

/// Service for fetching markdown content from URLs.
class MarkdownService {
  
  /// Attempts to determine if content is markdown.
  bool isLikelyMarkdown(String content, String contentType, String url) {
    // First check the content type header
    if (contentType.isNotEmpty) {
      final lowerCaseType = contentType.toLowerCase();
      if (lowerCaseType.contains('markdown') || 
          lowerCaseType.contains('text/md') ||
          lowerCaseType.contains('text/x-markdown')) {
        return true;
      }
      
      // Common non-markdown content types
      if (lowerCaseType.contains('html') ||
          lowerCaseType.contains('pdf') ||
          lowerCaseType.contains('application/') ||
          lowerCaseType.contains('image/') ||
          lowerCaseType.contains('audio/') ||
          lowerCaseType.contains('video/')) {
        return false;
      }
    }
    
    // Check content for markdown indicators
    if (content.length > 100) {
      // Look for markdown headings
      if (RegExp(r'^#+ ').hasMatch(content)) return true;
      
      // Look for markdown links
      if (RegExp(r'\[.+\]\(.+\)').hasMatch(content)) return true;
      
      // Look for HTML tags (indicating likely HTML, not markdown)
      if (RegExp(r'<!DOCTYPE html>', caseSensitive: false).hasMatch(content) ||
          RegExp(r'<html', caseSensitive: false).hasMatch(content)) {
        return false;
      }
    }
    
    // Check URL for markdown file extension
    if (url.toLowerCase().endsWith('.md') || 
        url.toLowerCase().endsWith('.markdown')) {
      return true;
    }
    
    // Default to treating it as markdown if we can't determine
    return true;
  }

  /// Fetches content from a URL and determines if it's markdown.
  /// 
  /// Returns a FetchResult with the content and metadata.
  /// Throws an exception if the fetch fails.
  Future<FetchResult> fetchContent(String url) async {
    try {
      // Ensure the URL has a valid scheme
      Uri uri = Uri.parse(url);
      if (!uri.hasScheme) {
        // If no scheme, assume https
        uri = Uri.parse('https://$url');
      }

      print('Fetching content from: $uri');

      // Timeout after 10 seconds
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      
      if (response.statusCode == 200) {
        print('Successfully fetched content from $uri');
        
        // Extract content type from headers
        String contentType = '';
        if (response.headers.containsKey('content-type')) {
          contentType = response.headers['content-type'] ?? '';
        }
        
        // Determine if the content is likely markdown
        bool isMarkdown = isLikelyMarkdown(response.body, contentType, url);
        
        return FetchResult(
          content: response.body,
          isMarkdown: isMarkdown,
          contentType: contentType,
          url: url,
        );
      } else {
        print('Failed to fetch content: Status code ${response.statusCode}');
        return FetchResult(
          content: _getErrorMarkdown('Failed to load content', 
            'Server returned status code ${response.statusCode}'),
          isMarkdown: true, // Errors are displayed as markdown
          contentType: 'text/markdown',
          url: url,
        );
      }
    } catch (e) {
      print('Error fetching content: $e');
      
      String errorContent;
      // Return a user-friendly error message based on the exception type
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection failed')) {
        errorContent = _getErrorMarkdown('Network Error', 
          '''Could not connect to $url
          
Possible causes:
- No internet connection
- The site may be down
- Network permissions may be needed

Technical details: $e''');
      } else if (e.toString().contains('TimeoutException')) {
        errorContent = _getErrorMarkdown('Request Timed Out', 
          'The request to $url took too long to complete.\n\nTechnical details: $e');
      } else {
        errorContent = _getErrorMarkdown('Error fetching content', e.toString());
      }
      
      return FetchResult(
        content: errorContent,
        isMarkdown: true, // Errors are displayed as markdown
        contentType: 'text/markdown',
        url: url,
      );
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
  
  /// Legacy method for backward compatibility
  Future<String> fetchMarkdown(String url) async {
    try {
      final result = await fetchContent(url);
      return result.content;
    } catch (e) {
      return _getErrorMarkdown('Error fetching content', e.toString());
    }
  }
}