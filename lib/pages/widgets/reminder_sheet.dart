import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reminder.dart';
import '../../providers/app_state.dart';
import '../../theme/app_colors.dart';
import 'sheet_widgets.dart';
import '../../widgets/pet_avatar.dart';

const _types = [
  MapEntry('deworm', '🪱 驱虫'),
  MapEntry('vaccine', '💉 疫苗'),
  MapEntry('weight', '⚖️ 称重'),
  MapEntry('bath', '🛁 洗澡'),
  MapEntry('checkup', '🩺 体检'),
  MapEntry('other', '📌 其他'),
];

const _typeDefaultTitle = {
  'deworm': '体内驱虫',
  'vaccine': '疫苗',
  'weight': '称体重',
  'bath': '洗澡',
  'checkup': '体检',
  'other': '',
};

const _repeatOptions = [
  MapEntry(0, '不重复'),
  MapEntry(7, '每周'),
  MapEntry(30, '每月'),
  MapEntry(90, '每 3 个月'),
  MapEntry(180, '每半年'),
  MapEntry(365, '每年'),
];

void showReminderSheet(BuildContext context, WidgetRef ref, Reminder? r) {
  showCupertinoModalPopup(
    context: context,
    barrierColor: const Color(0x6B0C0F19),
    builder: (_) => ReminderSheet(reminder: r),
  );
}

class ReminderSheet extends ConsumerStatefulWidget {
  final Reminder? reminder;
  const ReminderSheet({super.key, this.reminder});
  @override
  ConsumerState<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<ReminderSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late String _petId;
  late String _type;
  late DateTime _date;
  late int _repeat;

  @override
  void initState() {
    super.initState();
    final pets = ref.read(appStateProvider).pets;
    final r = widget.reminder;
    _petId = r?.petId ?? (pets.isNotEmpty ? pets.first.id : '');
    _type = r?.type ?? 'deworm';
    _titleCtrl = TextEditingController(
      text: r?.title ?? _typeDefaultTitle[_type] ?? '',
    );
    _noteCtrl = TextEditingController(text: r?.note ?? '');
    _date = (r != null && r.date.isNotEmpty)
        ? (DateTime.tryParse(r.date) ?? DateTime.now())
        : DateTime.now();
    _repeat = r?.repeat ?? 90;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final notifier = ref.read(appStateProvider.notifier);
    final data = Reminder(
      id: widget.reminder?.id ?? uid(),
      petId: _petId,
      type: _type,
      title: title,
      date: fmtDate(_date),
      repeat: _repeat,
      note: _noteCtrl.text.trim(),
    );

    if (widget.reminder != null) {
      notifier.updateReminder(data);
    } else {
      notifier.addReminder(data);
    }

    Navigator.pop(context);
  }

  // ---------------- 删除确认框 ----------------
  void _confirmDelete(BuildContext context) {
    final r = widget.reminder;
    if (r == null) return;

    // 找到关联宠物名
    final pets = ref.read(appStateProvider).pets;
    final pet = pets.where((p) => p.id == r.petId).toList();
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
              Navigator.pop(ctx); // 关确认框
              HapticFeedback.mediumImpact();
              ref.read(appStateProvider.notifier).deleteReminder(r.id);
              Navigator.pop(context); // 关弹层
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(appStateProvider).pets;
    final title = widget.reminder != null ? '编辑提醒' : '添加提醒';

    return SheetShell(
      title: title,
      children: [
        SheetField(
          label: '哪只宝贝',
          child: SheetChipsRow<String>(
            value: _petId,
            options: pets
                .map(
                  (p) => MapEntry(
                    p.id,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PetAvatar(avatar: p.avatar, size: 20, radius: 6),
                        const SizedBox(width: 6),
                        Text(p.name),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _petId = v),
          ),
        ),
        SheetField(
          label: '提醒类型',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final active = _type == t.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _type = t.key;
                    final cur = _titleCtrl.text.trim();
                    if (cur.isEmpty || _typeDefaultTitle.containsValue(cur)) {
                      _titleCtrl.text = _typeDefaultTitle[t.key] ?? '';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.line,
                    ),
                  ),
                  child: Text(
                    t.value,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: active ? CupertinoColors.white : AppColors.muted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SheetField(
          label: '提醒内容',
          child: SheetTextField(controller: _titleCtrl, placeholder: '比如：体内驱虫'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SheetField(
                label: '日期',
                child: SheetDateField(
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: SheetField(
                label: '重复周期',
                child: SheetSelect<int>(
                  value: _repeat,
                  options: _repeatOptions,
                  onChanged: (v) => setState(() => _repeat = v),
                ),
              ),
            ),
          ],
        ),
        SheetField(
          label: '备注（可选）',
          child: SheetTextField(
            controller: _noteCtrl,
            placeholder: '药品名 / 医院…',
          ),
        ),
        PrimaryButton(text: '保存提醒', onTap: _save),
        if (widget.reminder != null)
          GhostButton(
            text: '删除提醒',
            danger: true,
            onTap: () => _confirmDelete(context),
          ),
      ],
    );
  }
}
