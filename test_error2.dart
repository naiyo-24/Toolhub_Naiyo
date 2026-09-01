class Customer {
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer();
  }
  Customer();
}
void main() {
  List<dynamic> data = [ [1, 2, 3] ];
  try {
    data.map((json) => Customer.fromJson(json)).toList();
  } catch(e) {
    print("Map call: $e");
  }
}
