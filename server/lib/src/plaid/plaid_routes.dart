/// The Plaid proxy: `createLinkToken`, `exchangePublicToken`, `listItems`, `deleteItem`,
/// `syncItem` and `createUpdateLinkToken`, plus the webhook receiver, which answers 401
/// `webhook_unverified` to every delivery until Phase 3 verifies them.
library;

import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';

final _packageName = RegExp(
  r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
);

/// The Plaid routes over [items].
List<ApiRoute> plaidRoutes(ItemService items) => [
  ApiRoute('createLinkToken', 'post', '/plaid/link-token', (r) async {
    final body = ObjectReader(await r.json(), const {
      'android_package_name',
      'update_item_id',
    });
    final package = body.string('android_package_name', pattern: _packageName);
    final update = body.string('update_item_id', required: false, minLength: 1);
    body.check();
    return jsonResponse(
      await items.createLinkToken(
        r.userId,
        androidPackageName: package!,
        updateItemId: update,
      ),
    );
  }),
  ApiRoute('exchangePublicToken', 'post', '/plaid/exchange', (r) async {
    final body = ObjectReader(await r.json(), const {'public_token'});
    final token = body.string('public_token', minLength: 1);
    body.check();
    return jsonResponse(
      await items.exchange(r.userId, r.deviceId, token!),
      status: 201,
    );
  }),
  ApiRoute(
    'listItems',
    'get',
    '/plaid/items',
    (r) async => jsonResponse(await items.list(r.userId)),
  ),
  ApiRoute('deleteItem', 'delete', '/plaid/items/{item_id}', (r) async {
    await items.delete(r.userId, r.param('item_id'));
    return noContent();
  }),
  ApiRoute(
    'syncItem',
    'post',
    '/plaid/items/{item_id}/sync',
    (r) async => jsonResponse(
      await items.sync(r.userId, r.param('item_id')),
      status: 202,
    ),
  ),
  ApiRoute(
    'createUpdateLinkToken',
    'post',
    '/plaid/items/{item_id}/update-link-token',
    (r) async {
      final body = ObjectReader(await r.json(), const {'android_package_name'});
      final package = body.string(
        'android_package_name',
        pattern: _packageName,
      );
      body.check();
      return jsonResponse(
        await items.createUpdateLinkToken(
          r.userId,
          r.param('item_id'),
          androidPackageName: package!,
        ),
      );
    },
  ),
  ApiRoute(
    'receivePlaidWebhook',
    'post',
    '/webhooks/plaid',
    (r) async => throw const ProblemException.unauthorized(
      ProblemCode.webhookUnverified,
      detail:
          'Webhook verification arrives in Phase 3; no delivery is processed',
    ),
    authenticated: false,
  ),
];
