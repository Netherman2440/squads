import 'package:flutter/material.dart';

class PlayerH2HWidget extends StatelessWidget {
  final String playerName;
  final List<String> results; // e.g. ['W', 'L', 'D', 'W', 'X']
  final double scale;

  const PlayerH2HWidget({
    Key? key,
    required this.playerName,
    required this.results,
    this.scale = 1.0,
  }) : super(key: key);

  Color _tileColor(String result, BuildContext context) {
    switch (result) {
      case 'W':
        return Colors.green;
      case 'L':
        return Colors.red;
      case 'D':
        return Colors.grey;
      case 'X':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _textColor(String result) {
    switch (result) {
      case 'W':
      case 'L':
      case 'D':
        return Colors.white;
      case 'X':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double imageSize = 80;
    const double iconSize = 60;
    final double nameFontSize = Theme.of(context).textTheme.titleMedium?.fontSize ?? 18 * scale;
    final double tileSize = 40 * scale;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player image placeholder
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Icon(Icons.person, size: iconSize, color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.5)),
        ),
        SizedBox(height: 12 * scale),
        // Player name
        Text(
          playerName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: nameFontSize),
        ),
        SizedBox(height: 20 * scale),
        // Result tiles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final result = index < results.length ? results[index] : 'X';
            return Container(
              width: tileSize,
              height: tileSize,
              margin: EdgeInsets.symmetric(horizontal: 6 * scale),
              decoration: BoxDecoration(
                color: _tileColor(result, context),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Center(
                child: Text(
                  result,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _textColor(result),
                        fontSize: 22 * scale,
                      ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
} 