import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
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
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  // ============ Page Head ============
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

                  // ============ 过滤 chips ============
                  _chipsRow(pets),

                  const SizedBox(height: 14),

                  // ============ 列表 ============
                  ..._buildList(context, notifier, state),
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

  // ---------------- 过滤 chips ----------------
  Widget _chipsRow(List<Pet> pets) {
    final items = <Widget>[
      _chip(label: '全部', id: 'all'),
      ...pets.map((p) => _chip(label: '${p.avatar} ${p.name}', id: p.id)),
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

  Widget _chip({required String label, required String id}) {
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: active ? CupertinoColors.white : AppColors.muted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
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
    final petName = pet.isNotEmpty
        ? '${pet.first.avatar}${pet.first.name}'
        : '';

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

    return GestureDetector(
      onTap: () => showReminderSheet(context, ref, r),
      child: Opacity(
        opacity: r.done ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
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
                        onTap: () => notifier.toggleReminder(r.id),
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
    );
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
