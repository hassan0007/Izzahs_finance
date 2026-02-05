class SalesData {
  final String title;
  final double amount;
  final String subtitle;
  final String? badge;

  SalesData({
    required this.title,
    required this.amount,
    required this.subtitle,
    this.badge,
  });
}
