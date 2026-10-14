import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:furkid/utils/toast.dart';
import 'package:go_router/go_router.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/pet_avatar.dart';
import 'widgets/reminder_sheet.dart';

// 提醒类型 → emoji
const _typeIcons = {
  'deworm': '🪱',
  'vaccine': '💉',
  'weight': '⚖️',
  'bath': '🛁',
  'checkup': '🩺',
  'other': '📌',
};

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});
  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final pets = state.pets;

    return Container(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: pets.isEmpty
            ? _emptyNoPets(context)
            : Column(
                children: [
                  // ============ 固定顶部：标题 + 加号 ============
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '提醒事项',
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
                                '驱虫 · 疫苗 · 称重 · 洗澡',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _addButton(
                          onTap: () => showReminderSheet(context, ref, null),
                        ),
                      ],
                    ),
                  ),

                  // ============ 固定 chips ============
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _chipsRow(pets),
                  ),

                  const SizedBox(height: 14),

                  // ============ 只有列表滚动 ============
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      children: _buildList(context, notifier, state),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------- 加号按钮 ----------------
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
          size: 20,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  // ---------------- 过滤 chips ----------------
  Widget _chipsRow(List<Pet> pets) {
    final items = <Widget>[
      _chip(label: const Text('全部'), id: 'all'),
      ...pets.map(
        (p) => _chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PetAvatar(avatar: p.avatar, size: 20, radius: 6),
              const SizedBox(width: 6),
              Text(p.name),
            ],
          ),
          id: p.id,
        ),
      ),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  Widget _chip({required Widget label, required String id}) {
    final active = _filter == id;
    return GestureDetector(
      onTap: () => setState(() => _filter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.line,
            width: 1,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 12.5,
            color: active ? CupertinoColors.white : AppColors.muted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
          child: label,
        ),
      ),
    );
  }

  // ---------------- 列表内容 ----------------
  List<Widget> _buildList(
    BuildContext context,
    AppStateNotifier notifier,
    AppState state,
  ) {
    // 按 filter 过滤
    var list = state.reminders
        .map((r) => _ItemWithDays(r, daysUntil(r.date)))
        .toList();
    if (_filter != 'all') {
      list = list.where((e) => e.r.petId == _filter).toList();
    }

    if (list.isEmpty) {
      return [_emptyList(context)];
    }

    // 分组
    final pending = list.where((e) => !e.r.done).toList()
      ..sort((a, b) => a.days.compareTo(b.days));
    final finished = list.where((e) => e.r.done).toList()
      ..sort((a, b) => b.r.date.compareTo(a.r.date));

    final out = <Widget>[];

    if (pending.isNotEmpty) {
      out.add(_sectionTitle('待办 · ${pending.length}'));
      out.addAll(
        pending.map((e) => _remindItem(context, notifier, state, e.r, e.days)),
      );
    }
    if (finished.isNotEmpty) {
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Text(
            '已完成 · ${finished.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
      out.addAll(
        finished
            .take(8)
            .map((e) => _remindItem(context, notifier, state, e.r, e.days)),
      );
    }

    return out;
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 0.3,
      ),
    ),
  );

  // ---------------- 单条提醒 ----------------
  Widget _remindItem(
    BuildContext context,
    AppStateNotifier notifier,
    AppState state,
    Reminder r,
    int days,
  ) {
    // 找到宠物
    final pet = state.pets.where((p) => p.id == r.petId).toList();
    // ★ 只显示名字，不拼 avatar（避免图片路径显示成长链接）
    final petName = pet.isNotEmpty ? pet.first.name : '';

    // 状态文本 + 颜色
    String status;
    Color statusColor;
    if (r.done) {
      status = '已完成';
      statusColor = AppColors.text;
    } else if (days < 0) {
      status = '已过期 ${-days} 天';
      statusColor = AppColors.red;
    } else if (days == 0) {
      status = '就是今天';
      statusColor = AppColors.primary;
    } else {
      status = '$days 天后';
      statusColor = AppColors.text;
    }

    // 左边框颜色
    Color? leftBar;
    if (r.done) {
      leftBar = null;
    } else if (days < 0) {
      leftBar = AppColors.red;
    } else if (days == 0) {
      leftBar = AppColors.primary;
    }

    // 副标题拼装
    final repeatTxt = r.repeat > 0 ? ' · 重复' : '';
    final subPrefix = petName.isNotEmpty ? '$petName · ' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Slidable(
        key: ValueKey(r.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                _confirmDelete(context, notifier, r);
              },
              backgroundColor: AppColors.red,
              foregroundColor: CupertinoColors.white,
              icon: CupertinoIcons.delete,
              label: '删除',
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => showReminderSheet(context, ref, r),
          child: Opacity(
            opacity: r.done ? 0.55 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // 左侧色条（3px）
                    if (leftBar != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 3, color: leftBar),
                      ),
                    // 主内容
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Row(
                        children: [
                          // 图标 42×42
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              _typeIcons[r.type] ?? '📌',
                              style: const TextStyle(fontSize: 20, height: 1),
                            ),
                          ),
                          const SizedBox(width: 11),
                          // 文字区
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text.rich(
                                  TextSpan(
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.muted,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(text: subPrefix),
                                      TextSpan(text: '${r.date}$repeatTxt · '),
                                      TextSpan(
                                        text: status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 勾选按钮 29×29
                          GestureDetector(
                            onTap: () => _onCheckTap(context, notifier, r),
                            child: Container(
                              width: 29,
                              height: 29,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: r.done
                                    ? AppColors.green
                                    : CupertinoColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: r.done
                                      ? AppColors.green
                                      : const Color(0xFFDFE3EE),
                                  width: 2,
                                ),
                              ),
                              child: r.done
                                  ? const Icon(
                                      CupertinoIcons.checkmark,
                                      size: 14,
                                      color: CupertinoColors.white,
                                    )
                                  : null,
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
      ),
    );
  }

  // ---------------- 勾选按钮点击处理 ----------------
  void _onCheckTap(
    BuildContext context,
    AppStateNotifier notifier,
    Reminder r,
  ) {
    // 已完成 → 直接取消，不弹确认框
    if (r.done) {
      final msg = notifier.toggleReminder(r.id);
      HapticFeedback.selectionClick();
      showToast(context, msg);
      return;
    }

    // 未完成 → 弹确认框
    final isRepeat = r.repeat > 0;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(r.title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            isRepeat ? '确认这次已完成？\n下次会在 ${_nextDateText(r)} 提醒你' : '确认已完成？',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              final msg = notifier.toggleReminder(r.id);
              HapticFeedback.mediumImpact();
              showToast(context, msg);
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  // ---------------- 删除确认框 ----------------
  void _confirmDelete(
    BuildContext context,
    AppStateNotifier notifier,
    Reminder r,
  ) {
    // 找到关联宠物名
    final state = ref.read(appStateProvider);
    final pet = state.pets.where((p) => p.id == r.petId).toList();
    final petName = pet.isNotEmpty ? '「${pet.first.name}」的' : '';

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除提醒'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '确定要删除${petName}「${r.title}」吗？\n删除后不可恢复。',
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
              notifier.deleteReminder(r.id);
              HapticFeedback.mediumImpact();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 计算重复提醒的下次日期（用于确认框文案）
  String _nextDateText(Reminder r) {
    try {
      final d = DateTime.parse(r.date).add(Duration(days: r.repeat));
      return fmtDate(d);
    } catch (_) {
      return '';
    }
  }

  // ---------------- 空态：无宠物 ----------------
  Widget _emptyNoPets(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 50, height: 1)),
          const SizedBox(height: 14),
          const Text(
            '先去「宠物」页添加一只\n才能设置提醒哦',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.muted,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 190,
            child: GestureDetector(
              onTap: () => context.go('/pets'),
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
                  '去添加宠物',
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

  // ---------------- 空态：无提醒 ----------------
  Widget _emptyList(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 52),
    child: Column(
      children: [
        const Text('📭', style: TextStyle(fontSize: 50, height: 1)),
        const SizedBox(height: 14),
        const Text(
          '还没有提醒\n加一个驱虫 / 疫苗提醒吧',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.7),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 190,
          child: GestureDetector(
            onTap: () => showReminderSheet(context, ref, null),
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
                '＋ 添加提醒',
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
  );
}

// 辅助：把 Reminder + 剩余天数封装起来
class _ItemWithDays {
  final Reminder r;
  final int days;
  _ItemWithDays(this.r, this.days);
}
