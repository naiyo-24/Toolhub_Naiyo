import 'package:isar/isar.dart';

part 'document_model.g.dart';

@collection
class Document {
  Id id = Isar.autoIncrement;

  late String name;
  late String pdfPath;
  late String thumbnailPath;

  String? folderId;
  String? ocrText;

  late int pageCount;
  late int fileSize;

  late DateTime createdAt;
  late DateTime updatedAt;

  bool isFavorite = false;
}
