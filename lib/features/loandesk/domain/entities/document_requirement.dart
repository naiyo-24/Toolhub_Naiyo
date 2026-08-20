class DocumentRequirement {
  final String id;
  final String name;
  final String status; // "Missing", "Processing", "Received", "Pending", "Uploaded"
  final String? fileUrl;
  final String? fileName;

  DocumentRequirement({
    required this.id,
    required this.name,
    required this.status,
    this.fileUrl,
    this.fileName,
  });

  DocumentRequirement copyWith({
    String? id,
    String? name,
    String? status,
    String? fileUrl,
    String? fileName,
  }) {
    return DocumentRequirement(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
    );
  }
}
