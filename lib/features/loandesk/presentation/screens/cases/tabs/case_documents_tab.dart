import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart';
import '../../../../domain/entities/loan_case.dart';
import '../../../../domain/entities/document_requirement.dart';
import '../../../theme/loandesk_theme.dart';
import '../../../widgets/neo_card.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/loan_case_provider.dart';
import '../../../../data/repositories/document_repository.dart';

class CaseDocumentsTab extends ConsumerStatefulWidget {
  final LoanCase loanCase;

  const CaseDocumentsTab({super.key, required this.loanCase});

  @override
  ConsumerState<CaseDocumentsTab> createState() => _CaseDocumentsTabState();
}

class _CaseDocumentsTabState extends ConsumerState<CaseDocumentsTab> {
  String? _uploadingDocId;

  Future<void> _checkAndUpdateCaseStatus() async {
    final docs = ref.read(documentProvider(widget.loanCase.id)).valueOrNull ?? [];
    if (docs.any((d) => d.status == 'Uploaded' || d.fileName != null)) {
      if (!['IN PROGRESS', 'UNDER VERIFICATION', 'VERIFIED', 'APPROVED', 'REJECTED'].contains(widget.loanCase.status.toUpperCase())) {
        try {
          await ref.read(loanCaseProvider.notifier).updateCaseStatus(widget.loanCase.id, 'In Progress');
        } catch (_) {}
      }
    }
  }

  Future<CroppedFile?> _cropImage(String path) async {
    return await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: LoanDeskTheme.primaryBlue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Crop Document',
        ),
      ],
    );
  }

  Future<void> _capturePhoto(DocumentRequirement doc) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final cropped = await _cropImage(photo.path);
        if (cropped == null) return; // User cancelled crop

        setState(() {
          _uploadingDocId = doc.id;
        });

        final fileBytes = await cropped.readAsBytes();
        final repository = ref.read(documentRepositoryProvider);
        
        await repository.uploadDocument(
          caseId: widget.loanCase.id,
          documentType: doc.name,
          filePath: cropped.path,
          fileBytes: fileBytes,
          fileName: photo.name,
        );

        // Optimistically update
        ref.read(documentProvider(widget.loanCase.id).notifier).updateDocumentStatus(
          doc.id, 
          'Uploaded', 
          fileName: photo.name,
        );
        
        // Refresh from server
        await ref.read(documentProvider(widget.loanCase.id).notifier).refreshDocuments();
        await _checkAndUpdateCaseStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: LoanDeskTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingDocId = null;
        });
      }
    }
  }

  void _showCameraDisclosure(BuildContext context, DocumentRequirement doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: LoanDeskTheme.borderWidth),
          ),
          title: const Text('Camera Access', style: TextStyle(fontWeight: FontWeight.w900, color: LoanDeskTheme.primaryBlack)),
          content: const Text(
            'We need access to your camera to securely capture pictures of your documents for the loan application. The captured photos will only be used for verification purposes.',
            style: TextStyle(height: 1.5, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LoanDeskTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: 2),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _capturePhoto(doc);
              },
              child: const Text('Allow & Open', style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  void _showUploadOptions(BuildContext context, DocumentRequirement doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload, color: LoanDeskTheme.primaryBlue),
                title: const Text('Upload from Files/Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(doc);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: LoanDeskTheme.primaryBlue),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _showCameraDisclosure(context, doc);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFile(DocumentRequirement doc) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'xlsx', 'xls'],
      );

      if (result != null) {
        final file = result.files.single;
        String filePath = file.path ?? '';
        Uint8List? fileBytes = file.bytes;
        String fileName = file.name;

        final extension = file.extension?.toLowerCase();
        final isImage = extension == 'jpg' || extension == 'jpeg' || extension == 'png';
        
        if (isImage && filePath.isNotEmpty) {
          final cropped = await _cropImage(filePath);
          if (cropped == null) return; // User cancelled
          filePath = cropped.path;
          fileBytes = await cropped.readAsBytes();
        }

        setState(() {
          _uploadingDocId = doc.id;
        });

        final repository = ref.read(documentRepositoryProvider);
        
        await repository.uploadDocument(
          caseId: widget.loanCase.id,
          documentType: doc.name,
          filePath: filePath.isNotEmpty ? filePath : null,
          fileBytes: fileBytes,
          fileName: fileName,
        );

        // Optimistically update
        ref.read(documentProvider(widget.loanCase.id).notifier).updateDocumentStatus(
          doc.id, 
          'Uploaded', 
          fileName: fileName,
        );
        
        // Refresh from server
        await ref.read(documentProvider(widget.loanCase.id).notifier).refreshDocuments();
        await _checkAndUpdateCaseStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: LoanDeskTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingDocId = null;
        });
      }
    }
  }

  void _removeFile(DocumentRequirement doc) {
    // Note: Backend might not support deletion out of the box based on current routes, 
    // so we just reset locally for now. Real implementation should call a DELETE route.
    ref.read(documentProvider(widget.loanCase.id).notifier).updateDocumentStatus(
      doc.id, 
      'Pending', 
      fileName: null,
      fileUrl: null,
    );
  }

  void _viewDocument(DocumentRequirement doc) {
    if (doc.fileUrl != null) {
      // fileUrl holds the document ID based on our provider mapping
      context.push('/loandesk/cases/document-preview/${doc.fileUrl}?name=${Uri.encodeComponent(doc.fileName ?? doc.name)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentProvider(widget.loanCase.id));

    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: LoanDeskTheme.primaryBlue)),
      error: (error, stack) => Center(
        child: Text('Error loading documents: $error', style: const TextStyle(color: LoanDeskTheme.primaryRed)),
      ),
      data: (documents) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Document Upload and Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: LoanDeskTheme.primaryBlack,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              NeoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: LoanDeskTheme.primaryBlack,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                          topRight: Radius.circular(LoanDeskTheme.borderRadius - LoanDeskTheme.borderWidth),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Document Type', style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900))),
                          Expanded(flex: 4, child: Text('File Name', style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900))),
                          Expanded(flex: 2, child: Text('Status', style: TextStyle(color: LoanDeskTheme.primaryWhite, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                    
                    // Table Rows
                    ...documents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doc = entry.value;
                      final isLast = index == documents.length - 1;
                      final isUploading = _uploadingDocId == doc.id;
                      
                      return Container(
                        decoration: BoxDecoration(
                          border: isLast ? null : const Border(bottom: BorderSide(color: LoanDeskTheme.primaryBlack, width: 1)),
                          color: index.isEven ? LoanDeskTheme.primaryWhite : const Color(0xFFF8F9FA),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Document Type
                            Expanded(
                              flex: 3,
                              child: Text(
                                doc.name,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                            
                            // File Name / Action
                            Expanded(
                              flex: 4,
                              child: isUploading 
                                  ? const Row(
                                      children: [
                                        SizedBox(
                                          width: 16, 
                                          height: 16, 
                                          child: CircularProgressIndicator(strokeWidth: 2, color: LoanDeskTheme.primaryBlue)
                                        ),
                                        SizedBox(width: 8),
                                        Text('Uploading...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: LoanDeskTheme.primaryBlue)),
                                      ],
                                    )
                                  : doc.status == 'Uploaded' && doc.fileName != null
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            doc.fileName!,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: LoanDeskTheme.primaryBlue),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_red_eye, size: 18, color: LoanDeskTheme.primaryBlue),
                                          onPressed: () => _viewDocument(doc),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'View Document',
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: LoanDeskTheme.primaryRed),
                                          onPressed: () => _removeFile(doc),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () => _showUploadOptions(context, doc),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: LoanDeskTheme.primaryYellow,
                                            border: Border.all(color: LoanDeskTheme.primaryBlack, width: 1.5),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: const [
                                              BoxShadow(color: LoanDeskTheme.primaryBlack, offset: Offset(2, 2)),
                                            ],
                                          ),
                                          child: const Text(
                                            'Choose File',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            
                            // Status
                            Expanded(
                              flex: 2,
                              child: Text(
                                doc.status,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: doc.status == 'Uploaded' ? LoanDeskTheme.primaryGreen : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Text(
                '*Note: Supported formats PDF/JPG/PNG/Excel*',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              if (!['APPROVED', 'REJECTED'].contains(widget.loanCase.status.toUpperCase()))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LoanDeskTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: LoanDeskTheme.primaryBlack, width: 2),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await ref.read(loanCaseProvider.notifier).updateCaseStatus(widget.loanCase.id, 'Under Verification');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Case submitted for verification!'),
                                backgroundColor: LoanDeskTheme.primaryGreen,
                              ),
                            );
                            context.pop(); // Go back to workspace or cases
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: LoanDeskTheme.primaryRed),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Submit for Verification',
                        style: TextStyle(
                          color: LoanDeskTheme.primaryWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
