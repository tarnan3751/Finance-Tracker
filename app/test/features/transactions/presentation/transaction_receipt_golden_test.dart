// Goldens of a transaction with splits and a receipt, light and dark: the editor (which
// is the transaction's detail) of the seed's split transaction with a receipt photo, its
// two splits and the thumbnail in view; and the photo full screen, opened from the
// thumbnail. The photo is not decoded: image decoding and resizing are platform code
// whose pixels differ between machines (CI's Linux runner against macOS), so
// receiptImageProvider is overridden with a flat paper-coloured image the test draws
// itself, and the goldens show the layout only. The decode path is covered by the
// widget tests, which compare no pixels. Tagged `golden`; see
// test/flutter_test_config.dart for where the files go and how to update them.
import 'dart:ui' as ui;

import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Tall enough to show the splits and the receipt below them.
const Size _size = Size(412, 1500);

Future<Widget> _app(Brightness brightness) async {
  final InMemoryStore store = seededStore();
  store.upsertTransaction(
    store
        .transaction('demo-txn-04')!
        .copyWith(receiptPath: receiptPathFor('demo-txn-04')),
  );
  final MemoryReceiptStore receipts = MemoryReceiptStore();
  await receipts.commit(
    await receipts.stage(
      'demo-txn-04',
      // Never decoded: the image comes from [_DrawnImage].
      Uint8List.fromList(const [1, 2, 3]),
    ),
  );
  return SizedBox.fromSize(
    size: _size,
    child: buildTestApp(
      initialLocation: '/transactions/demo-txn-04',
      brightness: brightness,
      overrides: [
        storeOverride(store),
        receiptStoreProvider.overrideWithValue(receipts),
        receiptImageProvider.overrideWithValue((_) => _DrawnImage(_paper())),
      ],
    ),
  );
}

/// A receipt-sized image of one flat colour, drawn by the engine's own rasterizer: no
/// codec reaches it, and resampling a flat colour gives that colour on every platform.
ui.Image _paper() {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(const Color(0xFFF4EFE4), BlendMode.src);
  return recorder.endRecording().toImageSync(600, 900);
}

/// [image] as an [ImageProvider], with no decoding.
final class _DrawnImage extends ImageProvider<_DrawnImage> {
  const _DrawnImage(this.image);

  final ui.Image image;

  @override
  Future<_DrawnImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_DrawnImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _DrawnImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
  );
}

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    late Widget app;
    setUp(() async => app = await _app(brightness));

    goldenTest(
      'the editor of a split transaction with a receipt, ${brightness.name}',
      fileName: 'transaction_editor_splits_receipt_${brightness.name}',
      constraints: BoxConstraints.tight(_size),
      builder: () => app,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await precacheImages(tester);
      },
    );

    goldenTest(
      'a receipt full screen, ${brightness.name}',
      fileName: 'receipt_view_${brightness.name}',
      constraints: BoxConstraints.tight(_size),
      builder: () => app,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(ReceiptSection),
            matching: find.byType(Image),
          ),
        );
        await tester.pumpAndSettle();
        await precacheImages(tester);
      },
    );
  }
}
