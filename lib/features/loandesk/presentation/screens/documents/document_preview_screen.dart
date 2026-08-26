import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tool_hub/features/loandesk/presentation/theme/loandesk_theme.dart';
import 'package:tool_hub/core/api/api_config.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final int documentId;
  final String fileName;

  const DocumentPreviewScreen({
    super.key,
    required this.documentId,
    required this.fileName,
  });

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  bool get _isPdf => widget.fileName.toLowerCase().endsWith('.pdf');
  bool get _isImage => 
    widget.fileName.toLowerCase().endsWith('.jpg') || 
    widget.fileName.toLowerCase().endsWith('.jpeg') || 
    widget.fileName.toLowerCase().endsWith('.png');

  String get _downloadUrl => '${ApiConfig.baseUrl}/documents/download/${widget.documentId}';

  Map<String, String>? _headers;
  bool _isLoadingHeaders = true;

  @override
  void initState() {
    super.initState();
    _loadAuthHeaders();
  }

  Future<void> _loadAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (mounted) {
      setState(() {
        if (token != null) {
          _headers = {'Authorization': 'Bearer $token'};
        }
        _isLoadingHeaders = false;
      });
    }
  }

  Future<void> _downloadFile() async {
    final Uri url = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch download URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoanDeskTheme.background,
      appBar: AppBar(
        title: Text(widget.fileName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: LoanDeskTheme.primaryWhite,
        foregroundColor: LoanDeskTheme.primaryBlack,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadFile,
            tooltip: 'Download',
          ),
        ],
      ),
      body: _isLoadingHeaders
          ? const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlue))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_headers == null) {
      return const Center(child: Text('Authentication required to view document.'));
    }

    if (_isPdf) {
      return FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 300)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlue));
          }
          return SfPdfViewer.network(
            _downloadUrl,
            headers: _headers,
            canShowScrollHead: false,
            canShowScrollStatus: false,
          );
        }
      );
    } else if (_isImage) {
      return Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            _downloadUrl,
            headers: _headers,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                  color: LoanDeskTheme.primaryBlue,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.black38),
                    SizedBox(height: 16),
                    Text('Failed to load image', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 80, color: Colors.black38),
            const SizedBox(height: 24),
            const Text(
              'Preview not available for this file type.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _downloadFile,
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LoanDeskTheme.primaryBlue,
                foregroundColor: LoanDeskTheme.primaryWhite,
              ),
            ),
          ],
        ),
      );
    }
  }
}
