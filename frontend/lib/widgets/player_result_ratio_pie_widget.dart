import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerResultRatioPieWidget extends StatelessWidget {
  final int win;
  final int draw;
  final int loss;
  const PlayerResultRatioPieWidget({Key? key, required this.win, required this.draw, required this.loss}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = win + draw + loss;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final double chartSize = width < 400 ? 100 : 140;
    final double radius = width < 400 ? 28 : 40;
    final double centerSpace = width < 400 ? 20 : 32;
    String percent(int value) => total > 0 ? '${(value / total * 100).toStringAsFixed(0)}%' : '0%';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: chartSize,
          width: chartSize,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: win.toDouble(),
                  color: Colors.green,
                  title: percent(win),
                  radius: radius,
                  titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width < 400 ? 10 : 14),
                  showTitle: true,
                ),
                PieChartSectionData(
                  value: draw.toDouble(),
                  color: Colors.grey,
                  title: percent(draw),
                  radius: radius,
                  titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width < 400 ? 10 : 14),
                  showTitle: true,
                ),
                PieChartSectionData(
                  value: loss.toDouble(),
                  color: Colors.red,
                  title: percent(loss),
                  radius: radius,
                  titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: width < 400 ? 10 : 14),
                  showTitle: true,
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: centerSpace,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.green, label: 'Win'),
            const SizedBox(width: 12),
            _LegendDot(color: Colors.grey, label: 'Draw'),
            const SizedBox(width: 12),
            _LegendDot(color: Colors.red, label: 'Loss'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
} 