/// Which [ImageSource] takes receipt photos: `image_picker` by default (dev and prod), the
/// fake with the bundled receipt in the demo flavor (`overridesFor`); tests override it
/// with their own fake.
library;

import 'package:finance_tracker/core/platform/image_picker_source.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_source_provider.g.dart';

/// The image source.
@Riverpod(keepAlive: true)
ImageSource imageSource(Ref ref) => ImagePickerSource();
