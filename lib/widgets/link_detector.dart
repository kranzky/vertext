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
  final FocusNode _focusNode = FocusNode();
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We'll use GptMarkdown's linkBuilder feature to provide a custom link
    // widget that can detect hover events and update the status bar
    
    return Focus(
      focusNode: _focusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onExit: (_) {
          setState(() {
            _hoveredLink = null;
          });
          widget.onHover(null);
        },
        child: GptMarkdown(
          widget.markdown,
          onLinkTab: widget.onLinkTap,
          // Custom link builder that captures hover events
          linkBuilder: (context, text, url, style) {
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (_hoveredLink != url) {
                  setState(() {
                    _hoveredLink = url;
                  });
                  widget.onHover(url);
                }
              },
              onExit: (_) {
                if (_hoveredLink == url) {
                  setState(() {
                    _hoveredLink = null;
                  });
                  widget.onHover(null);
                }
              },
              child: GestureDetector(
                onTap: () => widget.onLinkTap(url, text),
                child: Text(
                  text,
                  style: style.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}