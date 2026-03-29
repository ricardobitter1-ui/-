import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/task_model.dart';
import '../theme/app_theme.dart';

class TaskFormModal extends ConsumerStatefulWidget {
  final TaskModel? initialTask;
  const TaskFormModal({super.key, this.initialTask});

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String _reminderType = 'none';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _locationTrigger = 'arrival';
  bool _attachLocation = false; 

  bool _isLoading = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    
    if (task != null) {
      _reminderType = task.reminderType ?? 'none';
      if (task.dueDate != null) {
        _selectedDate = task.dueDate;
        _selectedTime = TimeOfDay.fromDateTime(task.dueDate!);
      }
      _locationTrigger = task.locationTrigger ?? 'arrival';
      _attachLocation = task.latitude != null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DateTime? finalDueDate;
      if (_reminderType == 'datetime' && _selectedDate != null && _selectedTime != null) {
        finalDueDate = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          _selectedTime!.hour, _selectedTime!.minute,
        );
      }

      double? lat = widget.initialTask?.latitude;
      double? lng = widget.initialTask?.longitude;

      if (_reminderType == 'location' || (_attachLocation && lat == null)) {
        final position = await ref.read(locationServiceProvider).getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      } else if (!_attachLocation && _reminderType != 'location') {
        lat = null;
        lng = null;
      }

      final task = TaskModel(
        id: widget.initialTask?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isCompleted: widget.initialTask?.isCompleted ?? false,
        latitude: lat,
        longitude: lng,
        reminderType: _reminderType == 'none' ? null : _reminderType,
        dueDate: finalDueDate,
        locationTrigger: _reminderType == 'location' ? _locationTrigger : null,
        ownerId: widget.initialTask?.ownerId,
        groupId: widget.initialTask?.groupId,
      );

      // Gerenciar Notificação Local
      final ns = ref.read(notificationServiceProvider);
      
      // Se estamos editando, cancelamos a notificação antiga se ela existia
      // (Para simplificar, usamos o hash do ID como notifId se for edição,
      // ou o milisegundo atual se for novo. Idealmente o TaskModel teria um campo notifId).
      // Vamos usar task.id.hashCode como ID estável para notificações de uma tarefa específica.
      final notifId = task.id.isNotEmpty ? task.id.hashCode : DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (_reminderType == 'datetime' && finalDueDate != null) {
        if (finalDueDate.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aviso: O horário agendado precisa ser no futuro!'), backgroundColor: Colors.redAccent),
          );
          setState(() => _isLoading = false);
          return;
        }

        try {
          await ns.scheduleTaskReminder(
            notifId,
            task.title,
            task.description.isEmpty ? "Hora de completar sua tarefa!" : task.description,
            finalDueDate,
          );
        } catch (e) {
          print('Erro no agendamento: $e');
        }
      } else {
        // Se mudou para 'none' ou 'location', remove o alarme de data/hora se existir
        await ns.cancelNotification(notifId);
      }

      final fs = ref.read(firebaseServiceProvider);
      if (_isEditing) {
        await fs.updateTask(task);
      } else {
        await fs.addTask(task);
      }

      if (mounted) Navigator.of(context).pop(); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context, initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context, initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
      _selectedTime = pickedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEditing ? "Editar Tarefa" : "Nova Tarefa", style: Theme.of(context).textTheme.headlineMedium),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'O que você precisa fazer?'), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 12),
            TextField(controller: _descController, decoration: const InputDecoration(hintText: 'Detalhe a tarefa (opcional)'), maxLines: 2, textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 20),

            Text("Me lembre por:", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'none', label: Text('Sem Alarme'), icon: Icon(Icons.alarm_off)),
                ButtonSegment(value: 'datetime', label: Text('Data/Hora'), icon: Icon(Icons.calendar_today)),
                ButtonSegment(value: 'location', label: Text('Localização'), icon: Icon(Icons.place)),
              ],
              selected: {_reminderType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _reminderType = newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                selectedForegroundColor: AppTheme.primaryBlue,
              ),
            ),

            const SizedBox(height: 16),
            if (_reminderType == 'datetime') _buildDateTimeUI(),
            if (_reminderType == 'location') _buildLocationUI(),

            if (_reminderType != 'location') ...[
              const SizedBox(height: 8),
              _buildSimpleLocationAttach()
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditing ? "Salvar Alterações" : "Criar Tarefa"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeUI() {
    String dateText = 'Tocar para Escolher';
    if (_selectedDate != null && _selectedTime != null) {
      dateText = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} às ${_selectedTime!.format(context)}";
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(child: Text(dateText, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue))),
          TextButton(onPressed: _pickDateTime, child: const Text("ALTERAR")),
        ],
      ),
    );
  }

  Widget _buildLocationUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Disparar alerta invisível por GPS:", style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text("Ao Chegar no Local"),
                selected: _locationTrigger == 'arrival',
                onSelected: (val) { if(val) setState(() => _locationTrigger = 'arrival'); },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Ao Sair do Local"),
                selected: _locationTrigger == 'departure',
                onSelected: (val) { if(val) setState(() => _locationTrigger = 'departure'); },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
             "📍 O lembrete Geográfico captura sua coordenada.",
             style: TextStyle(fontSize: 12, color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _buildSimpleLocationAttach() {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         const Text("Anexar pino do mapa nesta tarefa?", style: TextStyle(color: Colors.grey)),
         Switch(value: _attachLocation, onChanged: (val) => setState(() => _attachLocation = val), activeColor: AppTheme.primaryBlue),
       ],
     );
  }
}
