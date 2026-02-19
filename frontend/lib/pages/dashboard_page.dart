import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import 'profile_page.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _selectedCategoryFilter = 'Toate';
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

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      case ThemeMode.system: return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DevBros Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, // Am centrat titlul pentru a se alinia cu design-ul constrâns
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(_getThemeIcon(currentMode)),
                tooltip: "Schimbă Tema",
                onSelected: (ThemeMode mode) async {
                  themeNotifier.value = mode;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('themeMode', mode.index);
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: ThemeMode.light, child: _ThemeItem(Icons.light_mode, 'Light')),
                  const PopupMenuItem(value: ThemeMode.dark, child: _ThemeItem(Icons.dark_mode, 'Dark')),
                  const PopupMenuItem(value: ThemeMode.system, child: _ThemeItem(Icons.brightness_auto, 'Auto')),
                ],
              );
            },
          ),
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
      // --- MODIFICARE: Centrare și ConstrainedBox ---
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<List<Task>>(
            future: _tasksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Eroare: ${snapshot.error}"));

              final allTasks = snapshot.data ?? [];
              final filteredTasks = allTasks.where((t) {
                bool matchesStatus = _selectedFilter == 'Toate' || (_selectedFilter == 'Active' ? !t.isCompleted : t.isCompleted);
                bool matchesCategory = _selectedCategoryFilter == 'Toate' || t.category == _selectedCategoryFilter;
                bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                     (t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                return matchesStatus && matchesCategory && matchesSearch;
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
                              itemBuilder: (context, index) => GestureDetector(
                                onLongPress: () => _showEditTaskDialog(filteredTasks[index]),
                                child: _buildTaskCard(filteredTasks[index]),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // --- SFÂRȘIT MODIFICARE ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Task Nou", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Toate metodele rămân identice de aici în jos...
  Widget _buildFilterRow() {
    return Column(
      children: [
        SingleChildScrollView(
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
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: ['Toate', ..._categories].map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c, style: const TextStyle(fontSize: 12)),
                selected: _selectedCategoryFilter == c,
                onSelected: (s) => setState(() => _selectedCategoryFilter = c),
                selectedColor: _getCategoryColor(c).withOpacity(0.3),
              ),
            )).toList(),
          ),
        ),
      ],
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
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
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

  void _showAddTaskDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    String p = 'medium', c = 'General';
    DateTime? d;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text("Task Nou"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleC, decoration: const InputDecoration(labelText: "Titlu")),
                TextField(controller: descC, decoration: const InputDecoration(labelText: "Descriere")),
                const SizedBox(height: 15),
                _buildDropdown("Categorie", c, _categories, (v) => setS(() => c = v!)),
                const SizedBox(height: 10),
                _buildDropdown("Prioritate", p, ['low', 'medium', 'high'], (v) => setS(() => p = v!)),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                    if (picked != null) setS(() => d = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(d == null ? "Setează Termen" : _formatDate(d)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                if (titleC.text.isNotEmpty) {
                  final t = await _taskService.createTask(widget.token, titleC.text, descC.text, p, c, d);
                  if (d != null) await _notificationService.scheduleNotification(t.id!, "Deadline!", t.title, d!);
                  Navigator.pop(ctx);
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
    final titleC = TextEditingController(text: task.title);
    final descC = TextEditingController(text: task.description);
    String p = task.priority, c = task.category;
    DateTime? d = task.deadline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text("Editează Task"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleC, decoration: const InputDecoration(labelText: "Titlu")),
                TextField(controller: descC, decoration: const InputDecoration(labelText: "Descriere")),
                const SizedBox(height: 15),
                _buildDropdown("Categorie", c, _categories, (v) => setS(() => c = v!)),
                const SizedBox(height: 10),
                _buildDropdown("Prioritate", p, ['low', 'medium', 'high'], (v) => setS(() => p = v!)),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: d ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (picked != null) setS(() => d = picked);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_formatDate(d)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anulează")),
            ElevatedButton(
              onPressed: () async {
                await _taskService.updateTask(widget.token, task.id!, titleC.text, descC.text, p, c, d);
                Navigator.pop(ctx);
                _refreshTasks();
              },
              child: const Text("Salvează"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
      onChanged: onChanged,
    );
  }

  void _confirmDelete(int taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ștergi acest task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Nu")),
          TextButton(onPressed: () async {
            await _taskService.deleteTask(widget.token, taskId);
            Navigator.pop(ctx);
            _refreshTasks();
          }, child: const Text("Da, șterge", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ThemeItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(label)]);
  }
}