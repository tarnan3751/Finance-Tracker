/// How the background sync's isolate and the app's coordinate within one process
/// (`docs/reference/background.md`, **One session at a time**), through named ports that
/// every engine in the process sees (`IsolateNameServer`). Each side registers its own
/// name before it looks at the other's, so two that start together always see each
/// other:
///
/// - **`ft.background`** is a lock: a worker takes it ([acquireBackgroundCycle]) before
///   anything else. A name already registered is taken; when its holder answers a ping
///   the worker does nothing (the periodic sync and a one-off, being different unique
///   works, can start together), and when it does not (its engine is gone and left the
///   name behind) the worker removes it, if it still holds the same port, and takes it.
///   An app starting meanwhile waits for it to go, at most [startWaitCeiling], before it
///   opens anything local ([waitForBackgroundCycle]).
/// - **`ft.app`**, registered by the app once per process and again on every resume
///   ([AppSyncPort]): a worker that holds the lock asks it ([askApp]). The app answers
///   `busy` while no app runs in it (a restore or a wipe has stopped it), or `ack` and
///   then `done` with the outcome of a sync it runs itself, so two sessions never share
///   one account's tokens. The worker then releases the lock. No answer within
///   [ackTimeout], and none to a second ask within [secondAckTimeout], means the app's
///   isolate is gone: the worker removes the name, only if it still holds the port it
///   asked, and runs its own cycle.
///
/// Messages are plain lists of strings and ports, so they cross isolates as they are.
library;

import 'dart:async';
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

/// The app's port name.
const String appPortName = 'ft.app';

/// The worker's port name.
const String backgroundPortName = 'ft.background';

/// How long the worker waits for the app's `ack`.
const Duration ackTimeout = Duration(seconds: 2);

/// How long the worker waits for an `ack` to its second ask, before it takes the app
/// for gone.
const Duration secondAckTimeout = Duration(seconds: 5);

/// How long a ping waits for its answer.
const Duration pingTimeout = Duration(seconds: 1);

/// How long a worker that took a dead holder's lock waits before it looks again.
const Duration takeoverSettle = Duration(milliseconds: 50);

/// How long the worker waits for the app's `done` after its `ack`.
const Duration doneTimeout = Duration(seconds: 30);

/// How long a starting app waits for the worker's own cycle to finish.
const Duration startWaitCeiling = Duration(seconds: 45);

/// The process-wide name registry: `IsolateNameServer`, or a map in tests.
abstract interface class PortRegistry {
  /// The port registered under [name], or null.
  SendPort? lookup(String name);

  /// Registers [port] under [name]; false when the name is already taken.
  bool register(SendPort port, String name);

  /// Removes the mapping of [name].
  void remove(String name);
}

/// The registry of the process.
final class IsolateNameRegistry implements PortRegistry {
  const IsolateNameRegistry();

  @override
  SendPort? lookup(String name) => IsolateNameServer.lookupPortByName(name);

  @override
  bool register(SendPort port, String name) =>
      IsolateNameServer.registerPortWithName(port, name);

  @override
  void remove(String name) => IsolateNameServer.removePortNameMapping(name);
}

/// A registry in memory, for tests within one isolate.
final class MapPortRegistry implements PortRegistry {
  final Map<String, SendPort> _ports = {};

  @override
  SendPort? lookup(String name) => _ports[name];

  @override
  bool register(SendPort port, String name) {
    if (_ports.containsKey(name)) return false;
    _ports[name] = port;
    return true;
  }

  @override
  void remove(String name) => _ports.remove(name);
}

/// What a sync the app ran on the worker's behalf came to.
enum DelegatedResult {
  /// Done; nothing for WorkManager to retry.
  success,

  /// No network: WorkManager retries on its backoff.
  retry,
}

/// What the app answered the worker.
sealed class AppAnswer {
  const AppAnswer();
}

/// No app isolate answered: the worker runs its own cycle.
final class NoApp extends AppAnswer {
  const NoApp();
}

/// The app is stopped for a restore or a wipe: the worker does nothing.
final class AppBusy extends AppAnswer {
  const AppBusy();
}

/// The app ran the sync; [result] is how it went, or null when it acknowledged and sent
/// nothing more within [doneTimeout].
final class AppSynced extends AppAnswer {
  const AppSynced(this.result);

  final DelegatedResult? result;
}

/// The app's side of `ft.app`: busy while [_running] says no app runs, else an `ack`,
/// then [_sync]'s outcome.
final class AppSyncPort {
  /// Registers the port in `registry`; the previous mapping of a dead engine goes.
  AppSyncPort(
    this._running,
    this._sync, {
    this._registry = const IsolateNameRegistry(),
  }) {
    _port.listen(_handle);
    register();
  }

  /// Registers the port again, replacing whatever holds the name (a dead engine's, or a
  /// worker's removal): `bootstrap` calls it on every resume.
  void register() {
    if (_registry.lookup(appPortName) == _port.sendPort) return;
    _registry.remove(appPortName);
    _registry.register(_port.sendPort, appPortName);
  }

  final bool Function() _running;
  final Future<DelegatedResult> Function() _sync;
  final PortRegistry _registry;
  final ReceivePort _port = ReceivePort();
  Future<DelegatedResult>? _inFlight;

  Future<void> _handle(Object? message) async {
    if (message is! List || message.isEmpty || message.first is! SendPort) {
      return;
    }
    final SendPort reply = message.first as SendPort;
    if (!_running()) {
      reply.send(['busy']);
      return;
    }
    reply.send(['ack']);
    // A second ask while one runs joins it rather than running another.
    final Future<DelegatedResult> running = _inFlight ??= _sync()
        .catchError(
          // The app's own status has it; the worker has nothing to retry.
          (Object _) => DelegatedResult.success,
        )
        .whenComplete(() => _inFlight = null);
    reply.send(['done', (await running).name]);
  }

  /// Removes the port.
  void close() {
    if (_registry.lookup(appPortName) == _port.sendPort) {
      _registry.remove(appPortName);
    }
    _port.close();
  }
}

/// Asks the app's isolate to sync, if one answers: the worker's first step once it
/// holds the lock.
Future<AppAnswer> askApp({
  PortRegistry registry = const IsolateNameRegistry(),
  Duration ack = ackTimeout,
  Duration secondAck = secondAckTimeout,
  Duration done = doneTimeout,
}) async {
  final SendPort? app = registry.lookup(appPortName);
  if (app == null) return const NoApp();
  final _Inbox inbox = _Inbox();
  try {
    app.send([inbox.sendPort]);
    Object? reply = await inbox.next(ack);
    if (reply == null) {
      // A busy app may be slow to answer: ask once more, longer, before taking it for
      // gone. A late answer to the first ask counts.
      app.send([inbox.sendPort]);
      reply = await inbox.next(secondAck);
    }
    if (reply == null) {
      // An engine that is gone left its name behind; a new one may hold it already.
      if (registry.lookup(appPortName) == app) registry.remove(appPortName);
      return const NoApp();
    }
    if (_kind(reply) == 'busy') return const AppBusy();
    // The answer to a second ask may come too; only `done` ends the wait.
    while (_kind(reply) != 'done') {
      reply = await inbox.next(done);
      if (reply == null) return const AppSynced(null);
    }
    return AppSynced(
      reply is List && reply.length == 2
          ? DelegatedResult.values.asNameMap()[reply[1]] ??
                DelegatedResult.success
          : DelegatedResult.success,
    );
  } finally {
    inbox.close();
  }
}

/// The replies to the worker's asks, taken one at a time with a wait each.
final class _Inbox {
  _Inbox() {
    _port.listen((message) {
      _messages.add(message);
      final Completer<void>? waiting = _waiting;
      _waiting = null;
      if (waiting != null && !waiting.isCompleted) waiting.complete();
    });
  }

  final ReceivePort _port = ReceivePort();
  final List<Object?> _messages = [];
  Completer<void>? _waiting;

  SendPort get sendPort => _port.sendPort;

  /// The next reply, or null when none comes within [wait].
  Future<Object?> next(Duration wait) async {
    if (_messages.isEmpty) {
      final Completer<void> waiting = _waiting = Completer<void>();
      await waiting.future.timeout(wait, onTimeout: () {});
      _waiting = null;
    }
    return _messages.isEmpty ? null : _messages.removeAt(0);
  }

  void close() => _port.close();
}

Object? _kind(Object? reply) =>
    reply is List && reply.isNotEmpty ? reply.first : null;

// Whether [port] answers a ping within [wait].
Future<bool> _answers(SendPort port, Duration wait) async {
  final ReceivePort pong = ReceivePort();
  try {
    port.send([pong.sendPort]);
    return await pong.first
        .then((_) => true)
        .timeout(wait, onTimeout: () => false);
  } finally {
    pong.close();
  }
}

/// Takes the `ft.background` lock, or returns null when a live cycle holds it (see the
/// library comment).
Future<BackgroundCyclePort?> acquireBackgroundCycle({
  PortRegistry registry = const IsolateNameRegistry(),
  Duration ping = pingTimeout,
}) async {
  final BackgroundCyclePort port = BackgroundCyclePort._(registry);
  if (registry.register(port._port.sendPort, backgroundPortName)) return port;
  final SendPort? holder = registry.lookup(backgroundPortName);
  if (holder != null && await _answers(holder, ping)) {
    port._port.close();
    return null;
  }
  if (registry.lookup(backgroundPortName) == holder) {
    registry.remove(backgroundPortName);
  }
  if (registry.register(port._port.sendPort, backgroundPortName)) {
    // Taking a dead holder's name is not atomic across isolates: another worker that read
    // the same dead holder may have removed this registration and made its own. Look
    // again a moment later, and step aside when the name is no longer ours.
    await Future<void>.delayed(takeoverSettle);
    if (registry.lookup(backgroundPortName) == port._port.sendPort) return port;
  }
  port._port.close();
  return null;
}

/// The worker's hold on `ft.background` ([acquireBackgroundCycle]): answers pings until
/// [release].
final class BackgroundCyclePort {
  BackgroundCyclePort._(this._registry) {
    _port.listen((message) {
      if (message is List && message.isNotEmpty && message.first is SendPort) {
        (message.first as SendPort).send(['pong']);
      }
    });
  }

  final PortRegistry _registry;
  final ReceivePort _port = ReceivePort();
  bool _released = false;

  /// Gives the lock up: the cycle is over. Idempotent.
  void release() {
    if (_released) return;
    _released = true;
    if (_registry.lookup(backgroundPortName) == _port.sendPort) {
      _registry.remove(backgroundPortName);
    }
    _port.close();
  }
}

/// Waits, at most [ceiling], while a worker's own cycle runs (`startApp`'s first step):
/// returns as soon as none is registered, or the one registered stops answering its pings
/// (stale: its mapping is removed, if it still holds the same port).
Future<void> waitForBackgroundCycle({
  PortRegistry registry = const IsolateNameRegistry(),
  Duration ceiling = startWaitCeiling,
  Duration ping = pingTimeout,
  Duration poll = const Duration(milliseconds: 200),
}) async {
  final Stopwatch waited = Stopwatch()..start();
  while (waited.elapsed < ceiling) {
    final SendPort? worker = registry.lookup(backgroundPortName);
    if (worker == null) return;
    // A holder that stops answering (its engine died with its cycle pending) is stale.
    if (!await _answers(worker, ping)) {
      if (registry.lookup(backgroundPortName) == worker) {
        registry.remove(backgroundPortName);
      }
      return;
    }
    await Future<void>.delayed(poll);
  }
}
