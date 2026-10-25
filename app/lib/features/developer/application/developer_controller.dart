/// The developer menu's operations (dev flavor only, `docs/reference/developer.md`): the
/// development server's Item and Sandbox controls, each followed by the Plaid pull, the
/// pull on its own, and the persona provisioning job.
///
/// Every call goes through `FinanceApi`; nothing here reaches Plaid or holds a key. An
/// operation's outcome stays in [DeveloperState] until the next one, never thrown: what
/// the call answered, or its exception as `ApiException.toString` names it (type, status
/// and code, never a token). One operation at a time. The provisioning job's id is kept
/// here, so the screen that polls it ([DeveloperController.pollJob], every
/// [provisionPollInterval], skipping a tick while the last request is unanswered) can
/// stop when it is closed and resume when it is opened again.
library;

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'developer_controller.g.dart';

final Logger _log = Logger('developer');

/// How often the screen asks for a running provisioning job's progress.
const Duration provisionPollInterval = Duration(seconds: 5);

/// The most transactions one injection takes (the contract's limit).
const int maxInjected = 10;

/// Plaid Sandbox's "today" at the instant [nowUtc]: the calendar date at UTC−12, the
/// latest date `sandboxCreateTransactions` accepts (`PLAN.md` §12, contract 0.3.0 as
/// delivered).
LocalDate plaidToday(DateTime nowUtc) =>
    LocalDate.fromDateTime(nowUtc.toUtc().subtract(const Duration(hours: 12)));

/// The operations of the menu.
enum DeveloperOperation {
  refreshTransactions,
  refreshBalances,
  resetLogin,
  fireWebhook,
  injectTransactions,
  pull,
  provision,
}

/// What the last Item operation did. [failure] names the exception when the operation
/// failed; otherwise [pullFailure] names the pull's when the pull after it failed.
final class DeveloperResult {
  const DeveloperResult(
    this.operation, {
    this.run,
    this.accounts,
    this.injected,
    this.failure,
    this.pullFailure,
  });

  final DeveloperOperation operation;

  /// What `refreshItem` answered.
  final SyncRun? run;

  /// How many accounts `refreshBalances` answered.
  final int? accounts;

  /// How many transactions were injected.
  final int? injected;

  final String? failure;
  final String? pullFailure;
}

/// The outcome of the last pull the menu ran: when the last whole pull finished (UTC,
/// null before the first) and, when this one failed, its exception.
typedef DeveloperPull = ({DateTime? pulledAt, String? failure});

/// The menu's state.
final class DeveloperState {
  const DeveloperState({
    this.running,
    this.result,
    this.pull,
    this.jobId,
    this.job,
    this.jobFailure,
  });

  /// The operation in flight, or null.
  final DeveloperOperation? running;

  /// The last Item operation's outcome.
  final DeveloperResult? result;

  /// The last pull's outcome.
  final DeveloperPull? pull;

  /// The provisioning job started from the menu, and its last known state.
  final String? jobId;
  final ProvisionJob? job;

  /// Why starting or polling the job last failed, or null.
  final String? jobFailure;

  /// Whether the job is still queued or running, so worth polling.
  bool get jobActive =>
      jobId != null &&
      job?.status != ProvisionJobStatus.completed &&
      job?.status != ProvisionJobStatus.failed;
}

/// The developer menu's state and operations.
@Riverpod(keepAlive: true)
class DeveloperController extends _$DeveloperController {
  // Whether a `getProvisionJob` is in flight, so a poll tick waits for its answer.
  bool _polling = false;

  @override
  DeveloperState build() => const DeveloperState();

  FinanceApi get _api => ref.read(financeApiProvider);

  /// `refreshItem`: Plaid refreshes the Item's transactions; then the pull.
  Future<void> refreshTransactions(String itemId) => _onItem(
    DeveloperOperation.refreshTransactions,
    itemId,
    () async => DeveloperResult(
      DeveloperOperation.refreshTransactions,
      run: await _api.refreshItem(itemId),
    ),
  );

  /// `refreshBalances`; then the pull.
  Future<void> refreshBalances(String itemId) => _onItem(
    DeveloperOperation.refreshBalances,
    itemId,
    () async => DeveloperResult(
      DeveloperOperation.refreshBalances,
      accounts: (await _api.refreshBalances(itemId)).length,
    ),
  );

  /// `sandboxResetLogin`: the Item needs its login repaired; then the pull.
  Future<void> resetLogin(String itemId) =>
      _onItem(DeveloperOperation.resetLogin, itemId, () async {
        await _api.sandboxResetLogin(itemId);
        return const DeveloperResult(DeveloperOperation.resetLogin);
      });

  /// `sandboxFireWebhook` with [code]; then the pull.
  Future<void> fireWebhook(String itemId, SandboxWebhookCode code) =>
      _onItem(DeveloperOperation.fireWebhook, itemId, () async {
        await _api.sandboxFireWebhook(itemId, code);
        return const DeveloperResult(DeveloperOperation.fireWebhook);
      });

  /// `sandboxCreateTransactions`: [count] transactions of [amount] (the app's sign) on
  /// account [accountId], dated [daysBack] days before Plaid's today, described
  /// [description] (numbered when more than one); then the pull.
  Future<void> injectTransactions(
    String itemId, {
    required String accountId,
    required int count,
    required String description,
    required Money amount,
    required int daysBack,
  }) => _onItem(DeveloperOperation.injectTransactions, itemId, () async {
    final LocalDate date = plaidToday(ref.read(clockProvider).nowUtc())
        .addDays(-daysBack);
    await _api.sandboxCreateTransactions(itemId, [
      for (int i = 1; i <= count; i++)
        SandboxTransaction(
          dateTransacted: date,
          datePosted: date,
          amount: amount,
          description: count == 1 ? description : '$description $i',
          accountId: accountId,
        ),
    ]);
    return DeveloperResult(
      DeveloperOperation.injectTransactions,
      injected: count,
    );
  });

  /// The Plaid pull on its own.
  Future<void> pullNow() async {
    if (state.running != null) return;
    _set(running: DeveloperOperation.pull);
    await _pull();
    _set(running: null);
  }

  /// Starts provisioning [persona] (`provisionPersona`); the screen then polls it.
  Future<void> provision(
    ProvisionPersona persona, {
    required int seed,
    required int days,
  }) async {
    if (state.running != null || state.jobActive) return;
    _set(running: DeveloperOperation.provision);
    try {
      final ProvisionJob job = await _api.provisionPersona(
        persona,
        seed: seed,
        days: days,
      );
      _setJob(job.id, job, null);
    } on Object catch (e) {
      _log.warning('provision failed: ${e.runtimeType}');
      _setJob(null, null, _describe(e));
    }
    _set(running: null);
  }

  /// Asks for the job's progress (`getProvisionJob`), unless none is active or the
  /// previous request has not been answered yet. A failed request is shown and the job
  /// asked for again at the next poll.
  Future<void> pollJob() async {
    final String? jobId = state.jobId;
    if (jobId == null || !state.jobActive || _polling) return;
    _polling = true;
    try {
      final ProvisionJob job = await _api.getProvisionJob(jobId);
      if (state.jobId == jobId) _setJob(jobId, job, null);
    } on Object catch (e) {
      _log.warning('provision poll failed: ${e.runtimeType}');
      if (state.jobId == jobId) _setJob(jobId, state.job, _describe(e));
    } finally {
      _polling = false;
    }
  }

  // Runs [operation] on Item [itemId], then the pull; the outcome goes into the state.
  Future<void> _onItem(
    DeveloperOperation operation,
    String itemId,
    Future<DeveloperResult> Function() call,
  ) async {
    if (state.running != null) return;
    _set(running: operation);
    DeveloperResult result;
    try {
      result = await call();
    } on Object catch (e) {
      _log.warning('${operation.name} failed: ${e.runtimeType}');
      if (e is ItemLoginRequired) {
        await ref.read(itemRepositoryProvider).markLoginRequired(itemId);
      }
      _set(
        running: null,
        result: DeveloperResult(operation, failure: _describe(e)),
      );
      return;
    }
    final String? pullFailure = await _pull();
    _set(
      running: null,
      result: DeveloperResult(
        operation,
        run: result.run,
        accounts: result.accounts,
        injected: result.injected,
        pullFailure: pullFailure,
      ),
    );
  }

  // The Plaid pull; its outcome goes into the state and its failure is returned.
  Future<String?> _pull() async {
    String? failure;
    try {
      await ref.read(plaidPullProvider).run();
    } on Object catch (e) {
      _log.warning('pull failed: ${e.runtimeType}');
      failure = _describe(e);
    }
    final DateTime? pulledAt = await ref
        .read(plaidPullStoreProvider)
        .pulledAt();
    _set(pull: (pulledAt: pulledAt, failure: failure));
    return failure;
  }

  static const Object _keep = Object();

  void _set({
    Object? running = _keep,
    DeveloperResult? result,
    DeveloperPull? pull,
  }) {
    if (!ref.mounted) return;
    state = DeveloperState(
      running: identical(running, _keep)
          ? state.running
          : running as DeveloperOperation?,
      result: result ?? state.result,
      pull: pull ?? state.pull,
      jobId: state.jobId,
      job: state.job,
      jobFailure: state.jobFailure,
    );
  }

  void _setJob(String? jobId, ProvisionJob? job, String? failure) {
    if (!ref.mounted) return;
    state = DeveloperState(
      running: state.running,
      result: state.result,
      pull: state.pull,
      jobId: jobId,
      job: job,
      jobFailure: failure,
    );
  }
}

// The exception as the menu shows it: an API failure's type, status and code (and the
// fields a validation failure names), any other's type. Never a token.
String _describe(Object error) => switch (error) {
  ValidationFailed(:final List<FieldError> errors) when errors.isNotEmpty =>
    '$error: ${errors.map((e) => e.field).join(', ')}',
  ApiException() => error.toString(),
  _ => error.runtimeType.toString(),
};
