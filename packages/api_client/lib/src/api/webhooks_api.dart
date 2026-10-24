//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/validation_problem.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';

class WebhooksApi {
  final Dio _dio;

  final Serializers _serializers;

  const WebhooksApi(this._dio, this._serializers);

  /// Receives a Plaid webhook delivery
  /// Verifies the &#x60;Plaid-Verification&#x60; JWT (key from &#x60;/webhook_verification_key/get&#x60;, body hash, freshness) before processing. An unverified delivery is &#x60;401&#x60; &#x60;webhook_unverified&#x60; and is never processed (PLAN.md §6.5).
  ///
  /// Parameters:
  /// * [plaidVerification] - The JWT Plaid signs each delivery with
  /// * [requestBody]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> receivePlaidWebhook({
    required String plaidVerification,
    required BuiltMap<String, JsonObject> requestBody,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/webhooks/plaid';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'Plaid-Verification': plaidVerification,
        ...?headers,
      },
      extra: <String, dynamic>{'secure': <Map<String, String>>[], ...?extra},
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(BuiltMap, [
        FullType(String),
        FullType(JsonObject),
      ]);
      _bodyData = _serializers.serialize(requestBody, specifiedType: _type);
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
}
