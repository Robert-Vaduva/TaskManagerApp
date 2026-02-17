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
              setState(() {
                _sortBy = value;
              });
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
          }

          final allTasks = snapshot.data ?? [];

          // 1. FILTRARE COMBINATĂ (Status + Căutare)
          final filteredTasks = allTasks.where((t) {
            // Filtru de status
            bool matchesStatus = true;
            if (_selectedFilter == 'Active') matchesStatus = !t.isCompleted;
            if (_selectedFilter == 'Finalizate') matchesStatus = t.isCompleted;

            // Filtru de căutare
            bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

            return matchesStatus && matchesSearch;
          }).toList();

          // 2. SORTARE AVANSATĂ
          filteredTasks.sort((a, b) {
            // CRITERIUL 1: Task-urile nefinalizate apar mereu primele
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }

            // CRITERIUL 2: Dacă au același status, sortăm după preferința utilizatorului (_sortBy)
            switch (_sortBy) {
              case 'priority':
                // Mapăm prioritățile la valori numerice pentru comparare
                const priorityWeights = {'high': 0, 'medium': 1, 'low': 2};
                int weightA = priorityWeights[a.priority.toLowerCase()] ?? 1;
                int weightB = priorityWeights[b.priority.toLowerCase()] ?? 1;
                return weightA.compareTo(weightB);

              case 'date':
                // Sortăm după ID descrescător (presupunând că ID mai mare = task mai nou)
                return b.id.compareTo(a.id);

              case 'alpha':
                // Sortare alfabetică A-Z
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());

              default:
                return 0;
            }
          });

          return Column(
            children: [
              _buildHeader(isDarkMode),
              _buildStatsHeader(allTasks),
              _buildFilterRow(), // Rândul de filtre
              Expanded(
                child: filteredTasks.isEmpty
                  ? const Center(child: Text("Niciun task găsit."))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return GestureDetector(
                          onLongPress: () => _showEditTaskDialog(task), // Editare la long press
                          child: _buildTaskCard(task),
                        );
                      },
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

  // WIDGET FILTRE
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
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = filter);
              },
              selectedColor: Colors.indigo.shade100,
            ),
          );
        }).toList(),
      ),
    );
  }

  // DIALOG EDITARE
  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    String selectedPriority = task.priority;

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
                  initialValue: selectedPriority,
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
                await _taskService.updateTask(
                  widget.token,
                  task.id,
                  titleController.text,
                  descController.text,
                  selectedPriority
                );
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

  // Reutilizăm widget-urile tale existente (Header, Stats, Card)
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
          const Text("Gestionează-ți eficient timpul."),

          // --- TEXT DINAMIC SORTARE ---
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.sort, size: 14, color: Colors.indigo.withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(
                "Sortat după: ${_sortBy == 'priority' ? 'Prioritate' : _sortBy == 'date' ? 'Cele mai noi' : 'Nume'}",
                style: TextStyle(fontSize: 12, color: Colors.indigo.withOpacity(0.7)),
              ),
            ],
          ),
          // ----------------------------

          const SizedBox(height: 15),

          // BARA DE CĂUTARE
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Caută un task...",
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
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

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: GestureDetector(
          onTap: () async {
            try {
              // Trimitem valoarea opusă celei actuale
              bool newStatus = !task.isCompleted;
              await _taskService.updateTaskStatus(widget.token, task.id, newStatus);

              // Forțăm reîmprospătarea listei după ce primim confirmarea de la server
              _refreshTasks();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newStatus ? "Task finalizat!" : "Task redeschis"),
                  duration: const Duration(seconds: 1),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Eroare server: $e")),
              );
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
        subtitle: _buildPriorityChip(task.priority),
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
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Adaugă Task Nou"),
          content: Column(
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await _taskService.createTask(widget.token, titleController.text, descController.text, selectedPriority);
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