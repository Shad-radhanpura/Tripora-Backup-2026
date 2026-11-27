import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// One labelled line in the popup, for example ("Destination", "Goa").
typedef ImageDetailLine = (String label, String value);

/// Opens a larger view of a place or dish photo. The page underneath stays where
/// it is: closing the popup (×, Escape or tapping outside) returns to the same
/// scroll position and filters.
Future<void> showImageDetailDialog(
  BuildContext context, {
  required Widget image,
  required String title,
  List<ImageDetailLine> details = const [],
  String? footer,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    builder: (dialogContext) => Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.escape): _CloseIntent()},
      child: Actions(
        actions: {
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) {
              Navigator.pop(dialogContext);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Dialog(
            key: const Key('image-detail-dialog'),
            insetPadding: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(aspectRatio: 4 / 3, child: image),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          key: const Key('image-detail-close'),
                          tooltip: 'Close',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.55),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: dialogContext.palette.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          for (final (label, value) in details) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$label: $value',
                              style: TextStyle(color: dialogContext.palette.text, height: 1.4),
                            ),
                          ],
                          if (footer != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              footer,
                              style: TextStyle(color: dialogContext.palette.muted, fontSize: 11.5, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}
