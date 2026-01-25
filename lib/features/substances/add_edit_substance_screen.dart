import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class AddEditSubstanceScreen extends ConsumerStatefulWidget {
  const AddEditSubstanceScreen({this.toEdit, super.key});
  final Substance? toEdit;

  @override
  ConsumerState<AddEditSubstanceScreen> createState() =>
      _AddEditSubstanceState();
}

class _AddEditSubstanceState extends ConsumerState<AddEditSubstanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.toEdit?.name ?? '');
    _dosage = TextEditingController(text: widget.toEdit?.dosage ?? '');
    _notes = TextEditingController(text: widget.toEdit?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(substanceRepoProvider);

      if (widget.toEdit == null) {
        await repo.add(
          SubstancesCompanion.insert(
            name: _name.text.trim(),
            dosage: drift.Value(
              _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
            ),
            notes: drift.Value(
              _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          ),
        );
      } else {
        await repo.update(
          widget.toEdit!.copyWith(
            name: _name.text.trim(),
            dosage: drift.Value(
              _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
            ),
            notes: drift.Value(
              _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtleColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.toEdit == null
              ? 'Add Medication/Supplement'
              : 'Edit Medication/Supplement',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _dosage,
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g., 200 mg)',
                ),
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: null,
              ),
              const SizedBox(height: 20),
              // Subtle disclaimer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: subtleColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This app does not check for interactions. '
                      'Consult a healthcare provider before making changes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtleColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
