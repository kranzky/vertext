import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html' hide File, Platform;
// Only import JS on web platforms
import 'stub_js.dart' if (dart.library.js) 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

// Web file stub for conditional imports
import 'stub_file.dart' if (dart.library.io) 'dart:io';

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
      
      final content = await rootBundle.loadString(assetName);
      
      return FetchResult(
        content: content,
        isMarkdown: true,
        contentType: 'text/markdown',
        url: 'asset://$assetName',
      );
    } catch (e) {
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
        if (kIsWeb) {
          // Web doesn't support file system paths in the same way
          _appDocumentsPath = '.';
          _appBundlePath = '.';
          return;
        }
        
        final directory = await getApplicationDocumentsDirectory();
        _appDocumentsPath = directory.path;
        
        // Get the application's bundle path which contains the assets
        // This is different depending on platform
        if (defaultTargetPlatform == TargetPlatform.iOS || 
            defaultTargetPlatform == TargetPlatform.macOS) {
          final directory = await getApplicationSupportDirectory();
          _appBundlePath = directory.path;
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          final directory = await getExternalStorageDirectory();
          _appBundlePath = directory?.path;
        } else {
          // For other platforms, use the application documents directory as a fallback
          _appBundlePath = _appDocumentsPath;
        }
        
      } catch (e) {
        // Fallback to a reasonable default
        _appDocumentsPath = '.';
        _appBundlePath = '.';
      }
    }
  }
  
  /// Resolve a relative path to an absolute path
  Future<String> resolveRelativePath(String relativePath) async {
    // For web platform, just return the relative path as-is
    if (kIsWeb) {
      return relativePath;
    }
    
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
    
    // On non-web platforms, check if files exist
    if (!kIsWeb) {
      for (final potentialPath in potentialPaths) {
        if (await File(potentialPath).exists()) {
          return potentialPath;
        }
      }
    }
    
    // If file not found, return the first path as a default
    return potentialPaths.isNotEmpty ? potentialPaths.first : relativePath;
  }
  
  /// Load markdown from a local file
  Future<FetchResult> loadLocalFile(String filePath) async {
    // Web platform cannot access local files through File API
    if (kIsWeb) {
      return FetchResult(
        content: _getErrorMarkdown('File Access Not Supported', 
          'Direct file access is not supported in web browsers due to security restrictions. Please use the file picker dialog instead.'),
        isMarkdown: true,
        contentType: 'text/markdown',
        url: 'file://$filePath',
      );
    }
    
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
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('Operation not permitted')) {
          
          String errorMessage = '''## File Permission Error

Unable to read the file due to permission restrictions. On macOS, the application needs explicit permission to access files outside of its container.

### How to Fix This:

1. Try using a system dialog to select the file instead of entering the path directly
2. Save the file to your Documents folder, which is typically accessible
3. Use the File > Open dialog in the system menu

### Technical Details:
Path: $filePath
Error: ${e.toString()}
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
      
      // Check for full web URLs that include hostname
      if (url.startsWith('http://') || url.startsWith('https://')) {
        var uri = Uri.parse(url);
        
        // Track if we're using a CORS proxy
        bool corsUsingProxy = false;
        String corsOriginalUrl = url;
        
        // For web platform, check if we need to use the CORS proxy
        if (kIsWeb) {
          // Use JavaScript interop to check if CORS proxy is needed
          final js.JsObject? corsProxy = js.context.hasProperty('FLUTTER_CORS_PROXY') 
              ? js.JsObject.fromBrowserObject(js.context['FLUTTER_CORS_PROXY']) 
              : null;
              
          if (corsProxy != null) {
            // Check if the URL needs a proxy (forced for mmm.kranzky.com)
            final bool needsProxy = uri.host == 'mmm.kranzky.com' || 
                corsProxy.callMethod('isCorsNeeded', [url]) as bool;
                
            if (needsProxy) {
              final String proxyUrl = corsProxy.callMethod('getProxyUrl', [url]) as String;
              uri = Uri.parse(proxyUrl);
              corsUsingProxy = true;
            }
          }
        }
        
        // Fetch content from web
        final response = await http.get(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Request timed out after 10 seconds');
          },
        );
        
        if (response.statusCode == 200) {
          
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
            // When using a CORS proxy, return the original URL, not the proxy URL
            url: corsUsingProxy ? corsOriginalUrl : uri.toString(),
          );
        } else {
          // If using a CORS proxy and it failed, try another proxy
          if (corsUsingProxy && kIsWeb) {
            // Get another proxy - directly call getProxyUrl again, as it will cycle to next proxy
            final js.JsObject? corsProxy = js.context.hasProperty('FLUTTER_CORS_PROXY') 
                ? js.JsObject.fromBrowserObject(js.context['FLUTTER_CORS_PROXY']) 
                : null;
                
            // Retry for both server errors (5xx) and client errors (4xx) like 403
            // since different CORS proxies may have different restrictions
            if (corsProxy != null && (response.statusCode >= 400)) {
              // Try all available proxies
              int retryCount = 0;
              int maxRetries = 3; // Try up to 3 more proxies
              
              while (retryCount < maxRetries) {
                try {
                  retryCount++;
                  
                  // Try another proxy
                  final String proxyUrl = corsProxy.callMethod('getProxyUrl', [corsOriginalUrl]) as String;
                  final retryUri = Uri.parse(proxyUrl);
                  
                  // Try with this proxy
                  final retryResponse = await http.get(retryUri).timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      throw TimeoutException('Request timed out after 10 seconds');
                    },
                  );
                  
                  // If successful, return the results
                  if (retryResponse.statusCode == 200) {
                    String contentType = '';
                    if (retryResponse.headers.containsKey('content-type')) {
                      contentType = retryResponse.headers['content-type'] ?? '';
                    }
                    
                    bool isMarkdown = isLikelyMarkdown(retryResponse.body, contentType, corsOriginalUrl);
                    
                    return FetchResult(
                      content: retryResponse.body,
                      isMarkdown: isMarkdown,
                      contentType: contentType,
                      url: corsOriginalUrl, // Use original URL, not proxy URL
                    );
                  }
                  
                  // Continue retrying only if we get an error response 
                  // (both 4xx and 5xx errors might be proxy-specific)
                  if (retryResponse.statusCode < 400) {
                    // If successful, don't try other proxies
                    break;
                  }
                } catch (e) {
                  // Error with this proxy, continue to next one
                }
              }
            }
          }
          
          return FetchResult(
            content: _getErrorMarkdown('Failed to load content', 
              'Server returned status code ${response.statusCode}'),
            isMarkdown: true,
            contentType: 'text/markdown',
            url: corsUsingProxy ? corsOriginalUrl : uri.toString(),
          );
        }
      }
      
      // Check for local file paths
      if (url.startsWith('file://')) {
        return loadLocalFile(url);
      }
      
      // Handle asset URLs (asset://path/to/file.md)
      if (url.startsWith('asset://')) {
        final assetPath = url.replaceFirst('asset://', '');
        return loadAssetMarkdown(assetPath);
      }
      
      // Handle relative paths based on baseUrl context
      if (baseUrl != null) {
        // 1. Handle asset-relative paths
        if (baseUrl.startsWith('asset://')) {
          if (!url.contains('://') && !url.startsWith('http')) {
            // Handle as relative to current asset
            final assetPath = baseUrl.replaceFirst('asset://', '');
            final dirName = path.dirname(assetPath);
            final joinedPath = path.join(dirName, url);
            return loadAssetMarkdown(joinedPath);
          }
        }
        
        // 2. Handle file-relative paths
        if (baseUrl.startsWith('file://')) {
          if (!url.contains('://') && !url.startsWith('http')) {
            // Handle as relative to current file
            final basePath = baseUrl.replaceFirst('file://', '');
            final dirName = path.dirname(basePath);
            final joinedPath = path.join(dirName, url);
            return loadLocalFile(joinedPath);
          }
        }
        
        // 3. Handle web-relative paths for http/https
        if (baseUrl.startsWith('http')) {
          if (!url.contains('://') && !url.startsWith('http')) {
            try {
              // If baseUrl contains a CORS proxy, extract the actual URL
              var actualBaseUrl = baseUrl;
              
              // Check for common CORS proxy patterns
              if (kIsWeb) {
                // Detect allorigins proxy
                if (baseUrl.contains('api.allorigins.win/raw?url=')) {
                  actualBaseUrl = Uri.decodeComponent(baseUrl.split('api.allorigins.win/raw?url=')[1]);
                }
                // Detect alternative CORS proxies
                else if (baseUrl.contains('cors.bridged.cc/')) {
                  actualBaseUrl = baseUrl.split('cors.bridged.cc/')[1];
                }
                else if (baseUrl.contains('corsproxy.org/?')) {
                  actualBaseUrl = Uri.decodeComponent(baseUrl.split('corsproxy.org/?')[1]);
                }
                // Detect corsproxy.io proxy
                else if (baseUrl.contains('corsproxy.io/?')) {
                  actualBaseUrl = Uri.decodeComponent(baseUrl.split('corsproxy.io/?')[1]);
                }
              }
              
              final baseUri = Uri.parse(actualBaseUrl);
              Uri resolvedUri;
              
              if (url.startsWith('/')) {
                // Absolute path relative to domain root
                resolvedUri = baseUri.replace(path: url);
              } else {
                // Check if the base URL ends with a filename pattern
                final baseFilename = baseUri.path.split('/').last;
                final hasFileExtension = baseFilename.contains('.') && 
                    !baseFilename.endsWith('/');
                
                if (hasFileExtension) {
                  // Base URL appears to be a file, use its directory as base
                  final baseDir = path.dirname(baseUri.path);
                  final normBaseDir = baseDir == '.' ? '' : baseDir;
                  final prefix = normBaseDir.endsWith('/') ? normBaseDir : '$normBaseDir/';
                  final suffix = url.startsWith('./') ? url.substring(2) : url;
                  
                  // Join paths properly
                  String joinedPath = '$prefix$suffix';
                  // Clean up any double slashes
                  joinedPath = joinedPath.replaceAll('//', '/');
                  // Ensure path starts with slash if not empty
                  if (joinedPath.isNotEmpty && !joinedPath.startsWith('/')) {
                    joinedPath = '/$joinedPath';
                  }
                  
                  resolvedUri = baseUri.replace(path: joinedPath);
                } else {
                  // Base URL is likely a directory, try to resolve directly
                  String basePath = baseUri.path;
                  if (!basePath.endsWith('/') && basePath.isNotEmpty) {
                    basePath = '$basePath/';
                  }
                  
                  final suffix = url.startsWith('./') ? url.substring(2) : url;
                  String joinedPath = '$basePath$suffix';
                  joinedPath = joinedPath.replaceAll('//', '/');
                  
                  resolvedUri = baseUri.replace(path: joinedPath);
                }
              }
              
              // After resolving the URL, fetch the content
              var finalUri = resolvedUri;
              
              // Track if we're using a proxy
              bool corsUsingProxy = false;
              String corsOriginalUrl = resolvedUri.toString();
              
              // Store the original host for CORS check
              final originalHost = resolvedUri.host;
              
              // For web platform, check if we need to use the CORS proxy
              if (kIsWeb) {
                final js.JsObject? corsProxy = js.context.hasProperty('FLUTTER_CORS_PROXY') 
                    ? js.JsObject.fromBrowserObject(js.context['FLUTTER_CORS_PROXY']) 
                    : null;
                    
                if (corsProxy != null) {
                  // Check if this is the same host that needed CORS proxy in the base URL
                  // This ensures we use the proxy when loading relative links from domains that need it
                  final bool needsProxy = originalHost == 'mmm.kranzky.com' || 
                      corsProxy.callMethod('isCorsNeeded', [resolvedUri.toString()]) as bool;
                  
                  if (needsProxy) {
                    final String proxyUrl = corsProxy.callMethod('getProxyUrl', [resolvedUri.toString()]) as String;
                    finalUri = Uri.parse(proxyUrl);
                    corsUsingProxy = true;
                  }
                }
              }
              
              final response = await http.get(finalUri).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Request timed out after 10 seconds');
                },
              );
              
              if (response.statusCode == 200) {
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
                  // Use original URL for relative link resolution, not the proxy URL
                  url: corsUsingProxy ? corsOriginalUrl : resolvedUri.toString(),
                );
              } else {
                return FetchResult(
                  content: _getErrorMarkdown('Failed to load content', 
                    'Server returned status code ${response.statusCode}'),
                  isMarkdown: true,
                  contentType: 'text/markdown',
                  url: corsUsingProxy ? corsOriginalUrl : resolvedUri.toString(),
                );
              }
            } catch (e) {
              // Fall back to simpler URL joining strategy on error
              try {
                final baseUri = Uri.parse(baseUrl);
                final host = baseUri.host;
                final scheme = baseUri.scheme;
                
                // Try to determine if base URL refers to a file or directory
                final String basePath = baseUri.path;
                String resolvedUrl;
                
                // Inspect the path to see if it ends with what looks like a file
                final segments = basePath.split('/');
                final lastSegment = segments.isNotEmpty ? segments.last : '';
                final isFile = lastSegment.contains('.') && !lastSegment.isEmpty;
                
                if (isFile) {
                  // If base URL looks like a file, resolve to its directory
                  final int lastSlash = basePath.lastIndexOf('/');
                  final String directory = lastSlash > 0 ? basePath.substring(0, lastSlash + 1) : '/';
                  resolvedUrl = '$scheme://$host$directory$url';
                } else {
                  // If base URL looks like a directory
                  final String directory = basePath.endsWith('/') ? basePath : '$basePath/';
                  resolvedUrl = '$scheme://$host$directory$url';
                }
                
                // As a last resort, try relative to root
                if (resolvedUrl.contains('//') && !resolvedUrl.contains('://')) {
                  resolvedUrl = '$scheme://$host/$url';
                }
                
                // Start a new fetch with the resolved URL but no base URL to avoid loops
                return fetchContent(resolvedUrl);
              } catch (fallbackError) {
                  throw e; // Throw original error if fallback fails
              }
            }
          }
        }
      }
      
      // Handle simple markdown filenames without directory context  
      if (!url.contains('/') && !url.contains('://') && !url.startsWith('http') &&
          (url.endsWith('.md') || url.endsWith('.markdown'))) {
        
        
        // Check if we have an http baseUrl - if so, treat as web relative path
        if (baseUrl != null && baseUrl.startsWith('http')) {
          try {
            final baseUri = Uri.parse(baseUrl);
            // Construct URL relative to the host root
            final resolvedUri = baseUri.replace(path: url);
            
            // Fetch the content from the web
            var finalUri = resolvedUri;
            
            // For web platform, check if we need to use the CORS proxy
            if (kIsWeb) {
              final js.JsObject? corsProxy = js.context.hasProperty('FLUTTER_CORS_PROXY') 
                  ? js.JsObject.fromBrowserObject(js.context['FLUTTER_CORS_PROXY']) 
                  : null;
                  
              if (corsProxy != null) {
                final bool needsProxy = corsProxy.callMethod('isCorsNeeded', [resolvedUri.toString()]) as bool;
                if (needsProxy) {
                  final String proxyUrl = corsProxy.callMethod('getProxyUrl', [resolvedUri.toString()]) as String;
                  finalUri = Uri.parse(proxyUrl);
                }
              }
            }
            
            final response = await http.get(finalUri).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Request timed out after 10 seconds');
              },
            );
            
            if (response.statusCode == 200) {
              String contentType = response.headers['content-type'] ?? '';
              return FetchResult(
                content: response.body,
                isMarkdown: isLikelyMarkdown(response.body, contentType, url),
                contentType: contentType,
                url: resolvedUri.toString(),
              );
            } else {
              return FetchResult(
                content: _getErrorMarkdown('Failed to load content', 
                  'Server returned status code ${response.statusCode}'),
                isMarkdown: true,
                contentType: 'text/markdown',
                url: resolvedUri.toString(),
              );
            }
          } catch (e) {
            // Fall back to trying as an asset
          }
        }
        
        // No http base context or web loading failed, assume it's a root-level asset
        return loadAssetMarkdown(url);
      }
      // Check for non-URL file paths with extensions that might be local files
      if (!url.contains('://') && !url.startsWith('http') && url.contains('.')) {
        return loadLocalFile(url);
      }
      
      // Check if it's just a scheme with an anchor and nothing else
      if (url.contains('://') && url.split('://')[1].startsWith('#')) {
        throw FormatException('URL contains only a scheme and an anchor, no host');
      }
      
      // At this point, we're dealing with a full URL or something we'll treat as one
      Uri uri;
      
      try {
        // Handle absolute URLs directly
        if (url.contains('://')) {
          uri = Uri.parse(url);
        } else {
          // No scheme - add https:// if needed
          if (url.startsWith('www.') || url.contains('.')) {
            uri = Uri.parse('https://$url');
          } else {
            throw FormatException('Cannot determine URL format for: $url');
          }
        }
        
        // Check for valid host
        if (uri.host.isEmpty) {
          throw FormatException('No host specified in URI $url');
        }
        
        
        // For web platform, check if we need to use the CORS proxy
        var finalUri = uri;
        if (kIsWeb) {
          final js.JsObject? corsProxy = js.context.hasProperty('FLUTTER_CORS_PROXY') 
              ? js.JsObject.fromBrowserObject(js.context['FLUTTER_CORS_PROXY']) 
              : null;
              
          if (corsProxy != null) {
            final bool needsProxy = corsProxy.callMethod('isCorsNeeded', [uri.toString()]) as bool;
            if (needsProxy) {
              final String proxyUrl = corsProxy.callMethod('getProxyUrl', [uri.toString()]) as String;
              finalUri = Uri.parse(proxyUrl);
            }
          }
        }
        
        // Timeout after 10 seconds
        final response = await http.get(finalUri).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Request timed out after 10 seconds');
          },
        );
        
        if (response.statusCode == 200) {
          
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
          return FetchResult(
            content: _getErrorMarkdown('Failed to load content', 
              'Server returned status code ${response.statusCode}'),
            isMarkdown: true, // Errors are displayed as markdown
            contentType: 'text/markdown',
            url: uri.toString(),
          );
        }
      } catch (e) {
        throw e;  // Re-throw to be caught by the outer catch block
      }
    } catch (e) {
      
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
      } else if (kIsWeb && url.startsWith('http') && 
          (e.toString().contains('CORS') || e.toString().contains('Cross-Origin'))) {
        // Special handling for CORS errors on web
        errorContent = _getErrorMarkdown('CORS Error', 
          '''Unable to access $url due to browser security restrictions (CORS).
          
This is a limitation of web browsers that prevents accessing content from a different domain.
          
Technical details: $e''');
      } else {
        errorContent = _getErrorMarkdown('Error fetching content', e.toString());
      }
      
      // Try to determine a URL to return even in case of error
      String resolvedUrl = url;
      try {
        if (baseUrl != null && !url.contains('://') && !url.startsWith('/')) {
          if (baseUrl.startsWith('http')) {
            final baseUri = Uri.parse(baseUrl);
            
            // Determine if the base URL looks like a file or directory
            final basePath = baseUri.path;
            final segments = basePath.split('/');
            final lastSegment = segments.isNotEmpty ? segments.last : '';
            final isFile = lastSegment.contains('.') && !lastSegment.isEmpty;
            
            if (isFile) {
              // If base looks like a file, resolve against its directory
              final lastSlash = basePath.lastIndexOf('/');
              final directory = lastSlash > 0 ? basePath.substring(0, lastSlash + 1) : '/';
              resolvedUrl = baseUri.replace(path: '$directory$url').toString();
            } else {
              // If base looks like a directory
              final directory = basePath.endsWith('/') ? basePath : '$basePath/';
              resolvedUrl = baseUri.replace(path: '$directory$url').toString();
            }
          } else if (baseUrl.startsWith('asset://')) {
            resolvedUrl = 'asset://${path.join(path.dirname(baseUrl.replaceFirst('asset://', '')), url)}';
          } else if (baseUrl.startsWith('file://')) {
            resolvedUrl = 'file://${path.join(path.dirname(baseUrl.replaceFirst('file://', '')), url)}';
          }
        }
      } catch (urlError) {
        // Just use the original URL if we can't resolve it
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