import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/expenses/presentation/providers/expense_provider.dart';
import 'package:basketball_academy/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// التقارير المالية — مقصورة على Super Admin فقط (تجمع الرواتب والمصروفات
/// والإيرادات الخاصة بأكاديمية واحدة لشهر محدد، عبر نقاط النهاية الموجودة
/// مسبقاً دون أي تعديل على منطقها).
class FinancialReportsScreen extends ConsumerStatefulWidget {
  final String academyId;
  const FinancialReportsScreen({super.key, required this.academyId});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState
    extends ConsumerState<FinancialReportsScreen> {
  String _month = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final start = DateTime.parse('$_month-01');
    final lastDay = DateTime(start.year, start.month + 1, 0);
    ref.read(payrollReportProvider.notifier).load(widget.academyId, _month);
    ref.read(expenseReportProvider.notifier).load(
          academyId: widget.academyId,
          startDate: DateFormat('yyyy-MM-dd').format(start),
          endDate: DateFormat('yyyy-MM-dd').format(lastDay),
        );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final current = DateTime.parse('$_month-01');
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _month = DateFormat('yyyy-MM').format(picked));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsync = ref.watch(payrollReportProvider);
    final expenseAsync = ref.watch(expenseReportProvider);
    final revenueAsync = ref.watch(revenueSummaryProvider(widget.academyId));

    final totalPayroll = payrollAsync.valueOrNull?.totalNetSalary ?? 0;
    final totalExpenses = expenseAsync.valueOrNull?.totalAmount ?? 0;
    final monthlyRevenue =
        (revenueAsync.valueOrNull?['monthlyRevenue'] as num?)?.toDouble() ?? 0;
    final totalRevenue =
        (revenueAsync.valueOrNull?['totalRevenue'] as num?)?.toDouble() ?? 0;
    final netRevenue = monthlyRevenue - totalExpenses - totalPayroll;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'اختر الشهر',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Center(
            child: Chip(
              label: Text(_month, style: TextStyle(fontSize: 14.sp)),
              backgroundColor: AppColors.primaryContainer,
            ),
          ),
          Gap(20.h),
          _FinancialCard(
            icon: Icons.payments_outlined,
            color: AppColors.error,
            label: 'إجمالي الرواتب (الشهر المحدد)',
            value: totalPayroll,
            loading: payrollAsync.isLoading,
          ),
          Gap(12.h),
          _FinancialCard(
            icon: Icons.receipt_long_outlined,
            color: AppColors.error,
            label: 'إجمالي المصروفات (الشهر المحدد)',
            value: totalExpenses,
            loading: expenseAsync.isLoading,
          ),
          Gap(12.h),
          _FinancialCard(
            icon: Icons.trending_up,
            color: AppColors.success,
            label: 'إيرادات الشهر الحالي',
            value: monthlyRevenue,
            loading: revenueAsync.isLoading,
          ),
          Gap(12.h),
          _FinancialCard(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.secondary,
            label: 'إجمالي الإيرادات (منذ التأسيس)',
            value: totalRevenue,
            loading: revenueAsync.isLoading,
          ),
          Gap(20.h),
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: netRevenue >= 0
                  ? AppColors.successLight
                  : AppColors.errorLight,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Text('صافي الإيرادات (إيرادات الشهر - الرواتب - المصروفات)',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey700),
                    textAlign: TextAlign.center),
                Gap(8.h),
                Text(
                  netRevenue.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: netRevenue >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final bool loading;

  const _FinancialCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: TextStyle(fontSize: 13.sp)),
        trailing: loading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
