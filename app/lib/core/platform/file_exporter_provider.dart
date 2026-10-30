/// Which [FileExporter] saves and shares exported files: the fake by default (the demo
/// flavor and the tests), `flutter_file_dialog` and `share_plus` in dev and prod
/// (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_exporter_provider.g.dart';

/// The file exporter.
@Riverpod(keepAlive: true)
FileExporter fileExporter(Ref ref) => FakeFileExporter();
