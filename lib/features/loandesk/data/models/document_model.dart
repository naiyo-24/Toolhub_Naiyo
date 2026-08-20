class DocumentModel {
  final int id;
  final int caseId;
  final String documentType;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final String storageKey;
  final int createdBy;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.caseId,
    required this.documentType,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    required this.storageKey,
    required this.createdBy,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      caseId: json['case_id'],
      documentType: json['document_type'],
      fileName: json['file_name'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
      storageKey: json['storage_key'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'document_type': documentType,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'storage_key': storageKey,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
