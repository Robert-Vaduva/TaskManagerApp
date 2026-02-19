import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final String email;
  final String token;

  const DashboardPage({super.key, required this.email, required this.token});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  late Future<List<Task>> _tasksFuture;

  String _selectedFilter = 'Toate';
  String _searchQuery = "";
  String _sortBy = 'priority';

  @override
  void initState() {
    super.initState();
    _tasksFuture = _taskService.getTasks(widget.token);
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _taskService.getTasks(widget.token);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Fără termen";
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return "";
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');

    return "$d.$m.$y la $h:$min";
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DevBros Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'priority', child: Text('Sortează după Prioritate')),
              const PopupMenuItem(value: 'date', child: Text('Sortează după cele mai noi')),
              const PopupMenuItem(value: 'alpha', child: Text('Sortează Alfabetic')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshTasks),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              final updatedEmail = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(email: widget.email, token: widget.token),
                ),
              );
              if (updatedEmail != null && updatedEmail != widget.email) {
                _refreshTasks();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Eroare: ${snapshot.error}"));
          }

          final allTasks = snapshot.data ?? [];

          final filteredTasks = allTasks.where((t) {
            bool matchesStatus = true;
            if (_selectedFilter == 'Active') matchesStatus = !t.isCompleted;
            if (_selectedFilter == 'Finalizate') matchesStatus = t.isCompleted;

            bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

            return matchesStatus && matchesSearch;
          }).toList();

          filteredTasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;

            switch (_sortBy) {
              case 'priority':
                const priorityWeights = {'high': 0, 'medium': 1, 'low': 2};
                return (priorityWeights[a.priority.toLowerCase()] ?? 1)
                    .compareTo(priorityWeights[b.priority.toLowerCase()] ?? 1);
              case 'date':
                return b.id.compareTo(a.id);
              case 'alpha':
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              default:
                return 0;
            }
          });

          return Column(
            children: [
              _buildHeader(isDarkMode),
              _buildStatsHeader(allTasks),
              _buildFilterRow(),
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(child: Text("Niciun task găsit."))
                    : RefreshIndicator(
                        onRefresh: () async {
                          _refreshTasks();
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        color: Colors.white,
                        backgroundColor: Colors.indigo,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return GestureDetector(
                              onLongPress: () => _showEditTaskDialog(task),
                              child: _buildTaskCard(task),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Task Nou"),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['Toate', 'Active', 'Finalizate'].map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) { if (val) setState(() => _selectedFilter = filter); },
              selectedColor: Colors.indigo.shade100,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    String selectedPriority = task.priority;
    DateTime? selectedDeadline = task.deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Editează Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Titlu")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Descriere")),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority.toLowerCase(),
                  decoration: const InputDecoration(labelText: "Prioritate", border: OutlineInputBorder()),
                  items: ['low', 'medium', 'high'].map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => selectedDeadline = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(selectedDeadline == null ? "Adaugă Termen" : _formatDate(selectedDeadline)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                await _taskService.updateTask(
                  widget.token, task.id, titleController.text,
                  descController.text, selectedPriority, selectedDeadline,
                );

                // --- PROGRAMARE NOTIFICARE LA EDITARE ---
                if (selectedDeadline != null) {
                  await _notificationService.scheduleNotification(
                    task.id,
                    "Task actualizat!",
                    "Termenul pentru '${titleController.text}' este acum.",
                    selectedDeadline!,
                  );
                }

                Navigator.pop(context);
                _refreshTasks();
              },
              child: const Text("Salvează"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    bool isExpired = task.deadline != null &&
                     task.deadline!.isBefore(DateTime.now()) &&
                     !task.isCompleted;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () async {
            bool newStatus = !task.isCompleted;
            await _taskService.updateTaskStatus(widget.token, task.id, newStatus);
            _refreshTasks();
          },
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : _getPriorityColor(task.priority),
            size: 32,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? Colors.grey
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.isCompleted
                        ? Colors.grey
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 4),
            _buildPriorityChip(task.priority),

            if (task.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 14, color: isExpired ? Colors.red : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.deadline),
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpired ? Colors.red : Colors.grey,
                        fontWeight: isExpired ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ],
                ),
              ),

            if (task.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Actualizat: ${_formatFullDate(task.updatedAt)}",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(task.id),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Widget _buildPriorityChip(String priority) {
    Color color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Adaugă Task Nou"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Titlu")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Descriere")),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(labelText: "Prioritate", border: OutlineInputBorder()),
                  items: ['low', 'medium', 'high'].map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => selectedPriority = val!),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => selectedDeadline = picked);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(selectedDeadline == null ? "Setează Termen" : _formatDate(selectedDeadline)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final newTask = await _taskService.createTask(
                    widget.token, titleController.text, descController.text,
                    selectedPriority, selectedDeadline,
                  );

                  // --- PROGRAMARE NOTIFICARE LA CREARE ---
                  if (selectedDeadline != null) {
                    await _notificationService.scheduleNotification(
                      newTask.id,
                      "Deadline Task!",
                      "Task-ul '${newTask.title}' a ajuns la termen.",
                      selectedDeadline!,
                    );
                  }

                  Navigator.pop(context);
                  _refreshTasks();
                }
              },
              child: const Text("Adaugă"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.shade50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salut, ${widget.email.split('@')[0]}!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Gestionează-ți eficient timpul."),
          const SizedBox(height: 15),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Caută un task...",
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<Task> tasks) {
    int completed = tasks.where((t) => t.isCompleted).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statCard("Total", tasks.length.toString(), Colors.blue),
          const SizedBox(width: 12),
          _statCard("Gata", completed.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ștergi task-ul?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Nu")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _taskService.deleteTask(widget.token, taskId);
              Navigator.pop(context);
              _refreshTasks();
            },
            child: const Text("Șterge", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}