import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/document_requirement.dart';
import '../../data/repositories/document_repository.dart';

final documentProvider = AsyncNotifierProviderFamily<DocumentNotifier, List<DocumentRequirement>, String>(
  DocumentNotifier.new,
);

class DocumentNotifier extends FamilyAsyncNotifier<List<DocumentRequirement>, String> {
  final List<DocumentRequirement> _baseRequirements = [
    DocumentRequirement(id: 'DOC-1', name: 'PAN Card', status: 'Pending'),
    DocumentRequirement(id: 'DOC-2', name: 'GST Certificate', status: 'Pending'),
    DocumentRequirement(id: 'DOC-3', name: 'Udyam Certificate', status: 'Pending'),
    DocumentRequirement(id: 'DOC-4', name: 'ITR', status: 'Pending'),
    DocumentRequirement(id: 'DOC-5', name: 'Bank Statement', status: 'Pending'),
    DocumentRequirement(id: 'DOC-6', name: 'P&L Statement', status: 'Pending'),
    DocumentRequirement(id: 'DOC-7', name: 'Address Proof', status: 'Pending'),
    DocumentRequirement(id: 'DOC-8', name: 'Other Document', status: 'Pending'),
  ];

  @override
  Future<List<DocumentRequirement>> build(String arg) async {
    return _fetchDocuments();
  }

  Future<List<DocumentRequirement>> _fetchDocuments() async {
    try {
      final repository = ref.read(documentRepositoryProvider);
      final uploadedDocs = await repository.getCaseDocuments(arg);

      // Merge base requirements with uploaded documents
      return _baseRequirements.map((req) {
        final matchingDocs = uploadedDocs.where((d) => d.documentType == req.name);
        if (matchingDocs.isNotEmpty) {
          final uploadedDoc = matchingDocs.first; // Or handle multiple versions
          return req.copyWith(
            status: 'Uploaded',
            fileName: uploadedDoc.fileName,
            fileUrl: uploadedDoc.id.toString(), // We store the document ID here for easy access later
          );
        }
        return req;
      }).toList();
    } catch (e) {
      // Return base requirements as fallback if network fails
      return _baseRequirements;
    }
  }

  Future<void> refreshDocuments() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDocuments());
  }

  // Fallback for immediate optimistic update
  void updateDocumentStatus(String docId, String newStatus, {String? fileUrl, String? fileName}) {
    if (state.hasValue) {
      state = AsyncData([
        for (final doc in state.value!)
          if (doc.id == docId)
            doc.copyWith(
              status: newStatus,
              fileUrl: fileUrl ?? doc.fileUrl,
              fileName: fileName ?? doc.fileName,
            )
          else
            doc
      ]);
    }
  }
}
