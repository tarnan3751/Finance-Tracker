/// Server-assigned ids.
library;

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A new random (v4) uuid. It fits the `Hlc` node-id pattern, so a device id can be a
/// clock's node id.
String newId() => _uuid.v4();
