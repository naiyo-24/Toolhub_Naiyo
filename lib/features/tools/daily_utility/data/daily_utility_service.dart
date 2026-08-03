import 'package:dio/dio.dart';
import 'package:tool_hub/core/api/api_client.dart';
import 'package:flutter/foundation.dart';

import 'dart:typed_data';

class DailyUtilityService {
  final Dio _dio;

  DailyUtilityService() : _dio = ApiClient().dio;

  // Calculators
  Future<Map<String, dynamic>> calculateEmi({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) async {
    final response = await _dio.post('/daily-utility/emi', data: {
      'principal': principal,
      'annual_rate': annualRate,
      'tenure_months': tenureMonths,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateGst({
    required double amount,
    required double gstRate,
    required bool isInclusive,
  }) async {
    final response = await _dio.post('/daily-utility/gst', data: {
      'amount': amount,
      'gst_rate': gstRate,
      'is_inclusive': isInclusive,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateSip({
    required double monthlyInvestment,
    required double expectedAnnualReturn,
    required int tenureYears,
  }) async {
    final response = await _dio.post('/daily-utility/sip', data: {
      'monthly_investment': monthlyInvestment,
      'expected_annual_return': expectedAnnualReturn,
      'tenure_years': tenureYears,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateLoan({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) async {
    final response = await _dio.post('/daily-utility/loan', data: {
      'principal': principal,
      'annual_rate': annualRate,
      'tenure_months': tenureMonths,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateDiscount({
    required double originalPrice,
    required double discountPercentage,
  }) async {
    final response = await _dio.post('/daily-utility/discount', data: {
      'original_price': originalPrice,
      'discount_percentage': discountPercentage,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateAge(String birthDate) async {
    final response = await _dio.post('/daily-utility/age', data: {
      'birth_date': birthDate,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculateBmi({
    required double weightKg,
    required double heightCm,
    int? age,
  }) async {
    final response = await _dio.post('/daily-utility/bmi', data: {
      'weight_kg': weightKg,
      'height_cm': heightCm,
      if (age != null) 'age': age,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> calculatePercentage(double part, double total) async {
    final response = await _dio.post('/daily-utility/percentage', queryParameters: {
      'part': part,
      'total': total,
    });
    return response.data;
  }

  // Converters
  Future<Map<String, dynamic>> convertUnit(double value, String fromUnit, String toUnit) async {
    final response = await _dio.post('/daily-utility/convert/unit', queryParameters: {
      'value': value,
      'from_unit': fromUnit,
      'to_unit': toUnit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> convertCurrency(double amount, String fromCurrency, String toCurrency) async {
    final response = await _dio.post('/daily-utility/convert/currency', queryParameters: {
      'amount': amount,
      'from_currency': fromCurrency,
      'to_currency': toCurrency,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> convertBinDec(String value, int fromBase, int toBase) async {
    final response = await _dio.post('/daily-utility/convert/bindec', data: {
      'value': value,
      'from_base': fromBase,
      'to_base': toBase,
    });
    return response.data;
  }

  // Text & Security
  Future<Map<String, dynamic>> generatePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    String? customChars,
  }) async {
    final response = await _dio.post('/daily-utility/password/generate', data: {
      'length': length,
      'include_uppercase': includeUppercase,
      'include_lowercase': includeLowercase,
      'include_numbers': includeNumbers,
      'include_symbols': includeSymbols,
      'custom_chars': customChars,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkPasswordStrength(String password) async {
    final response = await _dio.post('/daily-utility/password/check', data: {
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> countText(String text) async {
    final response = await _dio.post('/daily-utility/text/counter', data: {
      'text': text,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> convertCase(String text, String caseType) async {
    final response = await _dio.post('/daily-utility/text/case', data: {
      'text': text,
      'case_type': caseType,
    });
    return response.data;
  }

  // Scanners / Generators
  Future<Uint8List> generateQr({
    required String qrType,
    required String data,
    Map<String, dynamic>? qrData,
    String fillColor = '#000000',
    String backColor = '#ffffff',
    String borderColor = '#000000',
    int borderWidth = 0,
    String? logoBase64,
  }) async {
    final response = await _dio.post(
      '/daily-utility/qr/generate',
      data: {
        'qr_type': qrType,
        'data': data,
        'qr_data': qrData ?? {},
        'fill_color': fillColor,
        'back_color': backColor,
        'border_color': borderColor,
        'border_width': borderWidth,
        if (logoBase64 != null) 'logo_base64': logoBase64,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> scanQr(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/daily-utility/qr/scan', data: formData);
    return response.data;
  }

  Future<Uint8List> generateBarcode({
    required String data,
    String barcodeType = 'code128',
  }) async {
    final response = await _dio.post(
      '/daily-utility/barcode/generate',
      data: {
        'data': data,
        'barcode_type': barcodeType,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> scanBarcode(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/daily-utility/barcode/scan', data: formData);
    return response.data;
  }
}
