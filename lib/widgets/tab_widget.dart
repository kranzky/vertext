import 'package:flutter/material.dart';
import '../models/tab_model.dart';

/// A widget that represents a single browser tab.
class TabWidget extends StatelessWidget {
  /// The tab data to display
  final TabModel tab;
  
  /// Whether this tab is currently active
  final bool isActive;
  
  /// Callback when the tab is selected
  final VoidCallback onTap;
  
  /// Callback when the tab close button is pressed
  final VoidCallback onClose;
  
  /// Callback when the tab is dragged to a new position
  final void Function(DragTargetDetails<TabModel>) onAcceptDrag;

  const TabWidget({
    super.key,
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onAcceptDrag,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<TabModel>(
      onAccept: (data) => onAcceptDrag(DragTargetDetails<TabModel>(
        data: data,
        offset: Offset.zero,
      )),
      builder: (context, candidateData, rejectedData) {
        // Show a highlight when a tab is being dragged over this one
        final bool isTargeted = candidateData.isNotEmpty;
        
        return LongPressDraggable<TabModel>(
          data: tab,
          feedback: Material(
            elevation: 4.0,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.description_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tab.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 200,
              minWidth: 100,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 2.0,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            margin: const EdgeInsets.only(right: 2.0),
            child: Material(
              color: isTargeted
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                  topRight: Radius.circular(4.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(Icons.description_outlined, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tab.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: isActive
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: isActive
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}