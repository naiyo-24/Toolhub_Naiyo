import 'dart:convert';
void main() {
  Map<String, dynamic> json = {'created_at': null, 'updated_at': ""};
  try {
    print(DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()));
  } catch(e) {
    print("created_at error: $e");
  }
  
  try {
    print(DateTime.parse(json['updated_at']?.toString() ?? DateTime.now().toIso8601String()));
  } catch(e) {
    print("updated_at error: $e");
  }

  Map<String, dynamic> json2 = jsonDecode('{"created_at": null, "updated_at": null}');
  try {
    print("from decode: ${json2['updated_at']?.toString()}");
    print(DateTime.parse(json2['updated_at']?.toString() ?? DateTime.now().toIso8601String()));
  } catch(e) {
    print("json2 updated_at error: $e");
  }
}
