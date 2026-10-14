import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'widgets/pet_sheet.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ← ref 在这里
    final state = ref.watch(appStateProvider);
    final pets = state.pets;
    final notifier = ref.read(appStateProvider.notifier);

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: pets.isEmpty
            ? _empty(context, ref) // ← 传 ref
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '我的宠物',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.25,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '共 ${pets.length} 只宝贝',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _addButton(
                          onTap: () => showPetSheet(context, ref, null),
                        ),
                      ],
                    ),
                  ),
                  // ↓ 这里必须把 ref 传给 _petCard
                  ...List.generate(
                    pets.length,
                    (i) => _petCard(
                      context,
                      ref, // ← 传 ref
                      notifier,
                      state,
                      pets[i],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _addButton({required VoidCallback onTap}) {
    return GestureDetector(
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
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ↓ 签名加上 WidgetRef ref
  Widget _petCard(
    BuildContext context,
    WidgetRef ref, // ← 新增参数
    AppStateNotifier notifier,
    AppState state,
    dynamic p,
  ) {
    final w = notifier.latestWeightOf(p.id);
    final r = notifier.nextReminderOf(p.id);

    final metaSpans = <InlineSpan>[];
    if (w != null) {
      metaSpans.add(const TextSpan(text: '最近体重 '));
      metaSpans.add(
        TextSpan(
          text: '${w.value} kg',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      metaSpans.add(const TextSpan(text: '暂无体重记录'));
    }
    if (r != null) {
      final d = daysUntil(r.date);
      Color tagColor = AppColors.muted;
      String tagTxt;
      if (d < 0) {
        tagColor = AppColors.red;
        tagTxt = '已过期 ${-d} 天';
      } else if (d == 0) {
        tagColor = AppColors.red;
        tagTxt = '就是今天';
      } else if (d <= 7) {
        tagColor = AppColors.primary;
        tagTxt = '$d 天后';
      } else {
        tagTxt = '$d 天后';
      }
      metaSpans.add(TextSpan(text: ' · ${r.title} '));
      metaSpans.add(
        TextSpan(
          text: tagTxt,
          style: TextStyle(color: tagColor, fontWeight: FontWeight.w600),
        ),
      );
    }

    return GestureDetector(
      onTap: () => showPetSheet(context, ref, p), // ← 现在 ref 有定义了
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
        ),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    p.avatar,
                    style: const TextStyle(fontSize: 28, height: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (p.gender.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.gender,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          p.breed,
                          p.birthday,
                        ].where((e) => e != null && e.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                              height: 1.45,
                            ),
                            children: metaSpans,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => notifier.deletePet(p.id),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 15,
                      color: Color(0xFFCCD1E0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 50, height: 1)),
          const SizedBox(height: 14),
          const Text(
            '还没有宠物档案\n先给毛孩子建个档吧',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.muted,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 200,
            child: GestureDetector(
              onTap: () => showPetSheet(context, ref, null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52FF7A59),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  '＋ 添加第一只宠物',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
