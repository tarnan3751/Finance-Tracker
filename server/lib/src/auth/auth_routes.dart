/// `register`, `login`, `refreshTokens` and `logout`.
library;

import 'package:finance_tracker_server/src/auth/auth_service.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/wire.dart';

/// The auth routes over [auth].
List<ApiRoute> authRoutes(AuthService auth) => [
  ApiRoute(
    'register',
    'post',
    '/auth/register',
    (r) async {
      final body = ObjectReader(await r.json(), const {
        'email',
        'password',
        'device_name',
        'display_name',
      });
      final email = body.string('email', email: true);
      final password = body.string('password', minLength: 8, maxLength: 128);
      final device = body.string('device_name', minLength: 1, maxLength: 100);
      final display = body.string(
        'display_name',
        required: false,
        minLength: 1,
        maxLength: 100,
      );
      body.check();
      return jsonResponse(
        await auth.register(
          email: email!,
          password: password!,
          deviceName: device!,
          displayName: display,
        ),
        status: 201,
      );
    },
    authenticated: false,
    rateLimited: true,
  ),
  ApiRoute(
    'login',
    'post',
    '/auth/login',
    (r) async {
      final body = ObjectReader(await r.json(), const {
        'email',
        'password',
        'device_name',
      });
      final email = body.string('email', email: true);
      final password = body.string('password', minLength: 8, maxLength: 128);
      final device = body.string('device_name', minLength: 1, maxLength: 100);
      body.check();
      return jsonResponse(
        await auth.login(
          email: email!,
          password: password!,
          deviceName: device!,
        ),
      );
    },
    authenticated: false,
    rateLimited: true,
  ),
  ApiRoute(
    'refreshTokens',
    'post',
    '/auth/refresh',
    (r) async {
      final body = ObjectReader(await r.json(), const {'refresh_token'});
      final token = body.string('refresh_token', minLength: 1);
      body.check();
      return jsonResponse(await auth.refresh(token!));
    },
    authenticated: false,
    rateLimited: true,
  ),
  ApiRoute('logout', 'post', '/auth/logout', (r) async {
    final body = ObjectReader(await r.json(), const {'refresh_token'});
    final token = body.string('refresh_token', minLength: 1);
    body.check();
    await auth.logout(deviceId: r.deviceId, refreshToken: token!);
    return noContent();
  }),
];
