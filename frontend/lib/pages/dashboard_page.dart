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
  final List<String> _categories = ["General", "Muncă", "Personal", "Urgent", "Hobby"];

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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.blue;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'muncă': return Colors.blue;
      case 'personal': return Colors.green;
      case 'urgent': return Colors.red;
      case 'hobby': return Colors.orange;
      default: return Colors.blueGrey;
    }
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
            onSelected: (String value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
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
                MaterialPageRoute(builder: (context) => ProfilePage(email: widget.email, token: widget.token)),
              );
              if (updatedEmail != null) _refreshTasks();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Eroare: ${snapshot.error}"));

          final allTasks = snapshot.data ?? [];
          final filteredTasks = allTasks.where((t) {
            bool matchesStatus = _selectedFilter == 'Toate' || (_selectedFilter == 'Active' ? !t.isCompleted : t.isCompleted);
            bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            return matchesStatus && matchesSearch;
          }).toList();

          filteredTasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
            switch (_sortBy) {
              case 'priority':
                const weights = {'high': 0, 'medium': 1, 'low': 2};
                return (weights[a.priority.toLowerCase()] ?? 1).compareTo(weights[b.priority.toLowerCase()] ?? 1);
              case 'date': return b.id!.compareTo(a.id!);
              case 'alpha': return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              default: return 0;
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
                        onRefresh: () async => _refreshTasks(),
                        child: ListView.builder(
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Task Nou", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    bool isExpired = task.deadline != null && task.deadline!.isBefore(DateTime.now()) && !task.isCompleted;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: IconButton(
          icon: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : _getPriorityColor(task.priority),
            size: 30,
          ),
          onPressed: () async {
            await _taskService.updateTaskStatus(widget.token, task.id!, !task.isCompleted);
            _refreshTasks();
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(task.description!)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPriorityChip(task.priority),
                _buildCategoryChip(task.category),
              ],
            ),
            if (task.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isExpired ? Colors.red : Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatDate(task.deadline), style: TextStyle(color: isExpired ? Colors.red : Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(task.id!),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color = _getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(category, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    String category = 'General';
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Task Nou"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Titlu")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Descriere")),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: "Categorie", border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: "Prioritate", border: OutlineInputBorder()),
                  items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => deadline = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(deadline == null ? "Setează Termen" : _formatDate(deadline)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final t = await _taskService.createTask(widget.token, titleController.text, descController.text, priority, category, deadline);
                  if (deadline != null) await _notificationService.scheduleNotification(t.id!, "Deadline!", "Task: ${t.title}", deadline!);
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

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    String priority = task.priority;
    String category = task.category;
    DateTime? deadline = task.deadline;

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
                  value: category,
                  decoration: const InputDecoration(labelText: "Categorie", border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: "Prioritate", border: OutlineInputBorder()),
                  items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => priority = val!),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: deadline ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setDialogState(() => deadline = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_formatDate(deadline)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                await _taskService.updateTask(widget.token, task.id!, titleController.text, descController.text, priority, category, deadline);
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark ? Colors.indigo.withOpacity(0.1) : Colors.indigo.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salut, ${widget.email.split('@')[0]}!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Iată ce ai de făcut astăzi:"),
          const SizedBox(height: 12),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Caută task-uri...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<Task> tasks) {
    int completed = tasks.where((t) => t.isCompleted).length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statCard("Total", "${tasks.length}", Colors.blue),
          const SizedBox(width: 12),
          _statCard("Finalizate", "$completed", Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['Toate', 'Active', 'Finalizate'].map((f) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: _selectedFilter == f,
            onSelected: (s) => setState(() => _selectedFilter = f),
          ),
        )).toList(),
      ),
    );
  }

  void _confirmDelete(int taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ștergi acest task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Nu")),
          TextButton(onPressed: () async {
            await _taskService.deleteTask(widget.token, taskId);
            Navigator.pop(context);
            _refreshTasks();
          }, child: const Text("Da, șterge", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}