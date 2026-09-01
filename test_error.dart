void main() {
  dynamic x = "hello";
  try {
    print(x['id']);
  } catch(e) {
    print("String indexing: $e");
  }

  dynamic y = [1, 2, 3];
  try {
    print(y['id']);
  } catch(e) {
    print("List indexing: $e");
  }

  Map<String, dynamic> z = {};
  try {
    print(z['id']);
  } catch(e) {
    print("Map indexing: $e");
  }
}
