import 'package:flutter/material.dart';
import '../theme/color_utils.dart';
import '../theme/app_theme.dart';

/// Demo widget showcasing the color palette and theme switching
class ColorDemoWidget extends StatefulWidget {
  const ColorDemoWidget({super.key});

  @override
  State<ColorDemoWidget> createState() => _ColorDemoWidgetState();
}

class _ColorDemoWidgetState extends State<ColorDemoWidget> {
  bool _isDark = true;

  ThemeData get _theme => _isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
  bool get _isLight => !_isDark;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Color Palette Demo'),
          actions: [
            Row(
              children: [
                const Icon(Icons.light_mode),
                Switch(
                  value: _isDark,
                  onChanged: (val) {
                    setState(() => _isDark = val);
                  },
                ),
                const Icon(Icons.dark_mode),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Background Colors', [
                _buildColorCard('bgDark', ColorUtils.bgDark),
                _buildColorCard('bg', ColorUtils.bg),
                _buildColorCard('bgLight', ColorUtils.bgLight),
              ]),
              const SizedBox(height: 24),
              _buildSection('Text Colors', [
                _buildColorCard('text', ColorUtils.text),
                _buildColorCard('textMuted', ColorUtils.textMuted),
              ]),
              const SizedBox(height: 24),
              _buildSection('Border Colors', [
                _buildColorCard('border', ColorUtils.border),
                _buildColorCard('borderMuted', ColorUtils.borderMuted),
                _buildColorCard('highlight', ColorUtils.highlight),
              ]),
              const SizedBox(height: 24),
              _buildSection('Semantic Colors', [
                _buildColorCard('primary', ColorUtils.primary),
                _buildColorCard('secondary', ColorUtils.secondary),
                _buildColorCard('success', ColorUtils.success),
                _buildColorCard('warning', ColorUtils.warning),
                _buildColorCard('danger', ColorUtils.danger),
                _buildColorCard('info', ColorUtils.info),
              ]),
              const SizedBox(height: 24),
              _buildSection('Action Colors (Primary & Secondary)', [
                _buildPrimarySecondaryDemo(),
              ]),
              const SizedBox(height: 24),
              _buildSection('Interactive Elements', [
                _buildButtonDemo(),
                _buildInputDemo(),
                _buildCardDemo(),
              ]),
              const SizedBox(height: 24),
              _buildSection('Status Indicators', [
                _buildStatusDemo(),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final titleColor = Theme.of(context).textTheme.titleLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children,
        ),
      ],
    );
  }

  Widget _buildColorCard(String name, Color color) {
    if (_isLight) {
      // In light mode, use Card for elevation and no border
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide.none,
        ),
        child: Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // In dark mode, use border
      return Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorUtils.borderMuted),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPrimarySecondaryDemo() {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: ColorUtils.primary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            const Text('primary'),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.primary,
                foregroundColor: ColorUtils.bgDark,
              ),
              onPressed: () {},
              child: const Text('Primary Btn'),
            ),
          ],
        ),
        const SizedBox(width: 32),
        Column(
          children: [
            Container(
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: ColorUtils.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            const Text('secondary'),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.secondary,
                foregroundColor: ColorUtils.bgDark,
              ),
              onPressed: () {},
              child: const Text('Secondary Btn'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButtonDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buttons',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorUtils.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Primary'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Secondary'),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Text'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Input Fields',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorUtils.text,
          ),
        ),
        const SizedBox(height: 8),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Sample Input',
            hintText: 'Enter text here...',
          ),
        ),
      ],
    );
  }

  Widget _buildCardDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cards',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorUtils.text,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sample Card',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorUtils.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a sample card demonstrating the card theme with proper colors.',
                  style: TextStyle(color: ColorUtils.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Colors',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorUtils.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusChip('Success', ColorUtils.success),
            _buildStatusChip('Warning', ColorUtils.warning),
            _buildStatusChip('Danger', ColorUtils.danger),
            _buildStatusChip('Info', ColorUtils.info),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 