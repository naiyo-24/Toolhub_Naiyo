import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/document_requirement.dart';

// Maps a case ID to a list of its required documents
final documentProvider = StateNotifierProvider.family<DocumentNotifier, List<DocumentRequirement>, String>((ref, caseId) {
  return DocumentNotifier(caseId);
});

class DocumentNotifier extends StateNotifier<List<DocumentRequirement>> {
  final String caseId;

  DocumentNotifier(this.caseId) : super([]) {
    // Seed mock data for this specific case
    state = [
      DocumentRequirement(id: 'DOC-1', name: 'PAN Card', status: 'Received'),
      DocumentRequirement(id: 'DOC-2', name: 'GST Certificate', status: 'Received'),
      DocumentRequirement(id: 'DOC-3', name: 'Udyam Registration', status: 'Received'),
      DocumentRequirement(id: 'DOC-4', name: 'Bank Statement (6 Months)', status: 'Processing'),
      DocumentRequirement(id: 'DOC-5', name: 'IT Returns (Last 2 Years)', status: 'Missing'),
      DocumentRequirement(id: 'DOC-6', name: 'Address Proof', status: 'Missing'),
    ];
  }

  void updateDocumentStatus(String docId, String newStatus, {String? fileUrl}) {
    state = [
      for (final doc in state)
        if (doc.id == docId)
          doc.copyWith(status: newStatus, fileUrl: fileUrl ?? doc.fileUrl)
        else
          doc
    ];
  }
}
