import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/matches/presentation/providers/matches_provider.dart';
import 'package:basketball_academy/features/matches/presentation/screens/match_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  final String academyId;

  const CreateMatchScreen({super.key, required this.academyId});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String? _sport;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      _snack('التاريخ مطلوب', error: true);
      return;
    }
    if (_time == null) {
      _snack('الساعة مطلوبة', error: true);
      return;
    }

    setState(() => _saving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_date!);
    final timeStr =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';

    final match = await ref.read(matchesNotifierProvider.notifier).createMatch(
          academyId: widget.academyId,
          sport: _sport,
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          date: dateStr,
          time: timeStr,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (match == null) {
      _snack('فشل إنشاء المباراة', error: true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          matchId: match.id,
          academyId: widget.academyId,
        ),
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final academySports = academy?.sports ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء قائمة لاعبي مباراة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMultiSport) ...[
                DropdownButtonFormField<String>(
                  initialValue: _sport,
                  decoration: const InputDecoration(
                    labelText: 'الرياضة',
                    prefixIcon: Icon(Icons.sports_soccer_outlined),
                  ),
                  items: academySports
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _sport = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'الرياضة مطلوبة' : null,
                ),
                Gap(16.h),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المباراة',
                  prefixIcon: Icon(Icons.sports_soccer_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'اسم المباراة مطلوب'
                    : null,
              ),
              Gap(16.h),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'مكان المباراة',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'المكان مطلوب' : null,
              ),
              Gap(16.h),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _date == null
                        ? 'اختر التاريخ'
                        : DateFormat('yyyy-MM-dd').format(_date!),
                    style: TextStyle(
                      color: _date == null
                          ? AppColors.grey400
                          : AppColors.grey900,
                    ),
                  ),
                ),
              ),
              Gap(16.h),
              InkWell(
                onTap: _pickTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'الساعة',
                    prefixIcon: Icon(Icons.access_time_outlined),
                  ),
                  child: Text(
                    _time == null ? 'اختر الساعة' : _time!.format(context),
                    style: TextStyle(
                      color: _time == null
                          ? AppColors.grey400
                          : AppColors.grey900,
                    ),
                  ),
                ),
              ),
              Gap(16.h),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes_outlined),
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
                    : const Text('إنشاء المباراة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
