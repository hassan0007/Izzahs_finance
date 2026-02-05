import 'package:flutter/material.dart';
import '../models/sales_data.dart';
import '../models/financial_data.dart';
import '../models/performance_metric.dart';
import '../widgets/metric_card.dart';
import '../widgets/performance_card.dart';
import '../utils/colors.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  // Sample Data
  final List<SalesData> salesData = [
    SalesData(
      title: 'Total Sales',
      amount: 0.00,
      subtitle: 'All Channels',
    ),
    SalesData(
      title: 'Online Sales',
      amount: 0.00,
      subtitle: 'Website',
    ),
    SalesData(
      title: 'In-Store',
      amount: 0.00,
      subtitle: 'In-Store & Phone',
    ),
  ];

  final List<FinancialData> financialData = [
    FinancialData(
      title: 'Payment Processed',
      amount: 0.00,
      status: 'Verified & Cleared',
    ),
    FinancialData(
      title: 'Online Payment',
      amount: 0.00,
      status: 'Sent to Bank',
    ),
    FinancialData(
      title: 'Cash Payment',
      amount: 0.00,
      status: 'On the spot payments',
    ),
  ];

  final List<PerformanceMetric> performanceMetrics = [
    PerformanceMetric(
      title: 'Delivered Percentage',
      value: '0.0%',
      subtitle: '0 orders delivered',
    ),
    PerformanceMetric(
      title: 'Return Ratio',
      value: '0.0%',
      subtitle: '0 items returned',
    ),
    PerformanceMetric(
      title: 'COD Amount Booked',
      value: 'Rs 0.0',
      subtitle: '0 pending COD orders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track your shipments and performance metrics in real time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Last 30 Days'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                      side: const BorderSide(color: AppColors.primaryOrange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sales Overview and Performance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales Overview Section
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sales Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: salesData[0].title,
                            value: 'Rs ${salesData[0].amount.toStringAsFixed(2)}',
                            subtitle: salesData[0].subtitle,
                            borderColor: AppColors.blueBorder,
                            iconColor: AppColors.iconBlue,
                            icon: Icons.public,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            title: salesData[1].title,
                            value: 'Rs ${salesData[1].amount.toStringAsFixed(2)}',
                            subtitle: salesData[1].subtitle,
                            borderColor: AppColors.purpleBorder,
                            iconColor: AppColors.iconPurple,
                            icon: Icons.language,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            title: salesData[2].title,
                            value: 'Rs ${salesData[2].amount.toStringAsFixed(2)}',
                            subtitle: salesData[2].subtitle,
                            borderColor: AppColors.tealBorder,
                            iconColor: AppColors.iconTeal,
                            icon: Icons.store,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Performance Section
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Performance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PerformanceCard(
                      title: performanceMetrics[0].title,
                      value: performanceMetrics[0].value,
                      subtitle: performanceMetrics[0].subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Financial Overview and More Performance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Financial Overview Section
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Financial Overview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: financialData[0].title,
                            value: 'Rs ${financialData[0].amount.toStringAsFixed(2)}',
                            subtitle: financialData[0].status,
                            borderColor: AppColors.greenBorder,
                            iconColor: AppColors.iconGreen,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            title: financialData[1].title,
                            value: 'Rs ${financialData[1].amount.toStringAsFixed(2)}',
                            subtitle: financialData[1].status,
                            borderColor: AppColors.cyanBorder,
                            iconColor: AppColors.iconCyan,
                            icon: Icons.account_balance,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MetricCard(
                            title: financialData[2].title,
                            value: 'Rs ${financialData[2].amount.toStringAsFixed(2)}',
                            subtitle: financialData[2].status,
                            borderColor: AppColors.orangeBorder,
                            iconColor: AppColors.iconOrange,
                            icon: Icons.payments,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Transactions Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'No recent transactions',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // More Performance Metrics
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    PerformanceCard(
                      title: performanceMetrics[1].title,
                      value: performanceMetrics[1].value,
                      subtitle: performanceMetrics[1].subtitle,
                    ),
                    const SizedBox(height: 16),
                    PerformanceCard(
                      title: performanceMetrics[2].title,
                      value: performanceMetrics[2].value,
                      subtitle: performanceMetrics[2].subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
