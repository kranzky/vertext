import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../services/markdown_service.dart';

/// Enum to categorize different types of links
enum LinkType {
  /// Links to markdown documents (.md, .markdown, mmm.*)
  markdown,
  
  /// Links to non-markdown external resources
  external,
  
  /// Anchor links to sections within the same document (#section)
  anchor,
}

/// A widget that wraps the GptMarkdown to detect when the user hovers over links
class LinkDetector extends StatefulWidget {
  /// The markdown content
  final String markdown;
  
  /// Callback when a link is tapped
  final void Function(String url, String title) onLinkTap;
  
  /// Callback when a link is hovered
  final void Function(String? url) onHover;
  
  /// Function to check if an anchor link is valid (if null, all anchor links are assumed valid)
  final bool Function(String anchorLink)? isValidAnchorLink;
  
  /// The current URL for resolving relative references
  final String? baseUrl;

  const LinkDetector({
    super.key,
    required this.markdown,
    required this.onLinkTap,
    required this.onHover,
    this.isValidAnchorLink,
    this.baseUrl,
  });

  @override
  State<LinkDetector> createState() => _LinkDetectorState();
}

class _LinkDetectorState extends State<LinkDetector> {
  String? _hoveredLink;
  final MarkdownService _markdownService = MarkdownService();
  
  /// Identifies the type of link
  LinkType identifyLinkType(String url) {
    // Check for anchor links first
    if (url.startsWith('#')) {
      return LinkType.anchor;
    }
    
    final lowerUrl = url.toLowerCase();
    // Check if it ends with .md or .markdown extension
    if (lowerUrl.endsWith('.md') || lowerUrl.endsWith('.markdown')) {
      return LinkType.markdown;
    }
    
    // Relative paths without extensions might still be markdown files
    if (!url.contains('/') && !url.contains('://') && !url.contains('.') && !url.startsWith('http')) {
      // Simple names without extensions are treated as possible markdown links
      return LinkType.markdown;
    }
    
    try {
      if (url.contains('://')) {
        // Check if domain contains 'mmm' subdomain
        final uri = Uri.parse(url);
        if (uri.host.startsWith('mmm.')) {
          return LinkType.markdown;
        }
      } else if (url.startsWith('www.') && url.contains('mmm.')) {
        // www.mmm.domain.com links
        return LinkType.markdown;
      }
    } catch (e) {
      // If URL parsing fails, don't crash
    }
    
    return LinkType.external;
  }
  
  /// Process markdown to resolve relative image URLs
  String processMarkdownImages(String markdown) {
    if (widget.baseUrl == null) {
      return markdown; // No base URL to resolve against
    }
    
    // Regular expression to find image references in markdown
    // Handles both standard format: ![alt text](image-url)
    // And dimensions format: ![50x50 alt text](image-url)
    final imageRegex = RegExp(r'!\[(?:(\d+)x(\d+)\s+)?(.*?)\]\((.*?)\)', multiLine: true);
    
    return markdown.replaceAllMapped(imageRegex, (match) {
      final width = match.group(1);
      final height = match.group(2);
      final altText = match.group(3) ?? '';
      final imageUrl = match.group(4) ?? '';
      
      // Skip if the image URL is already absolute
      if (imageUrl.startsWith('http://') || 
          imageUrl.startsWith('https://') || 
          imageUrl.startsWith('file://') || 
          imageUrl.startsWith('asset://') ||
          imageUrl.startsWith('data:')) {
        return match.group(0)!;
      }
      
      // For relative URLs, resolve them using the same logic as links
      String resolvedUrl = _resolveRelativeUrl(imageUrl, widget.baseUrl!);
      
      // Reconstruct the image markdown with dimensions if provided
      if (width != null && height != null) {
        return '![$width x$height $altText]($resolvedUrl)';
      } else {
        return '![$altText]($resolvedUrl)';
      }
    });
  }
  
  /// Resolve a relative URL against a base URL
  String _resolveRelativeUrl(String relativeUrl, String baseUrl) {
    // Skip anchor links
    if (relativeUrl.startsWith('#')) {
      return relativeUrl;
    }
    
    try {
      // Handle different base URL types
      if (baseUrl.startsWith('asset://')) {
        // Asset-relative paths
        final assetPath = baseUrl.replaceFirst('asset://', '');
        final dirPath = assetPath.contains('/') 
            ? assetPath.substring(0, assetPath.lastIndexOf('/'))
            : '';
        
        if (relativeUrl.startsWith('/')) {
          // Absolute path relative to asset root
          return 'asset://${relativeUrl.substring(1)}';
        } else {
          // Relative to current asset directory
          // Handle ../ path traversal by normalizing the path
          List<String> segments = [...dirPath.split('/'), ...relativeUrl.split('/')];
          List<String> normalized = [];
          
          for (var segment in segments) {
            if (segment == '..' && normalized.isNotEmpty) {
              normalized.removeLast(); // Go up one directory
            } else if (segment != '' && segment != '.') {
              normalized.add(segment);
            }
          }
          
          final normalizedPath = normalized.join('/');
          
          return 'asset://$normalizedPath';
        }
      } else if (baseUrl.startsWith('file://')) {
        // File-relative paths
        final filePath = baseUrl.replaceFirst('file://', '');
        final dirPath = filePath.contains('/') 
            ? filePath.substring(0, filePath.lastIndexOf('/'))
            : '';
        
        if (relativeUrl.startsWith('/')) {
          // Absolute path relative to file system root
          return 'file://$relativeUrl';
        } else {
          // Relative to current directory
          // Handle ../ path traversal by normalizing the path
          List<String> segments = [...dirPath.split('/'), ...relativeUrl.split('/')];
          List<String> normalized = [];
          
          for (var segment in segments) {
            if (segment == '..' && normalized.isNotEmpty) {
              normalized.removeLast(); // Go up one directory
            } else if (segment != '' && segment != '.') {
              normalized.add(segment);
            }
          }
          
          final normalizedPath = normalized.join('/');
          
          return 'file://$normalizedPath';
        }
      } else if (baseUrl.startsWith('http://') || baseUrl.startsWith('https://')) {
        // Web-relative paths
        final baseUri = Uri.parse(baseUrl);
        
        // Determine if the base URL refers to a file or directory
        final String path = baseUri.path;
        final lastSegment = path.contains('/') ? path.split('/').last : '';
        final isFile = lastSegment.contains('.') && !lastSegment.isEmpty;
        
        Uri resolvedUri;
        if (relativeUrl.startsWith('/')) {
          // Absolute path relative to domain root
          resolvedUri = baseUri.replace(path: relativeUrl);
        } else if (isFile) {
          // Base URL is a file, resolve against its directory
          final lastSlash = path.lastIndexOf('/');
          final directory = lastSlash > 0 ? path.substring(0, lastSlash + 1) : '/';
          resolvedUri = baseUri.replace(path: '$directory$relativeUrl');
        } else {
          // Base URL is a directory
          final directory = path.endsWith('/') ? path : '$path/';
          resolvedUri = baseUri.replace(path: '$directory$relativeUrl');
        }
        
        return resolvedUri.toString();
      }
    } catch (e) {
      // In case of any errors, just return the original URL as a fallback
      return relativeUrl;
    }
    
    // If we couldn't resolve it, return the original URL
    return relativeUrl;
  }
  
  /// Checks if a URL likely points to a markdown document (legacy method)
  bool isLikelyMarkdownLink(String url) {
    return identifyLinkType(url) == LinkType.markdown;
  }
  
  /// Get the appropriate color for a link based on its type
  Color _getLinkColor(String url) {
    final isHovered = _hoveredLink == url;
    
    switch (identifyLinkType(url)) {
      case LinkType.markdown:
        // Blue for markdown links
        return isHovered ? Colors.blue.shade700 : Colors.blue.shade500;
        
      case LinkType.external:
        // Red for external links
        return isHovered ? Colors.red.shade700 : Colors.red.shade500;
        
      case LinkType.anchor:
        // For anchor links, first check if it's valid
        if (widget.isValidAnchorLink != null) {
          final isValid = widget.isValidAnchorLink!(url);
          if (!isValid) {
            // Grey for invalid anchor links
            return isHovered ? Colors.grey.shade600 : Colors.grey.shade400;
          }
        }
        // Light blue for valid anchor links
        return isHovered ? Colors.lightBlue.shade400 : Colors.lightBlue.shade300;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Process markdown to resolve relative image URLs
    final processedMarkdown = processMarkdownImages(widget.markdown);
    
    return GptMarkdown(
      processedMarkdown,
      onLinkTab: widget.onLinkTap,
      linkBuilder: (context, text, url, style) {
        // Let's go back to the basics but with a custom baseline setting
        return TextButton(
          onPressed: () => widget.onLinkTap(url, text),
          style: TextButton.styleFrom(
            // Essential for proper text alignment
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            // No shape decorations
            shape: const RoundedRectangleBorder(),
            // Match surrounding text alignment
            alignment: Alignment.centerLeft,
            // Crucial for proper baseline alignment:
            visualDensity: VisualDensity.compact,
            // Disable all hover and splash effects
            foregroundColor: _getLinkColor(url),
            // No overlap with text
            backgroundColor: Colors.transparent,
          ),
          // Use MouseRegion to handle hover state
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() {
                _hoveredLink = url;
              });
              widget.onHover(url);
            },
            onExit: (_) {
              setState(() {
                _hoveredLink = null;
              });
              widget.onHover(null);
            },
            // Use Transform to explicitly move text down by 2 pixels
            child: Transform.translate(
              offset: const Offset(0, 2.0),
              child: Text(
                text,
                // Use the original style with minimal changes
                style: style.copyWith(
                  color: _getLinkColor(url),
                  fontWeight: identifyLinkType(url) == LinkType.markdown ? FontWeight.w500 : style.fontWeight,
                  decoration: _hoveredLink == url ? TextDecoration.underline : TextDecoration.none,
                  // Keep decoration below text
                  decorationThickness: 1.0, 
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}