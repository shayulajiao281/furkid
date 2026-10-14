import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'widgets/weight_sheet.dart';

class WeightPage extends ConsumerStatefulWidget {
  const WeightPage({super.key});
  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  String? _petId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final pets = state.pets;

    if (pets.isEmpty) return _empty();

    if (_petId == null || !pets.any((p) => p.id == _petId)) {
      _petId = pets.first.id;
    }

    final recs = state.weights.where((w) => w.petId == _petId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final latest = recs.isNotEmpty ? recs.last : null;
    final prev = recs.length >= 2 ? recs[recs.length - 2] : null;

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            // ============ Page head ============
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '体重记录',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.25,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '记录每一次成长',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _addButton(
                    onTap: () => showWeightSheet(context, ref, _petId!),
                  ),
                ],
              ),
            ),

            // ============ 宠物切换 chips ============
            _chipsRow(pets),

            const SizedBox(height: 14),

            // ============ Hero ============
            _hero(latest, prev),

            const SizedBox(height: 13),

            // ============ 历史 ============
            if (recs.isNotEmpty) _history(notifier, recs),
          ],
        ),
      ),
    );
  }

  Widget _addButton({required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FF7A59),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '＋',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 23,
            height: 1,
          ),
        ),
      ),
    ),
  );

  Widget _chipsRow(List<dynamic> pets) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = pets[i];
          final active = p.id == _petId;
          return GestureDetector(
            onTap: () => setState(() => _petId = p.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : CupertinoColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.line,
                ),
              ),
              child: Text(
                '${p.avatar} ${p.name}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: active ? CupertinoColors.white : AppColors.muted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---- Hero 卡片 (渐变 135deg #ff9a6b → #ff6b8a) ----
  Widget _hero(dynamic latest, dynamic prev) {
    final hasData = latest != null;
    final diff = (hasData && prev != null) ? (latest.value - prev.value) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(19, 17, 19, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9A6B), Color(0xFFFF6B8A)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4DFF6B8A), // rgba(255,107,138,.3)
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasData ? '当前体重 · ${latest.date}' : '还没有体重记录',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xF0FFFFFF),
              letterSpacing: 0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasData ? '${latest.value}' : '--',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: CupertinoColors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kg',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xE6FFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            hasData
                ? (prev != null
                      ? '较上次 ${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg'
                      : '第一次记录，继续加油 💪')
                : '点右上角 ＋ 记录第一次体重',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xF0FFFFFF),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 历史记录卡片 ----
  Widget _history(AppStateNotifier notifier, List<dynamic> recs) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '历史记录 · ${recs.length} 条',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          ...recs.reversed.map((r) {
            final isLast = r == recs.first;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.date,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    '${r.value} kg',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => notifier.deleteWeight(r.id),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 12,
                          color: Color(0xFFA0A7B8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _empty() => Container(
    color: AppColors.bg,
    child: const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⚖️', style: TextStyle(fontSize: 50, height: 1)),
            SizedBox(height: 14),
            Text(
              '还没有宠物档案\n先添加一只宝贝吧',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.muted,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
