import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
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
  late Future<List<Task>> _tasksFuture;

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

  @override
  Widget build(BuildContext context) {
    // Detectăm dacă suntem în Dark Mode pentru a ajusta culorile header-ului
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DevBros Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage(email: widget.email)),
            ),
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                _buildHeader(isDarkMode),
                const Expanded(child: Center(child: Text("Nu ai task-uri momentan."))),
              ],
            );
          }

          final tasks = snapshot.data!;

          // SORTARE: Task-urile nefinalizate primele
          tasks.sort((a, b) {
            if (a.isCompleted == b.isCompleted) return 0;
            return a.isCompleted ? 1 : -1;
          });

          return Column(
            children: [
              _buildHeader(isDarkMode),
              _buildStatsHeader(tasks),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salut, ${widget.email.split('@')[0]}!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Iată progresul tău de astăzi:"),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<Task> tasks) {
    int completed = tasks.where((t) => t.isCompleted).length;
    int total = tasks.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _statCard("Total", total.toString(), Colors.blue),
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

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getPriorityColor(task.priority).withOpacity(0.2), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () async {
            try {
              await _taskService.updateTaskStatus(widget.token, task.id, !task.isCompleted);
              _refreshTasks();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : _getPriorityColor(task.priority),
            size: 30,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            _buildPriorityChip(task.priority),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(priority.toUpperCase(),
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(int taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ștergi task-ul?"),
        content: const Text("Această acțiune nu poate fi anulată."),
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

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';

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
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: "Prioritate", border: OutlineInputBorder()),
                  items: ['low', 'medium', 'high'].map((p) =>
                    DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                  onChanged: (val) => setDialogState(() => selectedPriority = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await _taskService.createTask(
                    widget.token,
                    titleController.text,
                    descController.text,
                    selectedPriority // <--- Acesta este al 4-lea argument
                  );
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
}