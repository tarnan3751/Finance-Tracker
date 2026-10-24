//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/api_util.dart';
import 'package:api_client/src/model/create_sandbox_transactions_request.dart';
import 'package:api_client/src/model/fire_webhook_request.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/validation_problem.dart';

class SandboxApi {
  final Dio _dio;

  final Serializers _serializers;

  const SandboxApi(this._dio, this._serializers);

  /// Injects transactions into an Item
  /// Calls Plaid&#39;s &#x60;/sandbox/transactions/create&#x60; with one to ten transactions; the Item&#39;s next sync delivers them. Dates must be today or up to 730 days in the past; anything else is &#x60;400&#x60;. Plaid categorizes injected transactions with &#x60;LOW&#x60; confidence and attaches no merchant or logo (PLAN.md §4). Available when the server&#39;s Plaid mode can drive Sandbox (fake or sandbox); never on a production server, where it is &#x60;409&#x60; &#x60;conflict&#x60;. Another user&#39;s Item is &#x60;404&#x60;; a &#x60;removed&#x60; Item is &#x60;409&#x60; &#x60;conflict&#x60;.
  ///
  /// Parameters:
  /// * [itemId] - The Item's id
  /// * [createSandboxTransactionsRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> sandboxCreateTransactions({
    required String itemId,
    required CreateSandboxTransactionsRequest createSandboxTransactionsRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/sandbox/items/{item_id}/transactions'.replaceAll(
      '{'
      r'item_id'
      '}',
      encodeQueryParameter(
        _serializers,
        itemId,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(CreateSandboxTransactionsRequest);
      _bodyData = _serializers.serialize(
        createSandboxTransactionsRequest,
        specifiedType: _type,
      );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Asks Plaid to fire a webhook for an Item
  /// Calls Plaid&#39;s &#x60;/sandbox/item/fire_webhook&#x60;. The delivery reaches &#x60;POST /webhooks/plaid&#x60; only through a tunnel (PLAN.md §4); with the fake Plaid client it is a no-op. Available when the server&#39;s Plaid mode can drive Sandbox (fake or sandbox); never on a production server, where it is &#x60;409&#x60; &#x60;conflict&#x60;. Another user&#39;s Item is &#x60;404&#x60;; a &#x60;removed&#x60; Item is &#x60;409&#x60; &#x60;conflict&#x60;.
  ///
  /// Parameters:
  /// * [itemId] - The Item's id
  /// * [fireWebhookRequest]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> sandboxFireWebhook({
    required String itemId,
    required FireWebhookRequest fireWebhookRequest,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/sandbox/items/{item_id}/fire-webhook'.replaceAll(
      '{'
      r'item_id'
      '}',
      encodeQueryParameter(
        _serializers,
        itemId,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(FireWebhookRequest);
      _bodyData = _serializers.serialize(
        fireWebhookRequest,
        specifiedType: _type,
      );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Forces an Item into the re-authentication state
  /// Calls Plaid&#39;s &#x60;/sandbox/item/reset_login&#x60;. The Item&#39;s status becomes &#x60;login_required&#x60; (with &#x60;error_code&#x60; &#x60;ITEM_LOGIN_REQUIRED&#x60;) at the latest on its next sync, and update-mode Link repairs it. Available when the server&#39;s Plaid mode can drive Sandbox (fake or sandbox); never on a production server, where it is &#x60;409&#x60; &#x60;conflict&#x60;. Another user&#39;s Item is &#x60;404&#x60;; a &#x60;removed&#x60; Item is &#x60;409&#x60; &#x60;conflict&#x60;.
  ///
  /// Parameters:
  /// * [itemId] - The Item's id
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> sandboxResetLogin({
    required String itemId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/sandbox/items/{item_id}/reset-login'.replaceAll(
      '{'
      r'item_id'
      '}',
      encodeQueryParameter(
        _serializers,
        itemId,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }
}
