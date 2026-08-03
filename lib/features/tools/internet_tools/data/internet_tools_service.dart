import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class InternetToolsService {
  final Dio _dio;

  InternetToolsService() : _dio = ApiClient().dio;

  Future<Map<String, dynamic>> shortenUrl(String url) async {
    final response = await _dio.post('/internet-tools/url/shorten', data: {'url': url});
    return response.data;
  }

  Future<Map<String, dynamic>> expandUrl(String shortUrl) async {
    final response = await _dio.post('/internet-tools/url/expand', data: {'short_url': shortUrl});
    return response.data;
  }

  Future<Map<String, dynamic>> checkLink(String url) async {
    final response = await _dio.post('/internet-tools/link/check', data: {'url': url});
    return response.data;
  }

  Future<Map<String, dynamic>> validateEmail(String email) async {
    final response = await _dio.post('/internet-tools/email/validate', data: {'email': email});
    return response.data;
  }

  Future<Map<String, dynamic>> lookupIp([String? ip]) async {
    final query = ip != null && ip.isNotEmpty ? '?ip=$ip' : '';
    final response = await _dio.get('/internet-tools/ip/lookup$query');
    return response.data;
  }

  Future<Map<String, dynamic>> checkWebsiteStatus(String url) async {
    final response = await _dio.post('/internet-tools/website/status', data: {'url': url});
    return response.data;
  }

  Future<Map<String, dynamic>> lookupDns(String domain) async {
    final response = await _dio.post('/internet-tools/dns/lookup', data: {'domain': domain});
    return response.data;
  }

  Future<Map<String, dynamic>> pingTest(String host) async {
    final response = await _dio.post('/internet-tools/ping', data: {'host': host});
    return response.data;
  }

  Future<Map<String, dynamic>> runSpeedTest() async {
    final response = await _dio.get(
      '/internet-tools/speedtest',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> formatJson(String jsonString) async {
    final response = await _dio.post('/internet-tools/json/format', data: {'json_string': jsonString});
    return response.data;
  }

  Future<Map<String, dynamic>> processBase64(String text, String action) async {
    final response = await _dio.post('/internet-tools/base64/process', data: {'text': text, 'action': action});
    return response.data;
  }

  Future<Uint8List> generateWifiQr(String ssid, String password, String encryption, {String fillColor = "#000000", String backColor = "#FFFFFF"}) async {
    final response = await _dio.post(
      '/internet-tools/qr/wifi',
      data: {
        'ssid': ssid,
        'password': password,
        'encryption': encryption,
        'fill_color': fillColor,
        'back_color': backColor,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> generateUpiQr(String vpa, String name, String? amount, {String fillColor = "#000000", String backColor = "#FFFFFF"}) async {
    final response = await _dio.post(
      '/internet-tools/qr/upi',
      data: {
        'vpa': vpa,
        'name': name,
        'amount': amount,
        'fill_color': fillColor,
        'back_color': backColor,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  Future<Uint8List> captureScreenshot(String url) async {
    final response = await _dio.get(
      '/internet-tools/screenshot?url=$url',
      options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 30)),
    );
    return Uint8List.fromList(response.data);
  }
}
