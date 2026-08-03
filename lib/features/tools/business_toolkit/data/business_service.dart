import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:tool_hub/core/api/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GST Master
  Future<List<dynamic>> getGstMaster() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/gst-master');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load GST Master: ${response.statusCode}');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getBusinessAnalytics() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/business-analytics');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load business analytics: ${response.statusCode}');
    }
  }

  // Profit Calculator
  Future<Map<String, dynamic>> calculateProfit({
    required double totalRevenue,
    required double cogs,
    required double operatingExpenses,
    double? taxesPaid,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/profit-calculator');
    final headers = await _getHeaders();
    
    final payload = {
      'total_revenue': totalRevenue,
      'cost_of_goods_sold': cogs,
      'operating_expenses': operatingExpenses,
      'taxes_paid': taxesPaid ?? 0.0,
    };
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate profit: ${response.statusCode}');
    }
  }

  // Sales Tracker
  Future<Map<String, dynamic>> trackSales(List<Map<String, dynamic>> sales) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/sales-tracker');
    final headers = await _getHeaders();
    
    final payload = {'sales': sales};
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to track sales: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getSalesHistory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/sales-tracker/history');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch sales history: ${response.statusCode}');
    }
  }

  // Expense Manager
  Future<Map<String, dynamic>> manageExpenses(List<Map<String, dynamic>> expenses) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/expense-manager');
    final headers = await _getHeaders();
    
    final payload = {'expenses': expenses};
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to manage expenses: ${response.statusCode}');
    }
  }

  // Generic PDF Generator
  Future<String> _generatePdfDocument(String endpoint, Map<String, dynamic> payload, String filenamePrefix) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/$endpoint');
    final headers = await _getHeaders();
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pdfUrl = json['pdf_url'];
      return '${ApiConfig.baseUrl}$pdfUrl';
    } else {
      throw Exception('Failed to generate PDF ($endpoint): ${response.statusCode}');
    }
  }

  // Image Upload
  Future<String> uploadImage(File imageFile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/upload-image');
    final headers = await _getHeaders();
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      final imageUrl = json['url'];
      return '${ApiConfig.baseUrl}$imageUrl';
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }

  // Invoice Generator
  Future<String> generateInvoice(Map<String, dynamic> invoiceData) async {
    return _generatePdfDocument('invoice-generator', invoiceData, 'invoice');
  }

  // GST Billing
  Future<String> generateGstBill(Map<String, dynamic> invoiceData) async {
    return _generatePdfDocument('gst-billing', invoiceData, 'gst_bill');
  }

  // Quotation Gen
  Future<String> generateQuotation(Map<String, dynamic> quoteData) async {
    return _generatePdfDocument('quotation-gen', quoteData, 'quotation');
  }

  // Receipt Gen
  Future<String> generateReceipt(Map<String, dynamic> receiptData) async {
    return _generatePdfDocument('receipt-gen', receiptData, 'receipt');
  }

  // Business Card
  Future<String> generateBusinessCard(Map<String, dynamic> cardData) async {
    return _generatePdfDocument('business-card', cardData, 'business_card');
  }

  // Inventory Manager
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/product');
    final headers = await _getHeaders();
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> lookupProduct(String barcode) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/product/lookup/$barcode');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Product not found: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> addInventory(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/inventory');
    final headers = await _getHeaders();
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add inventory: ${response.body}');
    }
  }

  Future<List<dynamic>> getInventory() async {
    String url = '${ApiConfig.baseUrl}/business-tools/inventory';
    final uri = Uri.parse(url);
    final headers = await _getHeaders();
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['items'] ?? [];
    } else {
      throw Exception('Failed to fetch inventory: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> scanInventory(String barcode) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/inventory/scan/$barcode');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return {'error': 'not_found'};
    } else {
      throw Exception('Failed to scan barcode: ${response.statusCode}');
    }
  }

  Future<String> generateInventoryBarcodes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/inventory/barcodes');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pdfUrl = json['pdf_url'];
      return '${ApiConfig.baseUrl}$pdfUrl';
    } else {
      throw Exception('Failed to generate barcodes: ${response.statusCode}');
    }
  }

  Future<String> generateSingleBarcode(String itemId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/inventory/barcode/$itemId');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pdfUrl = json['pdf_url'];
      return '${ApiConfig.baseUrl}$pdfUrl';
    } else {
      throw Exception('Failed to generate barcode: ${response.statusCode}');
    }
  }

  Future<String> generateInventoryReport() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/inventory/report');
    final headers = await _getHeaders();
    
    final response = await http.get(url, headers: headers);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pdfUrl = json['pdf_url'];
      return '${ApiConfig.baseUrl}$pdfUrl';
    } else {
      throw Exception('Failed to generate inventory report: ${response.statusCode}');
    }
  }

  Future<String> generatePOSCheckout(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/pos-checkout');
    final headers = await _getHeaders();
    
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final pdfUrl = json['pdf_url'];
      return '${ApiConfig.baseUrl}$pdfUrl';
    } else {
      throw Exception('Failed to generate POS receipt: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/profile');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  Future<void> recordPurchaseInvoice(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/purchase-invoice');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));
    if (response.statusCode != 200) {
      throw Exception('Failed to record purchase invoice: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getStockMovements(int productId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/business-tools/stock-movements/$productId');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch stock movements');
    }
  }
}

