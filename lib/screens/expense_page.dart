import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _searchController = TextEditingController();

  double totalCash = 0.0;
  double totalOnline = 0.0;
  double availableCashIncome = 0.0;
  double availableOnlineIncome = 0.0;
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  Map<String, double> titleTotals = {};
  bool isLoading = true;
  bool showAllTransactions = false;
  int touchedIndex = -1;

  final List<Color> chartColors = [
    Colors.red,
    Colors.orange,
    Colors.deepOrange,
    Colors.redAccent,
    Colors.pink,
    Colors.brown,
    Colors.amber,
    Colors.deepPurple,
    Colors.purple,
    Colors.indigo,
    Colors.blueGrey,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Load income data to check available balance
    _database.child('income').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          availableCashIncome = (data['cash'] ?? 0.0).toDouble();
          availableOnlineIncome = (data['online'] ?? 0.0).toDouble();
        });
      }
    });

    _database.child('expense').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          totalCash = (data['cash'] ?? 0.0).toDouble();
          totalOnline = (data['online'] ?? 0.0).toDouble();
        });
      }
    });

    _database.child('expense_transactions').onValue.listen((event) {
      final List<TransactionModel> loadedTransactions = [];
      final Map<String, double> tempTitleTotals = {};

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final transaction = TransactionModel.fromMap(key, value as Map<dynamic, dynamic>);
          loadedTransactions.add(transaction);

          final title = transaction.title.trim();
          if (title.isNotEmpty) {
            tempTitleTotals[title] = (tempTitleTotals[title] ?? 0.0) + transaction.amount;
          }
        });

        loadedTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      setState(() {
        allTransactions = loadedTransactions;
        filteredTransactions = loadedTransactions;
        titleTotals = tempTitleTotals;
        isLoading = false;
      });
    });
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredTransactions = allTransactions;
      } else {
        filteredTransactions = allTransactions
            .where((transaction) =>
        transaction.title.toLowerCase().contains(query) ||
            transaction.description.toLowerCase().contains(query))
            .toList();
      }
    });
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
            final remainingBalance = paymentType == 'Cash'
                ? (availableCashIncome - totalCash)
                : (availableOnlineIncome - totalOnline);

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

                      // Calculate remaining balance
                      final currentBalance = paymentType == 'Cash'
                          ? (availableCashIncome - totalCash)
                          : (availableOnlineIncome - totalOnline);

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Expense added: Rs ${amount.toStringAsFixed(2)}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final displayedTransactions = showAllTransactions ? filteredTransactions : filteredTransactions.take(5).toList();
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      color: const Color(0xFFF5F6FA),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Expense Management',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense Management',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Expense Cards
              isMobile
                  ? Column(
                children: [
                  _buildTotalCard('Cash Expense', totalCash, Colors.red, Icons.money_off),
                  const SizedBox(height: 16),
                  _buildTotalCard('Online Expense', totalOnline, Colors.orange, Icons.credit_card),
                ],
              )
                  : Row(
                children: [
                  Expanded(child: _buildTotalCard('Cash Expense', totalCash, Colors.red, Icons.money_off)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTotalCard('Online Expense', totalOnline, Colors.orange, Icons.credit_card)),
                ],
              ),
              const SizedBox(height: 24),

              // Total Expense Card
              _buildTotalCard('Total Expense', totalCash + totalOnline, AppColors.primaryOrange, Icons.trending_down),
              const SizedBox(height: 32),

              // Pie Chart Section
              if (titleTotals.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Distribution by Source',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: isMobile ? 250 : 300,
                        child: isMobile
                            ? Column(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  sections: _createPieChartSections(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(height: 100, child: _buildLegendList()),
                          ],
                        )
                            : Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  sections: _createPieChartSections(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: _buildLegendList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by title or description...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      showAllTransactions ? 'All Transactions' : 'Recent Transactions',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (allTransactions.length > 5)
                    TextButton(
                      onPressed: () => setState(() => showAllTransactions = !showAllTransactions),
                      child: Text(
                        showAllTransactions ? 'Show Less' : 'Show All',
                        style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Transactions List
              if (displayedTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty ? 'No expense transactions yet' : 'No transactions found',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = displayedTransactions[index];
                    return _buildTransactionCard(transaction);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections() {
    final total = titleTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final sortedEntries = titleTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final title = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 110.0 : 100.0;
      final fontSize = isTouched ? 18.0 : 14.0;

      return PieChartSectionData(
        value: amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%\n$title' : '${percentage.toStringAsFixed(1)}%',
        color: chartColors[index % chartColors.length],
        radius: radius,
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize),
      );
    }).toList();
  }

  Widget _buildLegendList() {
    final sortedEntries = titleTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value.key;
          final amount = entry.value.value;
          final total = titleTotals.values.fold(0.0, (sum, amt) => sum + amt);
          final percentage = (amount / total) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: chartColors[index % chartColors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rs ${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalCard(String title, double amount, Color color, IconData icon) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  transaction.paymentType == 'Cash' ? Icons.money_off : Icons.credit_card,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Text(
                      transaction.paymentType,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                    Flexible(
                      child: Text(
                        transaction.formattedDate,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction.paymentType == 'Cash' ? Icons.money_off : Icons.credit_card,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (transaction.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      transaction.paymentType,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text(
                      transaction.formattedDate,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Rs ${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}