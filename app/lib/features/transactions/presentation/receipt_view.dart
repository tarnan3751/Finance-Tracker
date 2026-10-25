/// A transaction's receipt photo: the editor's section (the thumbnail with Replace and
/// Remove, "Take photo" and "Choose photo" while there is none, "Receipt kept on another
/// device" when the photo is not on this device) and the full-screen view a tap on the
/// thumbnail opens, zoomable, through a pageless push (no route of its own). The photos
/// are bytes in memory: a replaced photo keeps its path, so no file image cache can show
/// the old one. The bytes become an image through [receiptImageProvider], which the
/// goldens override.
library;

import 'dart:typed_data';

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receipt_view.g.dart';

/// How a receipt photo's bytes become an image: decoded from memory. Image decoding and
/// resizing are platform code whose pixels differ between machines, so the goldens
/// override this with an image the test draws itself.
@Riverpod(keepAlive: true)
ImageProvider Function(Uint8List bytes) receiptImage(Ref ref) =>
    MemoryImage.new;

/// The receipt section's content for the editor: [bytes] when there is a photo to show,
/// else [missing] when the transaction names a receipt this device does not have, else
/// the buttons to add one.
class ReceiptSection extends StatelessWidget {
  const ReceiptSection({
    super.key,
    required this.bytes,
    required this.missing,
    required this.loading,
    required this.onTakePhoto,
    required this.onChoosePhoto,
    required this.onRemove,
  });

  /// The photo shown, or null.
  final Uint8List? bytes;

  /// Whether the transaction has a receipt whose photo is not on this device.
  final bool missing;

  /// Whether the stored photo is still being read.
  final bool loading;

  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = this.bytes;
    final Widget body;
    if (loading) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (bytes == null && !missing) {
      body = Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          OutlinedButton.icon(
            onPressed: onTakePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.receiptTakePhoto),
          ),
          OutlinedButton.icon(
            onPressed: onChoosePhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.receiptChoosePhoto),
          ),
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bytes != null)
            _Thumbnail(bytes)
          else
            SizedBox(
              width: _Thumbnail.width,
              height: _Thumbnail.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (missing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.receiptMissing,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                _ReplaceButton(
                  onTakePhoto: onTakePhoto,
                  onChoosePhoto: onChoosePhoto,
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.receiptRemove),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.receiptTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        body,
      ],
    );
  }
}

// The photo, small; a tap opens it full screen.
class _Thumbnail extends ConsumerWidget {
  const _Thumbnail(this.bytes);

  static const double width = 96;
  static const double height = 128;

  final Uint8List bytes;

  void _open(BuildContext context) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => ReceiptViewScreen(bytes: bytes),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      button: true,
      image: true,
      label: l10n.receiptImage,
      onTapHint: l10n.receiptOpenHint,
      onTap: () => _open(context),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: ResizeImage.resizeIfNeeded(
              (width * MediaQuery.devicePixelRatioOf(context)).round(),
              null,
              ref.watch(receiptImageProvider)(bytes),
            ),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: width,
              height: height,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

// Replace: the camera or the gallery, from a bottom sheet.
class _ReplaceButton extends StatelessWidget {
  const _ReplaceButton({
    required this.onTakePhoto,
    required this.onChoosePhoto,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;

  Future<void> _choose(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final VoidCallback? chosen = await showModalBottomSheet<VoidCallback>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.receiptTakePhoto),
              onTap: () => Navigator.of(context).pop(onTakePhoto),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.receiptChoosePhoto),
              onTap: () => Navigator.of(context).pop(onChoosePhoto),
            ),
          ],
        ),
      ),
    );
    chosen?.call();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: () => _choose(context),
      icon: const Icon(Icons.swap_horiz),
      label: Text(
        l10n.receiptReplace,
        semanticsLabel: l10n.receiptReplaceLabel,
      ),
    );
  }
}

/// The receipt photo full screen, zoomable.
class ReceiptViewScreen extends ConsumerWidget {
  const ReceiptViewScreen({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptTitle)),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Image(
            image: ref.watch(receiptImageProvider)(bytes),
            fit: BoxFit.contain,
            semanticLabel: l10n.receiptImage,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      ),
    );
  }
}
