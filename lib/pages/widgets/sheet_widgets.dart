import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';

// =============================================================
// Sheet 外壳：白底、顶部圆角 26px、阴影、handle、标题
// =============================================================
class SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SheetShell({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F0A0F1E),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle 38×4 圆角 4 #e2e5ee
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E5EE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // title 18px w800 letter-spacing -.3
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.text,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              // body padding: 0 20px 34px
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 34 + bottomInset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SheetField：label 12px muted w600 + 7px gap + 控件
// =============================================================
class SheetField extends StatelessWidget {
  final String label;
  final Widget child;
  const SheetField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

// =============================================================
// 输入框：CupertinoTextField（Material TextField 在 CupertinoApp 下会崩）
// =============================================================
class SheetTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool obscureText;

  const SheetTextField({
    super.key,
    required this.controller,
    this.placeholder = '',
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  State<SheetTextField> createState() => _SheetTextFieldState();
}

class _SheetTextFieldState extends State<SheetTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 46,
      decoration: BoxDecoration(
        color: _focused ? CupertinoColors.white : const Color(0xFFFAFBFD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.line,
          width: 1.5,
        ),
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        cursorColor: AppColors.primary,
        placeholder: widget.placeholder,
        placeholderStyle: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFFC2C8D6),
        ),
        style: const TextStyle(
          fontSize: 15.5,
          color: AppColors.text,
          height: 1.2,
        ),
        decoration: null,
        padding: const EdgeInsets.symmetric(horizontal: 13),
      ),
    );
  }
}

// =============================================================
// 日期字段：点击弹出「现代日历」弹层
// =============================================================
class SheetDateField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? maximumDate;

  const SheetDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.maximumDate,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _open(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: const Color(0x6B0C0F19),
      builder: (_) => _CalendarPopup(
        initial: value,
        maximumDate: maximumDate,
        onConfirm: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _fmt(value),
                style: const TextStyle(fontSize: 15.5, color: AppColors.text),
              ),
            ),
            const Icon(
              CupertinoIcons.calendar,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 日历弹层（现代风格）
// =============================================================
class _CalendarPopup extends StatefulWidget {
  final DateTime initial;
  final DateTime? maximumDate;
  final ValueChanged<DateTime> onConfirm;

  const _CalendarPopup({
    required this.initial,
    required this.onConfirm,
    this.maximumDate,
  });

  @override
  State<_CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<_CalendarPopup> {
  late DateTime _month; // 当前显示的月份（1 号）
  late DateTime _selected; // 选中的日期

  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];
  static const _monthNames = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initial.year,
      widget.initial.month,
      widget.initial.day,
    );
    _month = DateTime(_selected.year, _selected.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDisabled(DateTime d) {
    if (widget.maximumDate == null) return false;
    final max = widget.maximumDate!;
    final m = DateTime(max.year, max.month, max.day);
    return d.isAfter(m);
  }

  void _prevMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final today = DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 14, bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E5EE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ---------- 顶部：年月 + 切换箭头 ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_month.year}年 ${_monthNames[_month.month - 1]}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                _iconBtn(icon: CupertinoIcons.chevron_left, onTap: _prevMonth),
                const SizedBox(width: 6),
                _iconBtn(icon: CupertinoIcons.chevron_right, onTap: _nextMonth),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---------- 星期行 ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _weekdays.map((w) {
                return Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // ---------- 日期网格 ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CalendarGrid(
              month: _month,
              selected: _selected,
              today: today,
              isDisabled: _isDisabled,
              isSameDay: _isSameDay,
              onPick: (d) => setState(() => _selected = d),
            ),
          ),
          const SizedBox(height: 8),

          // ---------- 底部按钮 ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onConfirm(_selected);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
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
                        '确定',
                        style: TextStyle(
                          fontSize: 15,
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
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppColors.text),
      ),
    );
  }
}

// =============================================================
// 日历网格
// =============================================================
class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final bool Function(DateTime) isDisabled;
  final bool Function(DateTime, DateTime) isSameDay;
  final ValueChanged<DateTime> onPick;

  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.today,
    required this.isDisabled,
    required this.isSameDay,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // 本月第一天是星期几（0 = 周日）
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    // 本月有多少天
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 上个月有多少天
    final prevMonthDays = DateTime(month.year, month.month, 0).day;

    final cells = <Widget>[];

    // 前导：上月末尾
    for (int i = firstWeekday - 1; i >= 0; i--) {
      final d = prevMonthDays - i;
      cells.add(
        _buildDay(
          DateTime(month.year, month.month - 1, d),
          isCurrentMonth: false,
        ),
      );
    }
    // 本月
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(
        _buildDay(DateTime(month.year, month.month, d), isCurrentMonth: true),
      );
    }
    // 后补：下月开头，凑满整周
    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;
    for (int d = 1; cells.length < totalCells; d++) {
      cells.add(
        _buildDay(
          DateTime(month.year, month.month + 1, d),
          isCurrentMonth: false,
        ),
      );
    }

    return Column(
      children: [
        for (int row = 0; row < cells.length ~/ 7; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: cells
                  .sublist(row * 7, row * 7 + 7)
                  .map((c) => Expanded(child: c))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDay(DateTime date, {required bool isCurrentMonth}) {
    final isSelected = isSameDay(date, selected);
    final isToday = isSameDay(date, today);
    final disabled = isDisabled(date) || !isCurrentMonth;

    return GestureDetector(
      onTap: disabled ? null : () => onPick(date),
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday && isCurrentMonth
                        ? AppColors.primarySoft
                        : const Color(0x00000000)),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: Color(0x52FF7A59),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? CupertinoColors.white
                    : disabled
                    ? const Color(0xFFD0D4E0)
                    : isToday
                    ? AppColors.primary
                    : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 下拉选择：点击弹出 CupertinoPicker
// =============================================================
class SheetSelect<T> extends StatelessWidget {
  final T value;
  final List<MapEntry<T, String>> options;
  final ValueChanged<T> onChanged;

  const SheetSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  void _open(BuildContext context) {
    int index = options.indexWhere((e) => e.key == value);
    if (index < 0) index = 0;
    final ctrl = FixedExtentScrollController(initialItem: index);

    showCupertinoModalPopup(
      context: context,
      barrierColor: const Color(0x6B0C0F19),
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.white,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('完成'),
                    onPressed: () {
                      onChanged(options[ctrl.selectedItem].key);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: ctrl,
                itemExtent: 40,
                onSelectedItemChanged: (_) {},
                children: options
                    .map(
                      (e) => Center(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = options
        .firstWhere((e) => e.key == value, orElse: () => options.first)
        .value;

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15.5, color: AppColors.text),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Emoji 选择器：44×44、radius14、gap 8、active 时主色边框 + 缩放
// =============================================================
class EmojiPicker extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const EmojiPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((e) {
        final active = e == value;
        return GestureDetector(
          onTap: () => onChanged(e),
          child: AnimatedScale(
            scale: active ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primarySoft : const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppColors.primary : const Color(0x00000000),
                  width: 2,
                ),
              ),
              child: Text(e, style: const TextStyle(fontSize: 23, height: 1)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================
// 分段控件：bg #f3f5f9、radius13、padding4、active 白底 + 阴影
// =============================================================
class SegControl<T> extends StatelessWidget {
  final T value;
  final List<MapEntry<T, String>> options;
  final ValueChanged<T> onChanged;

  const SegControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: options.map((e) {
          final active = e.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? CupertinoColors.white
                      : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: active ? AppColors.text : AppColors.muted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================
// 水平 chips 选择器
// =============================================================
class SheetChipsRow<T> extends StatelessWidget {
  final T value;
  final List<MapEntry<T, String>> options;
  final ValueChanged<T> onChanged;

  const SheetChipsRow({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = options[i];
          final active = e.key == value;
          return GestureDetector(
            onTap: () => onChanged(e.key),
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
                e.value,
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
}

// =============================================================
// 主按钮：radius14、padding14、shadow 0 8 18 主色 32%
// =============================================================
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const PrimaryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: onTap,
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
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 幽灵按钮：透明底、muted 色（danger 时红色）
// =============================================================
class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool danger;

  const GhostButton({
    super.key,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: danger ? AppColors.red : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
