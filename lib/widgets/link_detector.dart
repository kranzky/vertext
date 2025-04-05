import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// A widget that wraps the GptMarkdown to detect when the user hovers over links
class LinkDetector extends StatefulWidget {
  /// The markdown content
  final String markdown;
  
  /// Callback when a link is tapped
  final void Function(String url, String title) onLinkTap;
  
  /// Callback when a link is hovered
  final void Function(String? url) onHover;

  const LinkDetector({
    super.key,
    required this.markdown,
    required this.onLinkTap,
    required this.onHover,
  });

  @override
  State<LinkDetector> createState() => _LinkDetectorState();
}

class _LinkDetectorState extends State<LinkDetector> {
  String? _hoveredLink;
  
  /// Checks if a URL likely points to a markdown document
  bool isLikelyMarkdownLink(String url) {
    final lowerUrl = url.toLowerCase();
    // Check if it ends with .md or .markdown extension
    if (lowerUrl.endsWith('.md') || lowerUrl.endsWith('.markdown')) {
      return true;
    }
    
    try {
      // Check if domain contains 'mmm' subdomain
      final uri = Uri.parse(url);
      if (uri.host.startsWith('mmm.')) {
        return true;
      }
    } catch (e) {
      // If URL parsing fails, don't crash
      debugPrint('Error parsing URL: $e');
    }
    
    return false;
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
                // Use purple for markdown links, blue for external links
                color: isLikelyMarkdownLink(url) 
                  ? (_hoveredLink == url ? Colors.purple.shade700 : Colors.purple.shade500)
                  : (_hoveredLink == url ? Colors.blue.shade700 : Colors.blue.shade500),
                decoration: _hoveredLink == url ? TextDecoration.underline : TextDecoration.none,
                // Make markdown links slightly more prominent
                fontWeight: isLikelyMarkdownLink(url) ? FontWeight.w500 : null,
              ),
            ),
          ),
        );
      },
    );
  }
}