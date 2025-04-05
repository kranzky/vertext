import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

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

  const LinkDetector({
    super.key,
    required this.markdown,
    required this.onLinkTap,
    required this.onHover,
    this.isValidAnchorLink,
  });

  @override
  State<LinkDetector> createState() => _LinkDetectorState();
}

class _LinkDetectorState extends State<LinkDetector> {
  String? _hoveredLink;
  
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
      debugPrint('Error parsing URL: $e');
    }
    
    return LinkType.external;
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
    return GptMarkdown(
      widget.markdown,
      onLinkTab: widget.onLinkTap,
      linkBuilder: (context, text, url, style) {
        // Create a TextButton for links - this handles cursor changes correctly
        return TextButton(
          onPressed: () => widget.onLinkTap(url, text),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const RoundedRectangleBorder(),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click, // Explicitly set cursor to pointer
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
            child: Text(
              text,
              style: style.copyWith(
                // Style based on link type
                color: _getLinkColor(url),
                decoration: _hoveredLink == url ? TextDecoration.underline : TextDecoration.none,
                // Make markdown links slightly more prominent
                fontWeight: identifyLinkType(url) == LinkType.markdown ? FontWeight.w500 : null,
              ),
            ),
          ),
        );
      },
    );
  }
}