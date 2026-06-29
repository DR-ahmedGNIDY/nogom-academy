import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

/// تسجيل دفعة على الاشتراك الحالي — يُسجَّل كملاحظة على الاشتراك الأحدث
/// (لا يوجد في النظام حالياً مفهوم "دفعات جزئية" مستقل عن الاشتراك نفسه).
class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String playerId;
  final String playerName;
  final SubscriptionEntity subscription;

  const RecordPaymentScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.subscription,
  });

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final existingNotes = widget.subscription.notes ?? '';
    final paymentLine = 'دفعة بقيمة $amount بتاريخ $dateStr';
    final updatedNotes =
        existingNotes.isEmpty ? paymentLine : '$existingNotes\n$paymentLine';

    final error = await ref
        .read(playerSubscriptionsProvider(widget.playerId).notifier)
        .updateNotes(id: widget.subscription.id, notes: updatedNotes);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدفعة بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دفعة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.playerName,
                  style: Theme.of(context).textTheme.titleMedium),
              Gap(20.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'قيمة الدفعة',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'قيمة غير صحيحة';
                  return null;
                },
              ),
              Gap(16.h),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(DateTime.now().year - 2),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الدفعة',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                ),
              ),
              Gap(24.h),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('تسجيل الدفعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
