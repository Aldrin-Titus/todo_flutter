import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> tasks = [];

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setDialogState(() {
                      selectedDueDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  selectedDueDate == null
                      ? "Pick Due Date"
                      : "Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isNotEmpty) {
                  setState(() {
                    tasks.add({
                      'title': title,
                      'body': body,
                      'dueDate': selectedDueDate ?? DateTime.now(),
                      'status': 'open',
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _editTask(int index) {
    final titleController = TextEditingController(text: tasks[index]['title']);
    final bodyController = TextEditingController(text: tasks[index]['body']);
    DateTime? selectedDueDate = tasks[index]['dueDate'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDueDate = picked;
                    });
                  }
                },
                child: Text(
                  selectedDueDate == null
                      ? "Pick Due Date"
                      : "Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tasks[index]['title'] = titleController.text.trim();
                  tasks[index]['body'] = bodyController.text.trim();
                  tasks[index]['dueDate'] = selectedDueDate ?? tasks[index]['dueDate'];
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleComplete(int index) {
    setState(() {
      tasks[index]['status'] =
          tasks[index]['status'] == 'complete' ? 'open' : 'complete';
    });
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<Map<String, dynamic>>.from(tasks)
      ..sort((a, b) => a['dueDate'].compareTo(b['dueDate']));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.displayName ?? 'User'} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: sortedTasks.isEmpty
          ? const Center(
              child: Text('No tasks yet.\nTap + to add one!',
                  textAlign: TextAlign.center),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: sortedTasks.length,
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                final due = task['dueDate'] as DateTime;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: task['status'] == 'complete',
                      onChanged: (_) => _toggleComplete(tasks.indexOf(task)),
                    ),
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task['status'] == 'complete'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task['body'].toString().isNotEmpty)
                          Text(
                            task['body'],
                            style: TextStyle(
                              color: task['status'] == 'complete'
                                  ? Colors.grey
                                  : Colors.black87,
                              fontStyle: task['status'] == 'complete'
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          "Due: ${due.day}/${due.month}/${due.year}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editTask(tasks.indexOf(task)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTask(tasks.indexOf(task)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
