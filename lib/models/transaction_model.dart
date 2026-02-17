import 'package:intl/intl.dart';

class TransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String paymentType;
  final int timestamp;

  TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.paymentType,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return TransactionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentType: map['paymentType'] ?? 'Cash',
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'paymentType': paymentType,
      'timestamp': timestamp,
    };
  }

  String get formattedDate {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String get formattedDateTime {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}