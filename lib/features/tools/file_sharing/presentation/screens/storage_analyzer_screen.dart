import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:go_router/go_router.dart';
import 'package:tool_hub/core/theme/app_text_styles.dart';
import 'package:tool_hub/core/widgets/neo_card.dart';
import '../providers/file_tools_providers.dart';
import 'package:disk_space_2/disk_space_2.dart';

class StorageAnalyzerScreen extends ConsumerStatefulWidget {
  const StorageAnalyzerScreen({super.key});

  @override
  ConsumerState<StorageAnalyzerScreen> createState() => _StorageAnalyzerScreenState();
}

class _StorageAnalyzerScreenState extends ConsumerState<StorageAnalyzerScreen> {
  // Device Storage State
  double? _totalDiskSpace;
  double? _freeDiskSpace;
  bool _isDeviceStorageLoading = true;

  // File Analysis State
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceStorage();
  }

  Future<void> _loadDeviceStorage() async {
    try {
      final total = await DiskSpace.getTotalDiskSpace;
      final free = await DiskSpace.getFreeDiskSpace;
      setState(() {
        _totalDiskSpace = total;
        _freeDiskSpace = free;
        _isDeviceStorageLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDeviceStorageLoading = false;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );
      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
          _analysisResult = null;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick files: $e';
      });
    }
  }

  Future<void> _executeAction() async {
    if (_selectedFiles.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _analysisResult = null;
    });

    try {
      final service = ref.read(fileToolsServiceProvider);
      
      final xfiles = _selectedFiles.map((f) => XFile(f.path!)).toList();
      final result = await service.analyzeStorage(xfiles);
      
      setState(() {
        _isLoading = false;
        _analysisResult = result;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatMb(double? mb) {
    if (mb == null) return 'Unknown';
    if (mb > 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFFF4D4D);
    
    double usedSpaceMb = 0;
    double totalSpaceMb = 0;
    double percentage = 0.0;
    
    if (_totalDiskSpace != null && _freeDiskSpace != null) {
      totalSpaceMb = _totalDiskSpace!;
      usedSpaceMb = _totalDiskSpace! - _freeDiskSpace!;
      percentage = totalSpaceMb > 0 ? (usedSpaceMb / totalSpaceMb) : 0;
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Storage Analyzer', style: AppTextStyles.heroTitle.copyWith(fontSize: 20, color: Colors.white)),
        backgroundColor: primaryRed,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            
            // Device Storage Overview (From Screenshot)
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('Device Storage Overview', style: AppTextStyles.heroTitle.copyWith(fontSize: 18)),
                  const SizedBox(height: 40),
                  
                  if (_isDeviceStorageLoading)
                    const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: primaryRed)),
                    )
                  else
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 20,
                            backgroundColor: Colors.grey[200],
                            color: primaryRed,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Used',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  _buildStatCard('Total Space', _formatMb(_totalDiskSpace), Colors.grey[200]!, Colors.black),
                  const SizedBox(height: 16),
                  _buildStatCard('Used Space', _formatMb(usedSpaceMb), const Color(0xFFFFEBEB), primaryRed),
                  const SizedBox(height: 16),
                  _buildStatCard('Free Space', _formatMb(_freeDiskSpace), const Color(0xFFEAF9E6), Colors.green),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // How to Use Box
            NeoCard(
              backgroundColor: const Color(0xFFE0FBFC),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('How to analyze files', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "1. Tap 'Select Files' to choose the files you want to analyze.\n"
                    "2. Tap 'Analyze Storage' to send them to the backend.\n"
                    "3. View the detailed breakdown by category and individual file sizes below.", 
                    style: AppTextStyles.bodyText.copyWith(fontSize: 14)
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Choose File & Analyze Card
            NeoCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_rounded, size: 64, color: primaryRed),
                  const SizedBox(height: 16),
                  Text('Analyze File Storage', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('Get a detailed breakdown of the selected files.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFiles,
                      icon: const Icon(Icons.folder_open_rounded, color: Colors.black),
                      label: Text(_selectedFiles.isEmpty ? 'Select Files' : '${_selectedFiles.length} File(s) Selected', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedFiles.isEmpty || _isLoading ? null : _executeAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedFiles.isEmpty ? Colors.grey[300] : primaryRed,
                        foregroundColor: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text('Analyze Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedFiles.isEmpty ? Colors.grey[500] : Colors.white)),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            
            // Results Card
            if (_analysisResult != null) ...[
              const SizedBox(height: 20),
              NeoCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Builder(
                  builder: (context) {
                    final breakdown = _analysisResult!['breakdown'] as Map<String, dynamic>;
                    
                    int photosCount = 0, photosSize = 0;
                    int docsCount = 0, docsSize = 0;
                    int appsCount = 0, appsSize = 0;
                    int othersCount = 0, othersSize = 0;
                    
                    final photosExts = ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi', 'mkv', 'webp', 'heic'];
                    final docsExts = ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'];
                    final appsExts = ['apk', 'aab', 'exe', 'ipa'];

                    for (final entry in breakdown.entries) {
                      final ext = entry.key.toLowerCase();
                      final count = entry.value['count'] as int;
                      final size = entry.value['size_bytes'] as int;
                      
                      if (photosExts.contains(ext)) {
                        photosCount += count;
                        photosSize += size;
                      } else if (docsExts.contains(ext)) {
                        docsCount += count;
                        docsSize += size;
                      } else if (appsExts.contains(ext)) {
                        appsCount += count;
                        appsSize += size;
                      } else {
                        othersCount += count;
                        othersSize += size;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detailed Breakdown', style: AppTextStyles.heroTitle.copyWith(fontSize: 20)),
                        const SizedBox(height: 24),
                        _buildStatCard('Total Files Analyzed', '${_analysisResult!['total_files']}', Colors.grey[200]!, Colors.black),
                        const SizedBox(height: 12),
                        _buildStatCard('Selected Size', _formatBytes(_analysisResult!['total_size_bytes'] ?? 0), const Color(0xFFFFEBEB), primaryRed),
                        const SizedBox(height: 24),
                        const Divider(color: Colors.black, thickness: 2),
                        const SizedBox(height: 16),
                        Text('Categorized Breakdown:', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: 16),
                        
                        if (photosCount > 0) ...[
                          _buildStatCard('Photos & Videos', '$photosCount files, ${_formatBytes(photosSize)}', Colors.blue[50]!, Colors.blue),
                          const SizedBox(height: 12),
                        ],
                        if (appsCount > 0) ...[
                          _buildStatCard('Apps & Games', '$appsCount files, ${_formatBytes(appsSize)}', Colors.orange[50]!, Colors.orange),
                          const SizedBox(height: 12),
                        ],
                        if (docsCount > 0) ...[
                          _buildStatCard('Documents', '$docsCount files, ${_formatBytes(docsSize)}', Colors.purple[50]!, Colors.purple),
                          const SizedBox(height: 12),
                        ],
                        if (othersCount > 0) ...[
                          _buildStatCard('System Files / Others', '$othersCount files, ${_formatBytes(othersSize)}', Colors.grey[200]!, Colors.black),
                          const SizedBox(height: 12),
                        ],
                        
                        const SizedBox(height: 12),
                        const Divider(color: Colors.black, thickness: 2),
                        const SizedBox(height: 16),
                        Text('Individual File Sizes:', style: AppTextStyles.sectionTitle.copyWith(fontSize: 16)),
                        const SizedBox(height: 16),
                        
                        ..._selectedFiles.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildStatCard(
                            f.name, 
                            _formatBytes(f.size), 
                            Colors.white, 
                            Colors.black
                          ),
                        )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor)),
        ],
      ),
    );
  }
}
