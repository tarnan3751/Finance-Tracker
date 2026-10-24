/// The Sandbox control routes: `sandboxResetLogin`, `sandboxFireWebhook`,
/// `sandboxCreateTransactions`, and the persona provisioning job's `provisionPersona` and
/// `getProvisionJob` (`docs/reference/server.md`, **Sandbox operations**,
/// **Provisioning**). The bodies are read here; the rules are [SandboxService]'s and
/// [ProvisioningService]'s.
library;

import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/plaid/provisioning_service.dart';
import 'package:finance_tracker_server/src/plaid/sandbox_service.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

/// The Sandbox routes over [sandbox] and [provisioning].
List<ApiRoute> sandboxRoutes(
  SandboxService sandbox,
  ProvisioningService provisioning,
) => [
  ApiRoute(
    'sandboxResetLogin',
    'post',
    '/sandbox/items/{item_id}/reset-login',
    (r) async {
      await sandbox.resetLogin(r.userId, r.param('item_id'));
      return noContent();
    },
  ),
  ApiRoute(
    'sandboxFireWebhook',
    'post',
    '/sandbox/items/{item_id}/fire-webhook',
    (r) async {
      final body = ObjectReader(await r.json(), const {'webhook_code'});
      final code = body.oneOf('webhook_code', {
        for (final c in webhookCodes) c: c,
      });
      body.check();
      await sandbox.fireWebhook(r.userId, r.param('item_id'), code!);
      return noContent();
    },
  ),
  ApiRoute(
    'sandboxCreateTransactions',
    'post',
    '/sandbox/items/{item_id}/transactions',
    (r) async {
      final body = ObjectReader(await r.json(), const {'transactions'});
      final raw = body.list('transactions');
      final transactions = <SandboxTransactionRequest>[];
      if (raw != null && (raw.isEmpty || raw.length > 10)) {
        body.errors.add(
          const FieldError('transactions', 'must hold 1 to 10 transactions'),
        );
      } else if (raw != null) {
        for (final (i, element) in raw.indexed) {
          if (element is! Map<String, Object?>) {
            body.errors.add(
              FieldError('transactions[$i]', 'must be an object'),
            );
            continue;
          }
          final t = ObjectReader(
            element,
            const {
              'date_transacted',
              'date_posted',
              'amount',
              'description',
              'account_id',
            },
            prefix: 'transactions[$i]',
            errors: body.errors,
          );
          final transacted = t.date('date_transacted');
          final posted = t.date('date_posted');
          final amount = t.money('amount');
          final description = t.string(
            'description',
            minLength: 1,
            maxLength: 200,
          );
          final accountId = t.string(
            'account_id',
            required: false,
            minLength: 1,
          );
          if (transacted != null &&
              posted != null &&
              amount != null &&
              description != null) {
            transactions.add((
              dateTransacted: transacted,
              datePosted: posted,
              amount: amount,
              description: description,
              accountId: accountId,
            ));
          }
        }
      }
      body.check();
      await sandbox.createTransactions(
        r.userId,
        r.param('item_id'),
        transactions,
      );
      return noContent();
    },
  ),
  ApiRoute('provisionPersona', 'post', '/sandbox/provision', (r) async {
    final body = ObjectReader(await r.json(), const {
      'persona',
      'seed',
      'days',
    });
    final persona = body.oneOf('persona', {
      for (final p in PersonaId.values) p.slug: p,
    });
    final seed = body.integer(
      'seed',
      required: false,
      fallback: 1,
      min: 1,
      max: 0x7FFFFFFF,
    );
    final days = body.integer(
      'days',
      required: false,
      fallback: 730,
      min: 30,
      max: 730,
    );
    body.check();
    return jsonResponse(
      provisioning.start(
        r.userId,
        r.deviceId,
        persona: persona!,
        seed: seed!,
        days: days!,
        baseUrl: r.raw.requestedUri,
      ),
      status: 202,
    );
  }),
  ApiRoute(
    'getProvisionJob',
    'get',
    '/sandbox/provision/{job_id}',
    (r) async => jsonResponse(provisioning.get(r.userId, r.param('job_id'))),
  ),
];
