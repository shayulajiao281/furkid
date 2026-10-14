import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/pet_avatar.dart';
import 'widgets/pet_sheet.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final pets = state.pets;
    final notifier = ref.read(appStateProvider.notifier);

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ============ 固定的顶部 ============
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                          pets.isEmpty ? '还没有档案哦' : '共 ${pets.length} 只宝贝',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _addButton(onTap: () => showPetSheet(context, ref, null)),
                ],
              ),
            ),

            // ============ 只有列表滚动 ============
            Expanded(
              child: pets.isEmpty
                  ? _empty(context, ref)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: pets.length,
                      itemBuilder: (_, i) =>
                          _petCard(context, ref, notifier, state, pets[i]),
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
        child: const Icon(
          CupertinoIcons.plus,
          size: 24,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  // ---------------- 宠物卡片（带左滑删除） ----------------
  Widget _petCard(
    BuildContext context,
    WidgetRef ref,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Slidable(
        key: ValueKey(p.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                _confirmDelete(context, notifier, p);
              },
              backgroundColor: AppColors.red,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.delete,
              label: '删除',
              borderRadius: BorderRadius.circular(18),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        child: Builder(
          builder: (slideContext) => GestureDetector(
            onTap: () {
              final slide = Slidable.of(slideContext);
              if (slide != null && slide.animation.value > 0.01) {
                slide.close(); // ← 侧滑打开，关闭
              } else {
                showPetSheet(context, ref, p); // ← 侧滑关闭，开编辑
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ★ 头像：自动区分 emoji / 图片
                  PetAvatar(avatar: p.avatar, size: 54, radius: 16),
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
                            // ★ "未知"性别不显示 tag
                            if (p.gender.isNotEmpty && p.gender != '未知') ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 删除确认框 ----------------
  void _confirmDelete(
    BuildContext context,
    AppStateNotifier notifier,
    dynamic p,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除宠物档案'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '确定要删除「${p.name}」吗？\n'
            '该宠物的所有提醒和体重记录也会一起删除。',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deletePet(p.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ---------------- 空态 ----------------
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
