// The image_picker source: asks for at most 1600 pixels at quality 85 from the camera or
// the gallery, returns a JPEG or a PNG stripped of its metadata, refuses any other
// format (a WebP), deletes the picker's file, returns null when the user took or chose
// nothing, and turns the picker's errors into NoCameraException and
// ImagePickFailedException.
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/core/platform/image_picker_source.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/jpeg_metadata.dart';
import 'package:finance_tracker/core/platform/png_metadata.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:mocktail/mocktail.dart';

class _MockPicker extends Mock implements picker.ImagePicker {}

void main() {
  setUpAll(() => registerFallbackValue(picker.ImageSource.camera));

  late Directory cache;
  late _MockPicker imagePicker;
  late ImagePickerSource source;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('picker_cache');
    imagePicker = _MockPicker();
    source = ImagePickerSource(imagePicker);
  });
  tearDown(() => cache.deleteSync(recursive: true));

  void picks(Future<picker.XFile?> Function() result) => when(
    () => imagePicker.pickImage(
      source: any(named: 'source'),
      maxWidth: any(named: 'maxWidth'),
      imageQuality: any(named: 'imageQuality'),
    ),
  ).thenAnswer((_) => result());

  test('a camera photo comes back stripped and its file is deleted', () async {
    final Uint8List original = File(
      'test/fixtures/receipts/exif_gps_orientation6.jpg',
    ).readAsBytesSync();
    final File picked = File('${cache.path}/photo.jpg')
      ..writeAsBytesSync(original);
    picks(() async => picker.XFile(picked.path));

    final PickedImage? image = await source.pickFromCamera();

    expect(image!.bytes, stripJpegMetadata(original));
    expect(latin1.decode(image.bytes), isNot(contains('FixtureCam')));
    expect(picked.existsSync(), isFalse);
    verify(
      () => imagePicker.pickImage(
        source: picker.ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      ),
    ).called(1);
  });

  test('the gallery is asked the same way', () async {
    final File picked = File('${cache.path}/chosen.jpg')
      ..writeAsBytesSync(
        File('test/fixtures/receipts/plain.jpg').readAsBytesSync(),
      );
    picks(() async => picker.XFile(picked.path));

    final PickedImage? image = await source.pickFromGallery();

    expect(
      image!.bytes,
      File('test/fixtures/receipts/plain.jpg').readAsBytesSync(),
    );
    verify(
      () => imagePicker.pickImage(
        source: picker.ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      ),
    ).called(1);
  });

  test('a PNG comes back without its metadata chunks', () async {
    final Uint8List original = File('test/fixtures/receipts/metadata.png')
        .readAsBytesSync();
    final File picked = File('${cache.path}/scaled.png')
      ..writeAsBytesSync(original);
    picks(() async => picker.XFile(picked.path));

    final PickedImage? image = await source.pickFromGallery();

    expect(image!.bytes, stripPngMetadata(original));
    expect(latin1.decode(image.bytes), isNot(contains('FixtureCam')));
    expect(picked.existsSync(), isFalse);
  });

  test('any other format is refused, and its file deleted', () async {
    final File picked = File('${cache.path}/photo.webp')
      ..writeAsBytesSync(
        File('test/fixtures/receipts/photo.webp').readAsBytesSync(),
      );
    picks(() async => picker.XFile(picked.path));

    await expectLater(
      source.pickFromGallery(),
      throwsA(isA<ImagePickFailedException>()),
    );
    expect(picked.existsSync(), isFalse);
  });

  test('nothing taken is null', () async {
    picks(() async => null);
    expect(await source.pickFromCamera(), isNull);
  });

  test('no camera app is a NoCameraException', () {
    picks(() async => throw PlatformException(code: 'no_available_camera'));
    expect(source.pickFromCamera(), throwsA(isA<NoCameraException>()));
  });

  test('any other picker error is an ImagePickFailedException', () {
    picks(() async => throw PlatformException(code: 'camera_access_denied'));
    expect(source.pickFromCamera(), throwsA(isA<ImagePickFailedException>()));
  });

  test('a JPEG that does not parse is an ImagePickFailedException', () async {
    final File picked = File('${cache.path}/broken.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE1, 0x7F, 0xFF]);
    picks(() async => picker.XFile(picked.path));

    await expectLater(
      source.pickFromGallery(),
      throwsA(isA<ImagePickFailedException>()),
    );
    expect(picked.existsSync(), isFalse);
  });
}
