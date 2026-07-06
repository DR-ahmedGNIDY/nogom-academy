import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/groups/presentation/providers/groups_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final String academyId;

  const CreateGroupScreen({super.key, required this.academyId});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageGroupController = TextEditingController();
  final _capacityController = TextEditingController();
  final _coachController = TextEditingController();

  String? _selectedSport;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageGroupController.dispose();
    _capacityController.dispose();
    _coachController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final academy =
        ref.read(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    if (isMultiSport && (_selectedSport == null || _selectedSport!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الرياضة'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref.read(groupsProvider.notifier).createGroup(
          academyId: widget.academyId,
          name: _nameController.text.trim(),
          sportId: isMultiSport ? _selectedSport : null,
          ageGroup: _ageGroupController.text.trim().isEmpty
              ? null
              : _ageGroupController.text.trim(),
          capacity: _capacityController.text.trim().isEmpty
              ? null
              : int.tryParse(_capacityController.text.trim()),
          coachId: _coachController.text.trim().isEmpty
              ? null
              : _coachController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

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
          content: Text('تم إضافة المجموعة بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final academyAsync = ref.watch(academyByIdProvider(widget.academyId));
    final academy = academyAsync.valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final sports = academy?.sports ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إضافة مجموعة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('اسم المجموعة'),
              Gap(6.h),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(hint: 'أدخل اسم المجموعة'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppStrings.required;
                  }
                  return null;
                },
              ),
              Gap(16.h),
              if (isMultiSport) ...[
                _buildLabel('الرياضة'),
                Gap(6.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSport,
                  decoration: _inputDecoration(hint: 'اختر الرياضة'),
                  items: sports
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSport = val),
                  validator: (v) => v == null ? AppStrings.required : null,
                ),
                Gap(16.h),
              ],
              _buildLabel('الفئة العمرية (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _ageGroupController,
                decoration: _inputDecoration(hint: 'مثال: تحت 12 سنة'),
              ),
              Gap(16.h),
              _buildLabel('السعة القصوى (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hint: 'عدد اللاعبين الأقصى'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (int.tryParse(v.trim()) == null) {
                    return 'يجب إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              Gap(16.h),
              _buildLabel('المدرب (اختياري)'),
              Gap(6.h),
              TextFormField(
                controller: _coachController,
                decoration: _inputDecoration(hint: 'اسم أو معرّف المدرب'),
              ),
              Gap(24.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'إضافة مجموعة',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              Gap(40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.grey700,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14.sp),
      filled: true,
      fillColor: AppColors.white,
      contentPadding:
          EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
