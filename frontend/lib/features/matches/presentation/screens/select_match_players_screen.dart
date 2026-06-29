import 'dart:async';

import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/matches/presentation/providers/matches_provider.dart';
import 'package:basketball_academy/features/player/presentation/providers/player_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class SelectMatchPlayersScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String academyId;
  final Set<String> alreadyAdded;

  const SelectMatchPlayersScreen({
    super.key,
    required this.matchId,
    required this.academyId,
    required this.alreadyAdded,
  });

  @override
  ConsumerState<SelectMatchPlayersScreen> createState() =>
      _SelectMatchPlayersScreenState();
}

class _SelectMatchPlayersScreenState
    extends ConsumerState<SelectMatchPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Set<String> _added;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _added = {...widget.alreadyAdded};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playersProvider.notifier).filterByAcademy(widget.academyId);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isEmpty) {
        ref.read(playersProvider.notifier).clearSearch();
      } else {
        ref.read(playersProvider.notifier).search(value.trim());
      }
    });
  }

  Future<void> _togglePlayer(String playerId) async {
    if (_added.contains(playerId)) return;
    setState(() => _added.add(playerId));
    final ok = await ref.read(matchesNotifierProvider.notifier).addPlayers(
          matchId: widget.matchId,
          playerIds: [playerId],
        );
    if (!ok && mounted) {
      setState(() => _added.remove(playerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إضافة لاعبين للمباراة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الكود',
                prefixIcon: Icon(Icons.search,
                    color: AppColors.grey400, size: 20.sp),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: AppColors.grey400, size: 18.sp),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
              ),
            ),
          ),
          Expanded(
            child: playersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (state) {
                if (state.players.isEmpty) {
                  return const Center(child: Text('لا يوجد لاعبون'));
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  itemCount: state.players.length,
                  separatorBuilder: (_, __) => Gap(10.h),
                  itemBuilder: (context, index) {
                    final player = state.players[index];
                    final isAdded = _added.contains(player.id);
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          backgroundImage: (player.imageUrl != null &&
                                  player.imageUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(player.imageUrl!)
                              : null,
                          child: (player.imageUrl == null ||
                                  player.imageUrl!.isEmpty)
                              ? Icon(Icons.person, color: AppColors.primary)
                              : null,
                        ),
                        title: Text(player.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${player.playerCode} • ${player.age} سنة${player.sport != null ? ' • ${player.sport}' : ''}',
                          style: TextStyle(
                              fontSize: 12.sp, color: AppColors.grey500),
                        ),
                        trailing: isAdded
                            ? Chip(
                                label: const Text('تمت الإضافة ✓'),
                                backgroundColor: AppColors.successLight,
                                labelStyle:
                                    TextStyle(color: AppColors.success),
                              )
                            : OutlinedButton(
                                onPressed: () => _togglePlayer(player.id),
                                child: const Text('إضافة للمباراة'),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () {
                      Navigator.of(context).pop(true);
                    },
              child: const Text('إنشاء القائمة'),
            ),
          ),
        ],
      ),
    );
  }
}
