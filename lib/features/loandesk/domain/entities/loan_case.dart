class LoanCase {
  final String id;
  final String caseNumber;
  final String customerId;
  final String customerName;
  final String loanType;
  final double amount;
  final String status;
  final DateTime applicationDate;
  final Map<String, dynamic>? rawDetails;

  LoanCase({
    required this.id,
    required this.caseNumber,
    required this.customerId,
    required this.customerName,
    required this.loanType,
    required this.amount,
    required this.status,
    required this.applicationDate,
    this.rawDetails,
  });

  factory LoanCase.fromJson(Map<String, dynamic> json) {
    return LoanCase(
      id: json['id'].toString(),
      caseNumber: json['case_number']?.toString() ?? 'N/A',
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? 'Unknown Customer',
      loanType: json['loan_type'] ?? 'Personal Loan',
      amount: double.tryParse((json['requested_amount'] ?? json['amount'] ?? 0.0).toString()) ?? 0.0,
      status: json['status'] ?? 'Draft',
      applicationDate: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      rawDetails: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_number': caseNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'loan_type': loanType,
      'amount': amount,
      'status': status,
      'created_at': applicationDate.toIso8601String(),
    };
  }

  LoanCase copyWith({
    String? id,
    String? caseNumber,
    String? customerId,
    String? customerName,
    String? loanType,
    double? amount,
    String? status,
    DateTime? applicationDate,
    Map<String, dynamic>? rawDetails,
  }) {
    return LoanCase(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      loanType: loanType ?? this.loanType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      rawDetails: rawDetails ?? this.rawDetails,
    );
  }
}
