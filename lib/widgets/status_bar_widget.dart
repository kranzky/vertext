import 'package:flutter/material.dart';

/// A widget that displays a status bar at the bottom of the browser column.
/// Shows the current tab's URL or the URL of a hovered link.
class StatusBarWidget extends StatelessWidget {
  /// The URL of the current tab
  final String currentUrl;
  
  /// The URL of the link being hovered over
  final String? hoveredUrl;
  
  /// Whether the widget should show content
  final bool isVisible;

  const StatusBarWidget({
    super.key, 
    required this.currentUrl,
    this.hoveredUrl,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which URL to display
    final String displayUrl = hoveredUrl ?? currentUrl;
    
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      alignment: Alignment.centerLeft,
      child: isVisible
          ? Text(
              displayUrl,
              style: TextStyle(
                fontSize: 12,
                color: hoveredUrl != null 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink(),
    );
  }
}