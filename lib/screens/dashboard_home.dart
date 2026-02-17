import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sales_data.dart';
import '../models/financial_data.dart';
import '../widgets/metric_card.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String selectedPeriod = 'Today';
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime endDate = DateTime.now();

  List<SalesData> salesData = [
    SalesData(title: 'Cash', amount: 0.00, subtitle: 'Cash'),
    SalesData(title: 'Online', amount: 0.00, subtitle: 'Bank'),
  ];

  List<FinancialData> financialData = [
    FinancialData(title: 'Cash', amount: 0.00, status: 'Money'),
    FinancialData(title: 'Online', amount: 0.00, status: 'Sent to Bank'),
  ];

  List<FlSpot> netProfitSpots = [];
  List<DateTime> chartDates = [];
  double maxY = 100;
  double minY = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadChartData();
  }

  void _updateDateRange(String period) {
    setState(() {
      selectedPeriod = period;
      final now = DateTime.now();
      endDate = now;

      switch (period) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'This Week':
          final weekday = now.weekday;
          startDate = now.subtract(Duration(days: weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
      }

      _loadChartData();
    });
  }

  void _loadChartData() async {
    final incomeSnapshot = await _database.child('income_transactions').get();
    final expenseSnapshot = await _database.child('expense_transactions').get();
    final bool aggregateByMonth = selectedPeriod == 'This Year';

    List<Map<String, dynamic>> allTransactions = [];

    if (incomeSnapshot.value != null) {
      final data = incomeSnapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final timestamp = value['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final dateKey = aggregateByMonth ? DateTime(date.year, date.month, 1) : date;

        if (dateKey.isAfter(startDate.subtract(const Duration(days: 1))) &&
            dateKey.isBefore(endDate.add(const Duration(days: 1)))) {
          final amount = (value['amount'] ?? 0.0).toDouble();
          allTransactions.add({'date': dateKey, 'timestamp': timestamp, 'amount': amount, 'type': 'income'});
        }
      });
    }

    if (expenseSnapshot.value != null) {
      final data = expenseSnapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final timestamp = value['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final dateKey = aggregateByMonth ? DateTime(date.year, date.month, 1) : date;

        if (dateKey.isAfter(startDate.subtract(const Duration(days: 1))) &&
            dateKey.isBefore(endDate.add(const Duration(days: 1)))) {
          final amount = (value['amount'] ?? 0.0).toDouble();
          allTransactions.add({'date': dateKey, 'timestamp': timestamp, 'amount': amount, 'type': 'expense'});
        }
      });
    }

    allTransactions.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    if (aggregateByMonth) {
      Map<DateTime, Map<String, double>> monthlyData = {};
      for (var transaction in allTransactions) {
        final date = transaction['date'] as DateTime;
        final monthKey = DateTime(date.year, date.month, 1);
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {'income': 0.0, 'expense': 0.0};
        }
        if (transaction['type'] == 'income') {
          monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + transaction['amount'];
        } else {
          monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + transaction['amount'];
        }
      }

      allTransactions.clear();
      monthlyData.forEach((date, data) {
        allTransactions.add({'date': date, 'timestamp': date.millisecondsSinceEpoch, 'amount': data['income']!, 'type': 'income'});
        allTransactions.add({'date': date, 'timestamp': date.millisecondsSinceEpoch + 1, 'amount': data['expense']!, 'type': 'expense'});
      });
      allTransactions.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
    }

    double runningBalance = 0;
    List<FlSpot> spots = [];
    List<DateTime> dates = [];
    double maxValue = 0;
    double minValue = 0;

    if (allTransactions.isNotEmpty) {
      spots.add(FlSpot(0, 0));
      dates.add(allTransactions[0]['date']);
    }

    for (int i = 0; i < allTransactions.length; i++) {
      final transaction = allTransactions[i];
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;
      final date = transaction['date'] as DateTime;

      if (type == 'income') {
        runningBalance += amount;
      } else {
        runningBalance -= amount;
      }

      spots.add(FlSpot((i + 1).toDouble(), runningBalance));
      dates.add(date);

      if (runningBalance > maxValue) maxValue = runningBalance;
      if (runningBalance < minValue) minValue = runningBalance;
    }

    setState(() {
      netProfitSpots = spots;
      chartDates = dates;
      if (spots.isEmpty) {
        maxY = 100;
        minY = 0;
      } else {
        final padding = (maxValue - minValue) * 0.1;
        maxY = maxValue + (padding > 0 ? padding : 100);
        // Ensure minY is never negative - set to 0 if minValue is positive
        minY = minValue < 0 ? (minValue - (padding > 0 ? padding : 100)) : 0;
        if (maxY == minY) {
          maxY = minValue + 100;
          minY = minValue > 0 ? 0 : minValue - 100;
        }
      }
    });
  }

  void _loadData() {
    _database.child('income').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          salesData[0] = SalesData(title: 'Cash', amount: (data['cash'] ?? 0.0).toDouble(), subtitle: 'Cash');
          salesData[1] = SalesData(title: 'Online', amount: (data['online'] ?? 0.0).toDouble(), subtitle: 'Bank');
        });
      }
    });

    _database.child('expense').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          financialData[0] = FinancialData(title: 'Cash', amount: (data['cash'] ?? 0.0).toDouble(), status: 'Money');
          financialData[1] = FinancialData(title: 'Online', amount: (data['online'] ?? 0.0).toDouble(), status: 'Sent to Bank');
        });
      }
    });
  }

  void _showAddIncomeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String paymentType = 'Cash';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Income'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: 'Rs '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Payment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'Cash',
                      groupValue: paymentType,
                      onChanged: (value) => setDialogState(() => paymentType = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Online'),
                      value: 'Online',
                      groupValue: paymentType,
                      onChanged: (value) => setDialogState(() => paymentType = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final amount = double.tryParse(amountController.text) ?? 0.0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      try {
                        final transactionRef = _database.child('income_transactions').push();
                        await transactionRef.set({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'amount': amount,
                          'paymentType': paymentType,
                          'timestamp': ServerValue.timestamp,
                        });
                        final pathKey = paymentType == 'Cash' ? 'cash' : 'online';
                        final totalRef = _database.child('income/$pathKey');
                        await totalRef.runTransaction((currentValue) {
                          double current = 0.0;
                          if (currentValue != null && currentValue is num) {
                            current = currentValue.toDouble();
                          }
                          return Transaction.success(current + amount);
                        });
                        if (mounted) {
                          Navigator.of(context).pop();
                          _loadChartData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Income added: Rs ${amount.toStringAsFixed(2)} ($paymentType)'), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding income: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String paymentType = 'Cash';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Calculate remaining balance for selected payment type
            final totalCashIncome = salesData[0].amount;
            final totalOnlineIncome = salesData[1].amount;
            final totalCashExpense = financialData[0].amount;
            final totalOnlineExpense = financialData[1].amount;

            final remainingBalance = paymentType == 'Cash'
                ? (totalCashIncome - totalCashExpense)
                : (totalOnlineIncome - totalOnlineExpense);

            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Balance Indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingBalance > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: remainingBalance > 0
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            remainingBalance > 0
                                ? Icons.check_circle
                                : Icons.warning,
                            color: remainingBalance > 0
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Balance ($paymentType)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Rs ${remainingBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: remainingBalance > 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: 'Rs '),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Payment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    RadioListTile<String>(
                      title: const Text('Cash'),
                      value: 'Cash',
                      groupValue: paymentType,
                      onChanged: (value) => setDialogState(() => paymentType = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Online'),
                      value: 'Online',
                      groupValue: paymentType,
                      onChanged: (value) => setDialogState(() => paymentType = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final amount = double.tryParse(amountController.text) ?? 0.0;

                      // Validate amount
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Calculate current balance
                      final totalCashIncome = salesData[0].amount;
                      final totalOnlineIncome = salesData[1].amount;
                      final totalCashExpense = financialData[0].amount;
                      final totalOnlineExpense = financialData[1].amount;

                      final currentBalance = paymentType == 'Cash'
                          ? (totalCashIncome - totalCashExpense)
                          : (totalOnlineIncome - totalOnlineExpense);

                      // Check if expense exceeds available balance
                      if (amount > currentBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Insufficient balance! Available: Rs ${currentBalance.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }

                      try {
                        final transactionRef = _database.child('expense_transactions').push();
                        await transactionRef.set({
                          'title': titleController.text,
                          'description': descriptionController.text,
                          'amount': amount,
                          'paymentType': paymentType,
                          'timestamp': ServerValue.timestamp,
                        });
                        final pathKey = paymentType == 'Cash' ? 'cash' : 'online';
                        final totalRef = _database.child('expense/$pathKey');
                        await totalRef.runTransaction((currentValue) {
                          double current = 0.0;
                          if (currentValue != null && currentValue is num) {
                            current = currentValue.toDouble();
                          }
                          return Transaction.success(current + amount);
                        });
                        if (mounted) {
                          Navigator.of(context).pop();
                          _loadChartData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Expense added: Rs ${amount.toStringAsFixed(2)} ($paymentType)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding expense: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = salesData[0].amount + salesData[1].amount;
    final totalExpense = financialData[0].amount + financialData[1].amount;
    final netProfit = totalIncome - totalExpense;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.getResponsiveValue(context: context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
              ResponsiveUtils.getResponsiveValue(context: context, mobile: 16.0, desktop: 24.0),
              ResponsiveUtils.getResponsiveValue(context: context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
              ResponsiveUtils.getResponsiveValue(context: context, mobile: 16.0, desktop: 24.0),
            ),
            child: isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your income and expenses in real time.',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<String>(
                        color: Colors.white,
                        initialValue: selectedPeriod,
                        onSelected: _updateDateRange,
                        itemBuilder: (BuildContext context) => const [
                          PopupMenuItem(value: 'Today', child: Text('Today')),
                          PopupMenuItem(value: 'This Week', child: Text('This Week')),
                          PopupMenuItem(value: 'This Month', child: Text('This Month')),
                          PopupMenuItem(value: 'This Year', child: Text('This Year')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                selectedPeriod,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text('Export', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryOrange,
                          side: const BorderSide(color: AppColors.primaryOrange),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your income and expenses in real time.',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    PopupMenuButton<String>(
                      color: Colors.white,
                      initialValue: selectedPeriod,
                      onSelected: _updateDateRange,
                      itemBuilder: (BuildContext context) => const [
                        PopupMenuItem(value: 'Today', child: Text('Today')),
                        PopupMenuItem(value: 'This Week', child: Text('This Week')),
                        PopupMenuItem(value: 'This Month', child: Text('This Month')),
                        PopupMenuItem(value: 'This Year', child: Text('This Year')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              selectedPeriod,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('Export', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryOrange,
                        side: const BorderSide(color: AppColors.primaryOrange),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: ResponsiveBuilder(
              mobile: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIncomeSection(isMobile: true),
                  const SizedBox(height: 20),
                  _buildExpenseSection(isMobile: true),
                  const SizedBox(height: 20),
                  _buildChart(netProfit, isMobile: true),
                ],
              ),
              tablet: (context) => Column(
                children: [
                  _buildIncomeSection(isMobile: false),
                  const SizedBox(height: 20),
                  _buildExpenseSection(isMobile: false),
                  const SizedBox(height: 20),
                  _buildChart(netProfit, isMobile: false),
                ],
              ),
              desktop: (context) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIncomeSection(isMobile: false),
                        const SizedBox(height: 20),
                        _buildExpenseSection(isMobile: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _buildChart(netProfit, isMobile: false)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection({required bool isMobile}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  'Income',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddIncomeDialog,
              icon: const Icon(Icons.add, size: 12),
              label: Text('Add', style: TextStyle(fontSize: isMobile ? 14 : 16)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 4),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        isMobile
            ? Column(
          children: [
            MetricCard(
              title: salesData[0].title,
              value: 'Rs ${salesData[0].amount.toStringAsFixed(0)}',
              subtitle: salesData[0].subtitle,
              borderColor: AppColors.blueBorder,
              iconColor: AppColors.iconBlue,
              icon: Icons.public,
            ),
            const SizedBox(height: 10),
            MetricCard(
              title: salesData[1].title,
              value: 'Rs ${salesData[1].amount.toStringAsFixed(0)}',
              subtitle: salesData[1].subtitle,
              borderColor: AppColors.purpleBorder,
              iconColor: AppColors.iconPurple,
              icon: Icons.language,
            ),
          ],
        )
            : Row(
          children: [
            Expanded(
              child: MetricCard(
                title: salesData[0].title,
                value: 'Rs ${salesData[0].amount.toStringAsFixed(0)}',
                subtitle: salesData[0].subtitle,
                borderColor: AppColors.blueBorder,
                iconColor: AppColors.iconBlue,
                icon: Icons.public,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: salesData[1].title,
                value: 'Rs ${salesData[1].amount.toStringAsFixed(0)}',
                subtitle: salesData[1].subtitle,
                borderColor: AppColors.purpleBorder,
                iconColor: AppColors.iconPurple,
                icon: Icons.language,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpenseSection({required bool isMobile}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  'Expense',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add, size: 12),
              label: Text('Add', style: TextStyle(fontSize: isMobile ? 14 : 16)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: 4),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        isMobile
            ? Column(
          children: [
            MetricCard(
              title: financialData[0].title,
              value: 'Rs ${financialData[0].amount.toStringAsFixed(0)}',
              subtitle: financialData[0].status,
              borderColor: AppColors.greenBorder,
              iconColor: AppColors.iconGreen,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 10),
            MetricCard(
              title: financialData[1].title,
              value: 'Rs ${financialData[1].amount.toStringAsFixed(0)}',
              subtitle: financialData[1].status,
              borderColor: AppColors.cyanBorder,
              iconColor: AppColors.iconCyan,
              icon: Icons.account_balance,
            ),
          ],
        )
            : Row(
          children: [
            Expanded(
              child: MetricCard(
                title: financialData[0].title,
                value: 'Rs ${financialData[0].amount.toStringAsFixed(0)}',
                subtitle: financialData[0].status,
                borderColor: AppColors.greenBorder,
                iconColor: AppColors.iconGreen,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: financialData[1].title,
                value: 'Rs ${financialData[1].amount.toStringAsFixed(0)}',
                subtitle: financialData[1].status,
                borderColor: AppColors.cyanBorder,
                iconColor: AppColors.iconCyan,
                icon: Icons.account_balance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(double netProfit, {required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Running Balance',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: netProfit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Rs ${netProfit.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    color: netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Income adds up, expenses bring it down',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isMobile ? 200 : 280,
            child: netProfitSpots.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No transaction data available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: selectedPeriod == 'This Year'
                          ? 1
                          : (netProfitSpots.length > 10 ? (netProfitSpots.length / 5).ceilToDouble() : 1),
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= chartDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = chartDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            selectedPeriod == 'This Year' ? DateFormat('MMM').format(date) : DateFormat('MMM d').format(date),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 9 : 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 4,
                      reservedSize: isMobile ? 40 : 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Rs ${value.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 9 : 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                minX: 0,
                maxX: (netProfitSpots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: netProfitSpots,
                    isCurved: true,
                    color: AppColors.primaryOrange,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryOrange.withOpacity(0.2),
                          AppColors.primaryOrange.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= chartDates.length) return null;
                        final date = chartDates[index];
                        return LineTooltipItem(
                          selectedPeriod == 'This Year'
                              ? '${DateFormat('MMMM yyyy').format(date)}\nBalance: Rs ${spot.y.toStringAsFixed(2)}'
                              : '${DateFormat('MMM d, yyyy').format(date)}\nBalance: Rs ${spot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}