class DocumentRequirement {
  final String id;
  final String name;
  final String status; // "Missing", "Processing", "Received"
  final String? fileUrl;

  DocumentRequirement({
    required this.id,
    required this.name,
    required this.status,
    this.fileUrl,
  });

  DocumentRequirement copyWith({
    String? id,
    String? name,
    String? status,
    String? fileUrl,
  }) {
    return DocumentRequirement(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }
}
