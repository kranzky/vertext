import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'dart:ui' as ui;

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
  Map<String, String> _linkMap = {};
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _extractLinks();
  }
  
  @override
  void didUpdateWidget(LinkDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _extractLinks();
    }
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  /// Extract links from the markdown content
  void _extractLinks() {
    _linkMap = {};
    
    // Use a simple regex to extract markdown links
    final RegExp regex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final matches = regex.allMatches(widget.markdown);
    
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final linkText = match.group(1);
        final linkUrl = match.group(2);
        if (linkText != null && linkUrl != null) {
          _linkMap[linkText] = linkUrl;
        }
      }
    }
    
    // Only for debugging - show the extracted links
    debugPrint('Extracted ${_linkMap.length} links:');
    _linkMap.forEach((text, url) {
      debugPrint('  "$text" -> $url');
    });
  }
  
  /// Show the URL in the status bar when hovered
  void _showUrlInStatus(String? text) {
    final url = text != null ? _linkMap[text] : null;
    if (_hoveredLink != url) {
      setState(() {
        _hoveredLink = url;
      });
      widget.onHover(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The simplest approach - let the GptMarkdown handle the links
    // and we'll figure out the hovering elsewhere
    return Focus(
      focusNode: _focusNode,
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onExit: (_) {
          _showUrlInStatus(null);
        },
        child: GptMarkdown(
          widget.markdown,
          onLinkTab: widget.onLinkTap,
        ),
      ),
    );
  }
}