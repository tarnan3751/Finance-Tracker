/// The Plaid proxy: `createLinkToken`, `exchangePublicToken`, `listItems`, `deleteItem`,
/// `syncItem`, `refreshItem`, `refreshBalances` and `createUpdateLinkToken`, the
/// institution logo (`getInstitutionLogo`), plus the webhook receiver, which reads the
/// body's exact bytes and hands them to [WebhookService] (204 for every verified delivery,
/// 401 `webhook_unverified` otherwise). Item JSON carries
/// logo URLs built from the request's own scheme and host, so the emulator's `10.0.2.2`
/// works.
library;

import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:finance_tracker_server/src/plaid/webhook_service.dart';
import 'package:shelf/shelf.dart';

final _packageName = RegExp(
  r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
);

/// The Plaid routes over [items] and [webhooks].
List<ApiRoute> plaidRoutes(ItemService items, WebhookService webhooks) => [
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
      await items.exchange(
        r.userId,
        r.deviceId,
        token!,
        baseUrl: r.raw.requestedUri,
      ),
      status: 201,
    );
  }),
  ApiRoute(
    'listItems',
    'get',
    '/plaid/items',
    (r) async =>
        jsonResponse(await items.list(r.userId, baseUrl: r.raw.requestedUri)),
  ),
  ApiRoute('deleteItem', 'delete', '/plaid/items/{item_id}', (r) async {
    final text = r.raw.url.queryParameters['history'];
    final history = text == null
        ? UnlinkHistory.delete
        : UnlinkHistory.values.where((h) => h.name == text).firstOrNull ??
              (throw ValidationException.single(
                'history',
                'must be keep or delete',
              ));
    await items.delete(r.userId, r.param('item_id'), history: history);
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
    'refreshItem',
    'post',
    '/plaid/items/{item_id}/refresh',
    (r) async => jsonResponse(
      await items.refresh(r.userId, r.param('item_id')),
      status: 202,
    ),
  ),
  ApiRoute(
    'refreshBalances',
    'post',
    '/plaid/items/{item_id}/balances',
    (r) async =>
        jsonResponse(await items.refreshBalances(r.userId, r.param('item_id'))),
  ),
  ApiRoute(
    'getInstitutionLogo',
    'get',
    '/institutions/{institution_id}/logo',
    (r) async => Response.ok(
      await items.institutionLogo(r.userId, r.param('institution_id')),
      headers: const {'content-type': 'image/png'},
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
  ApiRoute('receivePlaidWebhook', 'post', '/webhooks/plaid', (r) async {
    await webhooks.receive(
      await readBodyBytes(r.raw),
      r.raw.headers['plaid-verification'],
    );
    return noContent();
  }, authenticated: false),
];
