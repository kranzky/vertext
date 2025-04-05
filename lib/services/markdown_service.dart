import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

/// Service for fetching markdown content from URLs and local files.
class MarkdownService {
  // Cache of asset paths to avoid redundant lookups
  final Map<String, String> _assetPathCache = {};
  
  // Application documents directory path - initialized on first use
  String? _appDocumentsPath;
  String? _appBundlePath;
  
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

  /// Check if a URL is a special protocol
  bool isSpecialProtocol(String url) {
    return url.startsWith('about:') || url.startsWith('vertext:');
  }
  
  /// Handle special protocol URLs like about:markdown
  Future<FetchResult> handleSpecialProtocol(String url) async {
    if (url.startsWith('about:markdown')) {
      return loadAssetMarkdown('about_markdown.md');
    } else if (url == 'about:blank') {
      return FetchResult(
        content: '# Blank Page',
        isMarkdown: true,
        contentType: 'text/markdown',
        url: url,
      );
    } else if (url.startsWith('vertext:')) {
      // Custom protocol for app-specific pages
      final pageName = url.replaceFirst('vertext:', '');
      try {
        return loadAssetMarkdown('$pageName.md');
      } catch (e) {
        return FetchResult(
          content: _getErrorMarkdown('Page Not Found', 'The vertext: page "$pageName" does not exist.'),
          isMarkdown: true,
          contentType: 'text/markdown',
          url: url,
        );
      }
    }
    
    // Default error for unknown special protocols
    return FetchResult(
      content: _getErrorMarkdown('Unsupported Protocol', 'The protocol in "$url" is not supported.'),
      isMarkdown: true,
      contentType: 'text/markdown',
      url: url,
    );
  }
  
  /// Load markdown from application assets
  Future<FetchResult> loadAssetMarkdown(String assetName) async {
    try {
      // If not a full asset path, prepend the markdown directory
      if (!assetName.startsWith('assets/')) {
        assetName = 'assets/markdown/$assetName';
      }
      
      debugPrint('Loading asset: $assetName');
      final content = await rootBundle.loadString(assetName);
      
      return FetchResult(
        content: content,
        isMarkdown: true,
        contentType: 'text/markdown',
        url: 'asset://$assetName',
      );
    } catch (e) {
      debugPrint('Error loading asset $assetName: $e');
      return FetchResult(
        content: _getErrorMarkdown('Asset Not Found', 'Could not load the asset: $assetName\n\nError: $e'),
        isMarkdown: true,
        contentType: 'text/markdown',
        url: 'asset://$assetName',
      );
    }
  }
  
  /// Initialize app paths for file resolution
  Future<void> _initPaths() async {
    if (_appDocumentsPath == null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        _appDocumentsPath = directory.path;
        
        // Get the application's bundle path which contains the assets
        // This is different depending on platform
        if (Platform.isIOS || Platform.isMacOS) {
          final directory = await getApplicationSupportDirectory();
          _appBundlePath = directory.path;
        } else if (Platform.isAndroid) {
          final directory = await getExternalStorageDirectory();
          _appBundlePath = directory?.path;
        } else {
          // For other platforms, use the application documents directory as a fallback
          _appBundlePath = _appDocumentsPath;
        }
        
        debugPrint('Initialized app paths: documents=$_appDocumentsPath, bundle=$_appBundlePath');
      } catch (e) {
        debugPrint('Error initializing app paths: $e');
        // Fallback to a reasonable default
        _appDocumentsPath = '.';
        _appBundlePath = '.';
      }
    }
  }
  
  /// Resolve a relative path to an absolute path
  Future<String> resolveRelativePath(String relativePath) async {
    await _initPaths();
    
    // Try different base directories to find the file
    final potentialPaths = [
      // Application documents directory
      if (_appDocumentsPath != null) 
        path.join(_appDocumentsPath!, relativePath),
      
      // Application bundle directory
      if (_appBundlePath != null) 
        path.join(_appBundlePath!, relativePath),
      
      // Current working directory (fallback)
      path.join(Directory.current.path, relativePath),
    ];
    
    for (final potentialPath in potentialPaths) {
      if (await File(potentialPath).exists()) {
        debugPrint('Resolved relative path "$relativePath" to "$potentialPath"');
        return potentialPath;
      }
    }
    
    // If file not found, return the first path as a default
    return potentialPaths.first;
  }
  
  /// Load markdown from a local file
  Future<FetchResult> loadLocalFile(String filePath) async {
    try {
      // Normalize the file path
      filePath = filePath.replaceFirst('file://', '');
      
      // Handle relative paths
      if (!path.isAbsolute(filePath)) {
        filePath = await resolveRelativePath(filePath);
      }
      
      final file = File(filePath);
      
      // Check if file exists before attempting to read it
      if (!await file.exists()) {
        return FetchResult(
          content: _getErrorMarkdown('File Not Found', 'The file does not exist: $filePath'),
          isMarkdown: true,
          contentType: 'text/markdown',
          url: 'file://$filePath',
        );
      }

      // Try to access the file
      try {
        final content = await file.readAsString();
        
        // Determine content type based on extension
        String contentType = 'text/plain';
        if (filePath.toLowerCase().endsWith('.md') || filePath.toLowerCase().endsWith('.markdown')) {
          contentType = 'text/markdown';
        }
        
        return FetchResult(
          content: content,
          isMarkdown: isLikelyMarkdown(content, contentType, filePath),
          contentType: contentType,
          url: 'file://$filePath',
        );
      } on FileSystemException catch (e) {
        // Handle specific permission errors
        if (e.osError?.errorCode == 1 || // Operation not permitted
            e.osError?.errorCode == 13 || // Permission denied
            e.toString().contains('Permission denied') ||
            e.toString().contains('Operation not permitted')) {
          
          String errorMessage = '''## File Permission Error

Unable to read the file due to permission restrictions. On macOS, the application needs explicit permission to access files outside of its container.

### How to Fix This:

1. Try using a system dialog to select the file instead of entering the path directly
2. Save the file to your Documents folder, which is typically accessible
3. Use the File > Open dialog in the system menu

### Technical Details:
Path: $filePath
Error: ${e.message}
''';

          return FetchResult(
            content: _getErrorMarkdown('Permission Denied', errorMessage),
            isMarkdown: true,
            contentType: 'text/markdown',
            url: 'file://$filePath',
          );
        } else {
          // Other file system errors
          return FetchResult(
            content: _getErrorMarkdown('File System Error', 
              'Could not read file: $filePath\n\nError: $e'),
            isMarkdown: true,
            contentType: 'text/markdown',
            url: 'file://$filePath',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading local file: $e');
      return FetchResult(
        content: _getErrorMarkdown('Error Loading File', 'Could not load file: $filePath\n\nError: $e'),
        isMarkdown: true,
        contentType: 'text/markdown',
        url: 'file://$filePath',
      );
    }
  }

  /// Fetches content from a URL or local file and determines if it's markdown.
  /// 
  /// Returns a FetchResult with the content and metadata.
  /// Throws an exception if the fetch fails.
  Future<FetchResult> fetchContent(String url, [String? baseUrl]) async {
    try {
      // First check for special protocols
      if (isSpecialProtocol(url)) {
        return handleSpecialProtocol(url);
      }
      
      // Check for local file paths
      if (url.startsWith('file://') || 
          (!url.contains('://') && !url.startsWith('http') && url.contains('.'))) {
        return loadLocalFile(url);
      }
      
      // Handle asset URLs (asset://path/to/file.md)
      if (url.startsWith('asset://')) {
        final assetPath = url.replaceFirst('asset://', '');
        return loadAssetMarkdown(assetPath);
      }
      
      // Handle URLs that are just filenames with no protocol or path - assume they're local assets
      if (!url.contains('/') && !url.contains('://') && 
          (url.endsWith('.md') || url.endsWith('.markdown'))) {
        return loadAssetMarkdown(url);
      }
      
      // Check if it's just a scheme with an anchor and nothing else
      if (url.contains('://') && url.split('://')[1].startsWith('#')) {
        throw FormatException('URL contains only a scheme and an anchor, no host');
      }
      
      // Handle relative URLs
      Uri? uri;
      
      // Handle different URL types
      try {
        if (url.contains('://')) {
          // Already an absolute URL
          uri = Uri.parse(url);
        } else if (url.startsWith('/')) {
          // Absolute path but relative to domain
          if (baseUrl != null) {
            final baseUri = Uri.parse(baseUrl);
            uri = baseUri.replace(path: url);
          } else {
            throw FormatException('Cannot resolve absolute path without a base URL');
          }
        } else if (baseUrl != null) {
          // Relative path with a base URL
          final baseUri = Uri.parse(baseUrl);
          
          // If baseUrl is a file URL, join the paths
          if (baseUrl.startsWith('file://')) {
            final basePath = baseUrl.replaceFirst('file://', '');
            final dirName = path.dirname(basePath);
            final joinedPath = path.join(dirName, url);
            return loadLocalFile(joinedPath);
          }
          
          // For now, assume mmm.kranzky.com since that's our specific domain
          // In a more general solution, we'd extract this from the baseUrl
          uri = Uri(
            scheme: 'https',
            host: 'mmm.kranzky.com',
            path: url
          );
          
          debugPrint('Resolved relative URL: $url to $uri');
        } else {
          // No base URL provided, treat as absolute
          uri = Uri.parse(url);
          if (!uri.hasScheme) {
            uri = Uri.parse('https://$url');
          }
        }
      } catch (e) {
        debugPrint('Error resolving URL: $e');
        uri = Uri.parse('https://$url');
      }
      
      // Additional check for empty host but with scheme
      if (uri.host.isEmpty) {
        throw FormatException('No host specified in URI $url');
      }

      debugPrint('Fetching content from: $uri');

      // Timeout after 10 seconds
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );
      
      if (response.statusCode == 200) {
        debugPrint('Successfully fetched content from $uri');
        
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
          url: uri.toString(),
        );
      } else {
        debugPrint('Failed to fetch content: Status code ${response.statusCode}');
        return FetchResult(
          content: _getErrorMarkdown('Failed to load content', 
            'Server returned status code ${response.statusCode}'),
          isMarkdown: true, // Errors are displayed as markdown
          contentType: 'text/markdown',
          url: uri.toString(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching content: $e');
      
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
      
      // Try to determine a URL to return even in case of error
      String resolvedUrl = url;
      try {
        if (baseUrl != null && !url.contains('://') && !url.startsWith('/')) {
          // Similar hardcoded approach as above for consistency
          resolvedUrl = Uri(
            scheme: 'https',
            host: 'mmm.kranzky.com',
            path: url
          ).toString();
        }
      } catch (urlError) {
        // Just use the original URL if we can't resolve it
        debugPrint('Error resolving URL in error handler: $urlError');
      }
      
      return FetchResult(
        content: errorContent,
        isMarkdown: true, // Errors are displayed as markdown
        contentType: 'text/markdown',
        url: resolvedUrl,
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