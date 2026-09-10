// lib/pages/caregiver/caregiver_memories_tab.dart

import 'package:flutter/material.dart';
import '../../models/caregiver_models.dart';
import '../../services/caregiver_api_service.dart';

class CaregiverMemoriesTab extends StatefulWidget {
  const CaregiverMemoriesTab({super.key});
  @override
  State<CaregiverMemoriesTab> createState() => _CaregiverMemoriesTabState();
}

class _CaregiverMemoriesTabState extends State<CaregiverMemoriesTab> {
  static const Color _green = Color(0xFF214E3B);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _muted = Color(0xFF6B7F74);

  List<FamilyMemory> _memories = [];
  bool _loading = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _patientId ??= await CaregiverApiService.instance.savedPatientId;
    if (_patientId != null) {
      _memories =
          await CaregiverApiService.instance.fetchMemories(_patientId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(FamilyMemory m) async {
    final ok = await CaregiverApiService.instance.deleteMemory(m.id);
    if (ok) {
      setState(() => _memories.removeWhere((x) => x.id == m.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Memory removed')));
      }
    }
  }

  void _showDetail(FamilyMemory m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MemoryDetailSheet(memory: m, onDelete: () => _delete(m)),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMemorySheet(
        patientId: _patientId ?? '',
        onAdded: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: _green,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: const Text('Add Memory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF214E3B)))
          : RefreshIndicator(
              onRefresh: _load,
              color: _green,
              child: _memories.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_album_outlined,
                                    size: 56, color: _muted),
                                const SizedBox(height: 12),
                                Text('No memories yet',
                                    style: TextStyle(
                                        color: _muted, fontSize: 15)),
                                const SizedBox(height: 8),
                                Text('Tap + to add a family memory',
                                    style: TextStyle(
                                        color: _muted.withOpacity(0.7),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _memories.length,
                      itemBuilder: (_, i) => _MemoryCard(
                        memory: _memories[i],
                        onTap: () => _showDetail(_memories[i]),
                      ),
                    ),
            ),
    );
  }
}

// ── Memory Card ────────────────────────────────────────────────────────────────

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.onTap});
  final FamilyMemory memory;
  final VoidCallback onTap;

  static const Color _accent = Color(0xFF5F866D);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: memory.mediaUrl != null && memory.mediaUrl!.isNotEmpty
                    ? Image.network(
                        memory.mediaUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  if (memory.associatedPeople.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      memory.associatedPeople
                          .map((p) => p['name'] ?? '')
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: _accent),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFDCE8DA),
      child: const Center(
        child: Icon(Icons.photo_rounded,
            color: Color(0xFF5F866D), size: 40),
      ),
    );
  }
}

// ── Memory Detail Sheet ────────────────────────────────────────────────────────

class _MemoryDetailSheet extends StatelessWidget {
  const _MemoryDetailSheet(
      {required this.memory, required this.onDelete});
  final FamilyMemory memory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          if (memory.mediaUrl != null && memory.mediaUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(memory.mediaUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          const SizedBox(height: 16),
          Text(memory.title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          if (memory.description != null) ...[
            const SizedBox(height: 8),
            Text(memory.description!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A5A52))),
          ],
          if (memory.associatedPeople.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: memory.associatedPeople.map((p) {
                return Chip(
                  label: Text('${p['name']} · ${p['relation']}',
                      style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFDCE8DA),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Memory',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Add Memory Sheet ──────────────────────────────────────────────────────────

class _AddMemorySheet extends StatefulWidget {
  const _AddMemorySheet(
      {required this.patientId, required this.onAdded});
  final String patientId;
  final VoidCallback onAdded;

  @override
  State<_AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<_AddMemorySheet> {
  static const Color _green = Color(0xFF214E3B);
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _relCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _people = [];
  bool _saving = false;

  void _addPerson() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _people.add({
        'name': _nameCtrl.text.trim(),
        'relation': _relCtrl.text.trim(),
      });
      _nameCtrl.clear();
      _relCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await CaregiverApiService.instance.addMemory(
      patientId: widget.patientId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      mediaUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      associatedPeople: _people,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    if (ok) {
      widget.onAdded();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Memory added ✓')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to add memory')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Add Family Memory',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title *', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    labelText: 'Photo URL (optional)',
                    hintText: 'https://...',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Associated People',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              if (_people.isNotEmpty)
                Wrap(
                  spacing: 8, runSpacing: 4,
                  children: _people
                      .map((p) => Chip(
                            label: Text('${p['name']} · ${p['relation']}',
                                style: const TextStyle(fontSize: 12)),
                            onDeleted: () =>
                                setState(() => _people.remove(p)),
                            backgroundColor: const Color(0xFFDCE8DA),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _relCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Relation',
                          border: OutlineInputBorder(),
                          isDense: true),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    color: _green,
                    onPressed: _addPerson,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Memory',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
