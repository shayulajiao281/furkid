import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'widgets/weight_sheet.dart';
import '../widgets/pet_avatar.dart';

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
        child: Column(
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

            // ============ 固定 chips ============
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _chipsRow(pets),
            ),

            const SizedBox(height: 14),

            // ============ 只有内容滚动 ============
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  _hero(latest, prev),
                  const SizedBox(height: 13),
                  _chartCard(recs),
                  const SizedBox(height: 13),
                  if (recs.isNotEmpty) _history(notifier, recs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 加号按钮 ----------------
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
      child: const Icon(
        CupertinoIcons.plus,
        size: 20,
        color: CupertinoColors.white,
      ),
    ),
  );

  // ---------------- chips ----------------
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
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12.5,
                  color: active ? CupertinoColors.white : AppColors.muted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PetAvatar(avatar: p.avatar, size: 20, radius: 6),
                    const SizedBox(width: 6),
                    Text(p.name),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- Hero ----------------
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
            color: Color(0x4DFF6B8A),
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

  // ---------------- 折线图卡片 ----------------
  Widget _chartCard(List<dynamic> recs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '体重趋势',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: recs.length < 2 ? _chartEmpty() : _chart(recs),
          ),
        ],
      ),
    );
  }

  Widget _chartEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('📈', style: TextStyle(fontSize: 32, height: 1)),
        SizedBox(height: 8),
        Text(
          '记录 2 次以上就能看到趋势曲线啦',
          style: TextStyle(fontSize: 12.5, color: AppColors.muted),
        ),
      ],
    ),
  );

  Widget _chart(List<dynamic> recs) {
    final spots = <FlSpot>[];
    for (int i = 0; i < recs.length; i++) {
      spots.add(FlSpot(i.toDouble(), recs[i].value.toDouble()));
    }

    final vals = recs.map((r) => r.value as double).toList();
    double minY = vals.reduce((a, b) => a < b ? a : b);
    double maxY = vals.reduce((a, b) => a > b ? a : b);
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }
    final pad = (maxY - minY) * 0.25;
    minY -= pad;
    maxY += pad;

    String labelOf(int i) {
      final date = recs[i].date as String;
      final parts = date.split('-');
      return parts.length >= 3 ? '${parts[1]}/${parts[2]}' : date;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (recs.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 2,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFEEF0F6), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: (maxY - minY) / 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 9, color: Color(0xFFA8AFC0)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= recs.length) {
                  return const SizedBox.shrink();
                }
                final show = i == 0 || i == recs.length - 1;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labelOf(i),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA8AFC0),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E2231),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((t) {
                final i = t.x.toInt();
                final date = recs[i].date as String;
                return LineTooltipItem(
                  '$date\n${t.y.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            color: AppColors.primary,
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, i) {
                final isLast = i == spots.length - 1;
                return FlDotCirclePainter(
                  radius: isLast ? 5 : 3.2,
                  color: isLast ? AppColors.primary : CupertinoColors.white,
                  strokeWidth: isLast ? 3 : 2,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.26),
                  AppColors.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 历史 ----------------
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
                    onTap: () => _confirmDeleteWeight(notifier, r),
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

  // 删除体重确认
  void _confirmDeleteWeight(AppStateNotifier notifier, dynamic r) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除记录'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '确定要删除 ${r.date} 的 ${r.value} kg 记录吗？',
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
              HapticFeedback.mediumImpact();
              notifier.deleteWeight(r.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // ---------------- 空态 ----------------
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
