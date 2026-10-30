//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'dart:typed_data';

import 'package:api_client/src/api_util.dart';
import 'package:api_client/src/model/problem.dart';
import 'package:api_client/src/model/receipt.dart';
import 'package:api_client/src/model/validation_problem.dart';

class ReceiptsApi {
  final Dio _dio;

  final Serializers _serializers;

  const ReceiptsApi(this._dio, this._serializers);

  /// Returns a receipt photo
  /// The bytes the user stored under &#x60;sha256&#x60;, as &#x60;image/jpeg&#x60; or &#x60;image/png&#x60; by their signature. &#x60;404&#x60; when the user has stored none under it, whoever else has.
  ///
  /// Parameters:
  /// * [sha256] - The SHA-256 of a receipt photo's bytes, lower-case hex
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Uint8List] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Uint8List>> getReceipt({
    required String sha256,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/receipts/{sha256}'.replaceAll(
      '{'
      r'sha256'
      '}',
      encodeQueryParameter(
        _serializers,
        sha256,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'GET',
      responseType: ResponseType.bytes,
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

    Uint8List? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : rawResponse as Uint8List;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Uint8List>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Stores a receipt photo
  /// The photo&#39;s bytes, a JPEG or a PNG of at most 5 MiB (5,242,880 bytes), stored for the calling user under their SHA-256. Content-addressed and idempotent: bytes the user has already stored answer &#x60;200&#x60; without being stored again, so a retry after a lost answer is safe. Bytes that do not hash to the path&#39;s &#x60;sha256&#x60; are &#x60;400&#x60;; more than the cap is &#x60;413&#x60; &#x60;payload_too_large&#x60;; another content type is &#x60;415&#x60; &#x60;unsupported_media_type&#x60;. A device uploads a receipt before it pushes the change that names it in &#x60;Transaction.receipt_sha256&#x60;, so a device that pulls the change can fetch it.
  ///
  /// Parameters:
  /// * [sha256] - The SHA-256 of a receipt photo's bytes, lower-case hex
  /// * [body]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [Receipt] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<Receipt>> putReceipt({
    required String sha256,
    required MultipartFile body,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/receipts/{sha256}'.replaceAll(
      '{'
      r'sha256'
      '}',
      encodeQueryParameter(
        _serializers,
        sha256,
        const FullType(String),
      ).toString(),
    );
    final _options = Options(
      method: r'PUT',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearerAuth'},
        ],
        ...?extra,
      },
      contentType: 'image/jpeg',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = body.finalize();
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

    Receipt? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(Receipt),
            ) as Receipt;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<Receipt>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
