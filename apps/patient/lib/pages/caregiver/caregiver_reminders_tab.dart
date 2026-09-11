// lib/pages/caregiver/caregiver_reminders_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../services/caregiver_api_service.dart';
import '../../services/locale_service.dart';

class CaregiverRemindersTab extends StatefulWidget {
  const CaregiverRemindersTab({super.key});
  @override
  State<CaregiverRemindersTab> createState() => _CaregiverRemindersTabState();
}

class _CaregiverRemindersTabState extends State<CaregiverRemindersTab> {
  static const Color _green = Color(0xFF214E3B);
  static const Color _accent = Color(0xFF5F866D);
  static const Color _ivory = Color(0xFFF8F5EC);
  static const Color _muted = Color(0xFF6B7F74);

  List<PatientReminder> _reminders = [];
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
      _reminders =
          await CaregiverApiService.instance.fetchReminders(_patientId!);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(PatientReminder r) async {
    final ok = await CaregiverApiService.instance.deleteReminder(r.id);
    if (ok) {
      setState(() => _reminders.removeWhere((x) => x.id == r.id));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('caregiver.reminderDeleted'))));
      }
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CreateReminderSheet(
        patientId: _patientId ?? '',
        onCreated: _load,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'acknowledged':
        return Colors.green.shade600;
      case 'missed':
        return Colors.red.shade600;
      case 'snoozed':
        return Colors.orange.shade600;
      default:
        return _accent;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication_outlined;
      case 'meal':
        return Icons.restaurant_outlined;
      case 'hydration':
        return Icons.water_drop_outlined;
      case 'activity':
        return Icons.directions_walk_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.alarm_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reminder_create_fab',
        onPressed: _showCreateSheet,
        backgroundColor: _green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.tr('caregiver.newReminder'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF214E3B)))
          : RefreshIndicator(
              onRefresh: _load,
              color: _green,
              child: _reminders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_none_rounded,
                                    size: 56, color: _muted),
                                const SizedBox(height: 12),
                                Text(context.tr('caregiver.noRemindersYet'),
                                    style:
                                        const TextStyle(color: _muted, fontSize: 15)),
                                const SizedBox(height: 8),
                                Text(context.tr('caregiver.tapToCreateReminder'),
                                    style: TextStyle(
                                        color: _muted.withValues(alpha: 0.7),
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _reminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = _reminders[i];
                        return Dismissible(
                          key: Key(r.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 28),
                          ),
                          onDismissed: (_) => _delete(r),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_typeIcon(r.type),
                                      color: _accent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.title,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text(
                                        DateFormat('hh:mm a · EEE, d MMM')
                                            .format(r.scheduledTime.toLocal()),
                                        style: const TextStyle(
                                            fontSize: 12, color: _muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(r.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r.status,
                                    style: TextStyle(
                                        color: _statusColor(r.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ── Create Reminder Bottom Sheet ─────────────────────────────────────────────

class _CreateReminderSheet extends StatefulWidget {
  const _CreateReminderSheet(
      {required this.patientId, required this.onCreated});
  final String patientId;
  final VoidCallback onCreated;

  @override
  State<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<_CreateReminderSheet> {
  static const Color _green = Color(0xFF214E3B);
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _voiceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _type = 'medication';
  String _repeat = 'daily';
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));
  bool _voiceEnabled = true;
  bool _saving = false;

  final List<String> _types = [
    'medication', 'meal', 'hydration', 'activity', 'appointment', 'custom'
  ];

  Future<void> _pickTime() async {
    final picked = await showDateTimePicker(context, _scheduledTime);
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await CaregiverApiService.instance.createReminder(
      patientId: widget.patientId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      scheduledTime: _scheduledTime,
      repeat: _repeat,
      isVoicePromptEnabled: _voiceEnabled,
      voicePromptText: _voiceCtrl.text.trim().isNotEmpty
          ? _voiceCtrl.text.trim()
          : _titleCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    if (ok) {
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('caregiver.reminderCreated'))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create reminder')));
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              const Text('New Reminder',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: _types
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time_rounded),
                label: Text(DateFormat('hh:mm a · EEE, d MMM').format(_scheduledTime)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _repeat,
                decoration: const InputDecoration(
                    labelText: 'Repeat', border: OutlineInputBorder()),
                items: ['none', 'daily', 'weekly', 'custom']
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _repeat = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _voiceEnabled,
                onChanged: (v) => setState(() => _voiceEnabled = v),
                title: const Text('Voice Prompt'),
                activeThumbColor: _green,
                contentPadding: EdgeInsets.zero,
              ),
              if (_voiceEnabled) ...[
                TextFormField(
                  controller: _voiceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Voice prompt text (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
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
                    : const Text('Create Reminder',
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
