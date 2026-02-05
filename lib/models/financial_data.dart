class FinancialData {
  final String title;
  final double amount;
  final String status;
  final String? badge;

  FinancialData({
    required this.title,
    required this.amount,
    required this.status,
    this.badge,
  });
}
