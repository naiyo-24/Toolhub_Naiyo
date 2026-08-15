import 'package:isar/isar.dart';

part 'folder_model.g.dart';

@collection
class Folder {
  Id id = Isar.autoIncrement;

  late String name;
  
  String? parentFolderId;
  String? color;
  
  late DateTime createdAt;
}
