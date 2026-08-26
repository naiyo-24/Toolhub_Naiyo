import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../domain/entities/loan_case.dart';
import '../../../../../core/api/api_config.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

class CaseSummaryPdfScreen extends ConsumerWidget {
  final LoanCase loanCase;

  const CaseSummaryPdfScreen({super.key, required this.loanCase});

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<void> _downloadAndOpenReport(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading PDF Report...')));
    try {
      final token = await _getToken();
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/Case_Report_${loanCase.caseNumber}.pdf';
      
      final dio = Dio();
      if (token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      await dio.download(
        '${ApiConfig.loanDeskBaseUrl}/cases/${loanCase.id}/download-report',
        filePath,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report downloaded successfully!')));
      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download report: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: If you face a 404 here for viewing, you might need to update this URL as well.
    final String pdfUrl = '${ApiConfig.loanDeskBaseUrl}/cases/${loanCase.id}/download-report';

    return Scaffold(
      appBar: AppBar(
        title: Text('CAM Report: ${loanCase.customerName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: "Download PDF",
            onPressed: () => _downloadAndOpenReport(context),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final token = snapshot.data ?? '';
          return SfPdfViewer.network(
            pdfUrl,
            headers: {
              'Authorization': 'Bearer $token',
            },
          );
        },
      ),
    );
  }
}
