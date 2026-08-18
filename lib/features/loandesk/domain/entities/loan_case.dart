class LoanCase {
  final String id;
  final String customerId;
  final String customerName;
  final String loanType;
  final double amount;
  final String status;
  final DateTime applicationDate;

  LoanCase({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.loanType,
    required this.amount,
    required this.status,
    required this.applicationDate,
  });

  LoanCase copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? loanType,
    double? amount,
    String? status,
    DateTime? applicationDate,
  }) {
    return LoanCase(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      loanType: loanType ?? this.loanType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
    );
  }
}
