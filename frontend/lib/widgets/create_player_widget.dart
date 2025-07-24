import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squads/models/player.dart';
import 'package:squads/models/position.dart';
import 'package:squads/services/player_service.dart';

class CreatePlayerWidget extends ConsumerStatefulWidget {
  final VoidCallback? onPlayerCreated;
  final String squadId;

  const CreatePlayerWidget({
    super.key,
    this.onPlayerCreated,
    required this.squadId,
  });

  @override
  ConsumerState<CreatePlayerWidget> createState() => _CreatePlayerWidgetState();
}

class _CreatePlayerWidgetState extends ConsumerState<CreatePlayerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController();
  Position _selectedPosition = Position.none; // Keep for API compatibility
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _createPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final playerCreate = PlayerCreate(
        name: _nameController.text.trim(),
        baseScore: int.parse(_scoreController.text),
        position: _selectedPosition, // Still send position for backend compatibility
      );

      await PlayerService.instance.createPlayer(widget.squadId, playerCreate);
      
      // Clear form
      _nameController.clear();
      _scoreController.clear();
      // Keep _selectedPosition as Position.none

      // Notify parent
      widget.onPlayerCreated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracz został utworzony')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dodaj nowego gracza',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa gracza',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa jest wymagana';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scoreController,
                decoration: const InputDecoration(
                  labelText: 'Punktacja bazowa',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Punktacja jest wymagana';
                  }
                  final score = int.tryParse(value);
                  if (score == null || score < 0) {
                    return 'Wprowadź poprawną liczbę';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPlayer,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Dodaj gracza'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 