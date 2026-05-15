import 'package:budget_app/core/constants/app_colors.dart';
import 'package:budget_app/core/utils/currency_formatter.dart';
import 'package:budget_app/data/models/category.dart';
import 'package:budget_app/data/models/transaction.dart';
import 'package:budget_app/presentation/providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class TransactionStatistics extends ConsumerStatefulWidget {
  const TransactionStatistics({super.key});

  @override
  ConsumerState<TransactionStatistics> createState() =>
      _TransactionStatisticsState();
}

class _TransactionStatisticsState extends ConsumerState<TransactionStatistics> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsForMonthProvider);
    final categories = ref.watch(categoryNotifierProvider);

    final expenses = transactions.where((t) => t.isExpense).toList();
    final income = transactions.where((t) => !t.isExpense).toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold(0.0, (sum, t) => sum + t.amount);

    if (transactions.isEmpty) return const SizedBox.shrink();

    final categoryData = _buildCategoryData(expenses, categories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tab: Donut + breakdown ─────────────────────────
        _SectionTitle(title: 'Utgifter per kategori'),
        const Gap(12),

        if (categoryData.isEmpty)
          _emptyChart(context, 'Inga utgifter denna månad')
        else
          Column(
            children: [
              // ── Donut chart ──────────────────────────────
              _DonutChart(
                data: categoryData,
                total: totalExpenses,
                touchedIndex: _touchedIndex,
                onTouch: (i) => setState(
                    () => _touchedIndex = _touchedIndex == i ? null : i),
              ),
              const Gap(16),

              // ── Category breakdown list ──────────────────
              _CategoryBreakdownList(
                data: categoryData,
                total: totalExpenses,
                touchedIndex: _touchedIndex,
                onTap: (i) => setState(
                    () => _touchedIndex = _touchedIndex == i ? null : i),
              ),
            ],
          ),

        const Gap(24),

        // ── Weekly bar chart ───────────────────────────────
        _SectionTitle(title: 'Inkomst vs utgifter per vecka'),
        const Gap(12),
        _WeeklyBarChart(transactions: transactions),
        const Gap(8),

        // ── Income vs expense summary row ──────────────────
        _SummaryRow(totalIncome: totalIncome, totalExpenses: totalExpenses),
        const Gap(24),
      ],
    );
  }

  Widget _emptyChart(BuildContext context, String message) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
      ),
    );
  }

  // ── Build category data ────────────────────────────────────────

  List<_CategoryStat> _buildCategoryData(
    List<Transaction> expenses,
    List<Category> categories,
  ) {
    final Map<String, double> totals = {};
    for (final t in expenses) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }

    final result = totals.entries.map((e) {
      final cat = categories.cast<Category?>().firstWhere(
            (c) => c?.id == e.key,
            orElse: () => null,
          );
      return _CategoryStat(
        categoryId: e.key,
        name: cat?.name ?? 'Okänd',
        color: cat?.color ?? AppColors.primary,
        amount: e.value,
      );
    }).toList();

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryStat {
  final String categoryId;
  final String name;
  final Color color;
  final double amount;

  const _CategoryStat({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.amount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DONUT CHART
// ─────────────────────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.data,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<_CategoryStat> data;
  final double total;
  final int? touchedIndex;
  final ValueChanged<int> onTouch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 64,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    final idx = response?.touchedSection?.touchedSectionIndex;
                    if (idx != null) onTouch(idx);
                  }
                },
              ),
              sections: data.asMap().entries.map((e) {
                final i = e.key;
                final stat = e.value;
                final isTouched = touchedIndex == i;
                final pct = total > 0 ? stat.amount / total : 0.0;

                return PieChartSectionData(
                  value: stat.amount,
                  color: stat.color,
                  radius: isTouched ? 32 : 24,
                  showTitle: isTouched,
                  title: '${(pct * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Centre label ───────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (touchedIndex != null && touchedIndex! < data.length) ...[
                Text(
                  data[touchedIndex!].name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(2),
                Text(
                  CurrencyFormatter.formatCompact(data[touchedIndex!].amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: data[touchedIndex!].color,
                  ),
                ),
              ] else ...[
                Text(
                  'Totalt',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Gap(2),
                Text(
                  CurrencyFormatter.formatCompact(total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY BREAKDOWN LIST
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBreakdownList extends StatelessWidget {
  const _CategoryBreakdownList({
    required this.data,
    required this.total,
    required this.touchedIndex,
    required this.onTap,
  });

  final List<_CategoryStat> data;
  final double total;
  final int? touchedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: data.asMap().entries.map((e) {
          final i = e.key;
          final stat = e.value;
          final pct = total > 0 ? stat.amount / total : 0.0;
          final isTouched = touchedIndex == i;

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isTouched
                    ? stat.color.withOpacity(0.07)
                    : Colors.transparent,
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : i == data.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16))
                        : BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // ── Colour dot ──────────────────────
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: stat.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(10),

                        // ── Name ────────────────────────────
                        Expanded(
                          child: Text(
                            stat.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isTouched ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),

                        // ── Percentage ───────────────────────
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Gap(12),

                        // ── Amount ───────────────────────────
                        Text(
                          CurrencyFormatter.formatCompact(stat.amount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: stat.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Progress bar ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 0, 16, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor:
                              theme.colorScheme.onSurface.withOpacity(0.07),
                          valueColor: AlwaysStoppedAnimation(stat.color),
                        ),
                      ),
                    ),
                  ),

                  if (i < data.length - 1) const Divider(height: 1, indent: 36),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY BAR CHART
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyData = _buildWeeklyData();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: weeklyData
                  .expand((w) => [w.income, w.expenses])
                  .fold(0.0, (a, b) => a > b ? a : b) *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.cardTheme.color!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                final week = weeklyData[group.x];
                final amount = isIncome ? week.income : week.expenses;
                return BarTooltipItem(
                  '${isIncome ? "Inkomst" : "Utgift"}\n${CurrencyFormatter.formatCompact(amount)}',
                  TextStyle(
                    color: isIncome ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['V1', 'V2', 'V3', 'V4', 'V5'];
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.onSurface.withOpacity(0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: weeklyData.asMap().entries.map((e) {
            final i = e.key;
            final w = e.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: w.income,
                  color: AppColors.income,
                  width: 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: w.expenses,
                  color: AppColors.expense,
                  width: 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<_WeekData> _buildWeeklyData() {
    // 5 possible week slots per month (days 1-7, 8-14, 15-21, 22-28, 29+)
    final weeks = List.generate(5, (_) => _WeekData());

    for (final t in transactions) {
      final weekIndex = ((t.date.day - 1) / 7).floor().clamp(0, 4);
      if (t.isExpense) {
        weeks[weekIndex].expenses += t.amount;
      } else {
        weeks[weekIndex].income += t.amount;
      }
    }
    return weeks;
  }
}

class _WeekData {
  double income = 0;
  double expenses = 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY ROW
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalIncome,
    required this.totalExpenses,
  });

  final double totalIncome;
  final double totalExpenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _LegendDot(color: AppColors.income),
        const Gap(4),
        Text('Inkomst',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const Gap(4),
        Text(
          CurrencyFormatter.formatCompact(totalIncome),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.income,
          ),
        ),
        const Gap(16),
        _LegendDot(color: AppColors.expense),
        const Gap(4),
        Text('Utgift',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const Gap(4),
        Text(
          CurrencyFormatter.formatCompact(totalExpenses),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.expense,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
